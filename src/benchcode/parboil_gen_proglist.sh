#!/bin/bash

if [ $# -lt 1 ]; then
    echo "usage: "
    echo "  ./parboil_gen_proglist.sh <options> prog_num"
    echo "Options: "
    echo "      -c, --codetype [cuda_base, cuda]"
    echo "      -d, --dataset [small, medium, large]"
    echo ""
    exit 0
fi

while [ $# -gt 0 ]; do
  key="$1"
  case $key in
    -b|--blockvars)
			blockvars="true"
			;;
    -d|--dataset)
      dataset="$2"
      shift 
      ;;
    -c|--codetype)
      ver="$2"
      shift 
      ;;
    *)
      # unknown option
      if [ "$prog" = "" ]; then
        prog=$1
      else
        echo "Unknown option:" $key
        exit 0
      fi
      ;;
  esac
  shift 
done

if [ $DEBUG ]; then 
   echo $prog
	 echo $kernel
   echo $ver
   echo $dataset
	 echo $metric
   echo $maxreg
   echo $blocksize
fi


PARBOIL_HOME=$HOME/Experiments/Parboil
[ -x ${PARBOIL_HOME} ] || { "unable to cd to Parboil home directory; exiting ..." ; exit 1; }  

input_dir=${PARBOIL_HOME}/datasets
source ${PARBOIL_HOME}/parboil_vardefs.sh ${input_dir}

[ "${maxreg}" ] || { maxreg=default; }
[ "${dataset}" ] || { dataset=small; }
[ "${ver}" ] || { ver="cuda_base"; }


variants="default 16 20 24 32 40 48 64 512" 


function reg_cap_new() {
	for prog in {0..21}; do
		if [ $ver = "cuda_base" ]; then
			kernel=${kernels_base[$prog]}  
		fi
		if [ $ver = "cuda" ]; then
			kernel=${kernels[$prog]}  
		fi
		# get number of allocated registers with --maxrregcount 512 for _this_ program
		launch=`parboil_gen_variant.sh -c $ver -r 512 -l $prog`

		reg_512=`echo $launch | awk '{print $1}'`
		bkls_def=`echo $launch | awk '{print $2}'`
		thrds_def=`echo $launch | awk '{print $3}'`

		reg_last=0
		
		i=0
		for v in $variants; do
			
			# get number of registers for _this_ variant  
			launch=`parboil_gen_variant.sh -c $ver -r $v -l $prog`
			reg_def=`echo $launch | awk '{print $1}'`                  # only reg, launch is same as -r 512

			# check if we have seen this variant before 
			found=0 
			for ((j=0; j < $i; j++)); do 
				if [ ${reg_def} = ${regs[$j]} ]; then 
					found=1
					break
				fi
			done
			
			# only consider if this is a new variant
			if [ ${found} -ne 1 ]; then  
				regs[$i]=${reg_def}

        # get number of registers for default threads/block and min blocks/grid 
  			launch=`parboil_gen_variant.sh -m ${thrds_def} -n 1 -c $ver -l $prog`
				reg_max=`echo $launch | awk '{print $1}'`
				
   	  	# only consider this instance, if a variation in reg allocation is observed 
				if [ ${reg_max} -gt ${reg_def} ] || [ ${reg_512} -gt ${reg_def} ]; then 
					build="parboil_gen_variant.sh -c $ver -r $v $prog"
					exec=`${PARBOIL_HOME}/parboil_cmd_gen.sh -c $ver $prog`
					echo "+ ;;" $build " ;; " $kernel $exec
					
   		    # consider the larger of the two for "opt" variant  
					if [ ${reg_max} -gt ${reg_512} ]; then 
						build="parboil_gen_variant.sh -m ${thrds_def} -n 1 -c $ver $prog"
					else 
						build="parboil_gen_variant.sh -r 512 -c $ver $prog"
					fi
					exec=`${PARBOIL_HOME}/parboil_cmd_gen.sh -c $ver $prog`
					echo "aggr ;;" $build " ;; " $kernel $exec
				fi
				i=$(($i+1))
			fi

#			echo ${reg_def} ${reg_512}
		done
	done
}

function reg_cap_variants() {
	for prog in {11..21}; do
		if [ $ver = "cuda_base" ]; then
			kernel=${kernels_base[$prog]}  
		fi
		if [ $ver = "cuda" ]; then
			kernel=${kernels[$prog]}  
		fi
		i=0
		for model in $models; do
			build="parboil_gen_variant.sh -c $ver -r $model $prog"
			exec=`${PARBOIL_HOME}/parboil_cmd_gen.sh -c $ver $prog`
			echo "+ ;;" $build " ;; " $kernel $exec
			if [ $DEFVAL ]; then 
				echo ${def_bs[$prog]} ${model} > def_vals.txt
			fi
			j=0
			for m in $models; do 
				build="parboil_gen_variant.sh -r $m -c $ver $prog"
				exec=`${PARBOIL_HOME}/parboil_cmd_gen.sh -c $ver $prog`
				echo $m ";;" $build " ;; " $kernel $exec
				j=$(($j+1))
			done                
			i=$(($i+1))
		done
	done
}

function blocksize_variants() {
	for prog in {0..10}; do
		if [ $ver = "cuda_base" ]; then
			kernel=${kernels_base[$prog]}  
		fi
		if [ $ver = "cuda" ]; then
			kernel=${kernels[$prog]}  
		fi
	if [ $prog -ne 1 ] && [ $prog -ne 3 ] && [ $prog -ne 6 ]; then 
		if [ $prog -eq 0 ] || [ $prog -eq 2 ]; then  
			blocks="32 64 96 128 160 192 224 256 288 320 352 384 416 448 480 512 544 576 608 640 672 \
              704 736 768 800 832 864 896 928 960 992 1024"
		elif [ $prog -eq 4 ] || [ $prog -eq 5 ]; then  
			blocks="32 64 128 256 512 1024"
		elif [ $prog -eq 7 ]; then  
			if [ $dataset = "large" ]; then 
				blocks="4 16 64 128 256 512 1024"
			else
				blocks="4 16 64"
			fi
		elif [ $prog -eq 8 ]; then 
			blocks="32 64 96 160 192 288 320 480 544 576 864 96"
		elif [ $prog -eq 9 ]; then  
			if [ $dataset = "large" ]; then 
				grid=`echo ${base_launch} | awk '{print $1/62}'`
			else
				blocks="1 2 7 14 17 31 34 62 73 119 146 217 238 434 511 527 1022"
			fi
		elif [ $prog -eq 10 ]; then 
			blocks="32 64 128 256 512 1024"
		else 
			blocks="32 64 128 160 256 320 512 640 1024"
		fi

		i=0
		for block in $blocks; do
			build="parboil_gen_variant.sh -b $block -r default $prog"
			exec=`${PARBOIL_HOME}/parboil_cmd_gen.sh $prog`
			echo "+ ;;" $build " ;; " $kernel $exec
			if [ $DEFVAL ]; then 
				echo ${block} ${def_regs[$prog]} > def_vals.txt
			fi
			j=0
			for m in $models; do 
				build="parboil_gen_variant.sh -b $block -r $m $prog"
				exec=`${PARBOIL_HOME}/parboil_cmd_gen.sh $prog`
				echo $m ";;" $build " ;; " $kernel $exec
				j=$(($j+1))
			done                
			i=$(($i+1))
		done
	fi
	done
}

if [ $blockvars ]; then 
	blocksize_variants
else 
	reg_cap_new
fi

