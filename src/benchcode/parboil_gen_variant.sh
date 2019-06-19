#!/bin/bash


function usage() {
/bin/cat 2>&1 <<"EOF"
     
		Builds, execute and profile parboil benchmarks with custom configuration (optimization level, launch bounds etc)

    Usage: parboil_gen_variant.sh [options] prog_num"
    
    Options:
       --help              print this help message
       -v, --verbose       verbose mode  
       -g, --debug         debug mode
       -v, --verify        check output against reference
       -t, --time          report execution time
       -l, --launch        show kernel launch configuration
       -s, --showregs      show number of registers allocated 
       --show_spills       show number of register spills 

    Optionss with values:
       -c, --codetype <VERSION>      specify version of code; <VERSION> = cuda_base, cuda
       -r, --regs <REGS>             maximum numbers of registers to allocate for each kernel; <REGS> = {16..512} 
       -d, --dataset <SIZE>          data set size; <DATA> = small, medium, large
       -b, --blocksize <BLOCKSIZE>   specify thread block size; <BLOCKSIZE> = {32..1024}
       --opts <LEVEL>                specify compiler optimization level; <LEVEL> is 0,1,2 or 3
       --ptx_opts <LEVEL>            specify PTX optimization level; <LEVEL> is 0,1,2 or 3
       -a, --ra  <LEVEL>             specify register allocation aggresiveness level; <LEVEL> is -1, 0, 1,2
 
    Examples:
       parboil_gen_variant.sh -s -b 256  0    // build benchmark 0 with a blocksize 256; show registers

EOF
	exit 1
}

if [ $# -lt 1 ] || [ "$1" == "--help" ]; then
	usage
  exit 0
fi

while [ $# -gt 0 ]; do
  key="$1"
  case $key in
    -r|--regs)
      maxreg="$2"
      shift 
      ;;
    -a|--ra)
      ra_level="$2"
      shift 
      ;;
    -v|--verify)
      check=true
      ;;
    -p|--profile)
      perf="$2"
			shift
      ;;
    -g|--debug)
      debug=true
      ;;
    -d|--dataset)
      dataset="$2"
      shift 
      ;;
		--opts)
			opts="$2"
			shift
			;;
		--ptx_opts)
			ptx_opts="$2"
			shift
			;;
    -b|--blocksize)
      blocksize="$2"
      shift 
      ;;
    -m|--max_thrds)
      max_thrds="$2"
      shift 
      ;;
    -n|--min_thrds)
      min_blks="$2"
      shift 
      ;;
    -c|--codetype)
      ver="$2"
      shift 
      ;;
    -l|--launch)
      launch=true
      ;;
    -s|--showregs)
      showregs=true
      ;;
    --showspills)
      showspills=true
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

[ "$prog" ] || { echo "no program specified. exiting ..."; exit 0; }


# enviornment specific variables; needs to be set at install time 
PARBOIL_HOME=$HOME/Experiments/Parboil
input_dir=${PARBOIL_HOME}/datasets
ref_output_dir=${input_dir}

MAKEFILE_DIR=${PARBOIL_HOME}/benchmarks
MAKEFILE="Makefile.conf"

[ -x ${PARBOIL_HOME} ] || { "unable to cd to Parboil home directory; exiting ..." ; exit 1; }  


[ "${opts}" ] || { opts="default"; }
[ "${ptx_opts}" ] || { ptx_opts="default"; }

if [ "${maxreg}" = "" ]; then 
	maxreg=default
fi
if [ "${ra_level}" = "" ]; then 
	ra_level=default
fi
if [ "${blocksize}" = "" ]; then 
	blocksize=default
fi
if [ "${dataset}" = "" ]; then 
	dataset=small
fi
if [ "${ver}" = "" ]; then 
	ver="cuda_base"
fi

if [ ! "${max_thrds}" ]; then 
	if [ ! "${min_blks}" ]; then 
		max_thrds=default
		min_blks=default
	else 
		max_thrds=1024
	fi
else 
	if [ ! "${min_blks}" ]; then 
		min_blks=1
	fi
fi 

if [ $DEBUG ]; then 
   echo $prog
   echo $ver
   echo $maxreg
   echo ${max_thrds}
   echo ${min_blks}
   echo $blocksize
	 exit 
fi

cd ${PARBOIL_HOME}
source ${HOME}/code/MLTUNE/src/benchcode/parboil_vardefs.sh ${input_dir}

function build {
  i=$1
  prog=${progs[$i]}
  ver=$2

  srcdir="${PARBOIL_HOME}/benchmarks/$prog/src/$ver"

  pushd ${MAKEFILE_DIR}  > /dev/null
  cp ${MAKEFILE} ${MAKEFILE}.orig
  
  if [ ${opts} != "default" ]; then
    sed -i "s/CC_OPTLEVEL=-O2/CC_OPTLEVEL=-O${opts}/" ${MAKEFILE}
  fi
  if [ ${ptx_opts} != "default" ]; then
    sed -i "s/PTX_OPTLEVEL=-O2/PTX_OPTLEVEL=-O${ptx_opts}/" ${MAKEFILE}
  fi
  if [ ${ra_level} != "default" ]; then
 			sed -i "s/RALEVEL=/RALEVEL=-mllvm -reg_control=${ra_level}/" ${MAKEFILE}
			cp ${MAKEFILE} ${MAKEFILE}.gen

	fi
	if [ ${maxreg} != "default" ]; then
    sed -i "s/REGCAP=/REGCAP=-Xcuda-ptxas --maxrregcount=${maxreg}/" ${MAKEFILE} ### LLVM
#    sed -i "s/REGCAP=/REGCAP=--ptxas-options --maxrregcount=${maxreg}/" ${MAKEFILE}
  fi
  if [ ${blocksize} != "default" ]; then
    sed -i "s/BLOCKPARAM=/BLOCKPARAM=-DML/" ${MAKEFILE}
	fi  

	
  if [ ${max_thrds} != "default" ] || [ ${min_blks} != "default" ]; then 
		sed -i "s/LAUNCH=/LAUNCH=-DLAUNCH/" ${MAKEFILE}
		sed -i "s/ML_MAX_THRDS_PER_BLK=/ML_MAX_THRDS_PER_BLK=-DML_MAX_THRDS_PER_BLK=${max_thrds}/" ${MAKEFILE}
		sed -i "s/ML_MIN_BLKS_PER_MP=/ML_MIN_BLKS_PER_MP=-DML_MIN_BLKS_PER_MP=${min_blks}/" ${MAKEFILE}
	fi

  if [ -d  $srcdir ]; then 
      pushd $srcdir > /dev/null
      make clean &> /dev/null

      if [ ${blocksize} != "default" ]; then
				case ${prog} in 
					"cutcp") 
						srcfile=cutoff.cu
						;;
					"lbm") 
						srcfile=${prog}.cu
						;;
					"mri-gridding")
						srcfile=CUDA_interface.cu
						;;
					"mri-q")
						srcfile=computeQ.cu
						;;
					"sgemm"|"tpacf")
						srcfile=${prog}_kernel.cu
						;;
					"spmv")
						srcfile=gpu_info.cc
						;;
					*)
						srcfile=main.cu
						;;
				esac
				#commented out because we want to copy the src to src.orig only once, upon install
				#otherwise the .orig will become corrupted if this .sh file terminates before restore
				#and impact all future runs. Can be easily fixed, but users may not notice.
				#cp ${srcfile} ${srcfile}.orig
				sed -i "s/__BLOCKSIZE0/${blocksize}/" ${srcfile}
      fi  
      (make 2>&1)  > tmp 

      spills=`cat tmp | grep "spill" | awk '{print $5 + $9}'`
      regs=`cat tmp | grep "registers" | awk '{ print $5 }'`

      if [ "${debug}" ]; then 
				cp tmp regs.dbg
				cp ${MAKEFILE} ${MAKEFILE}.gen
      fi
      

      if [ $ver = "cuda_base" ]; then 
          if [ $prog = "histo" ]; then
              regs=`echo $regs | awk '{print $3}'`

              spills=`echo $spills | awk '{print $3}'`
          fi
          if [ $prog = "mri-gridding" ]; then
              regs=`echo $regs | awk '{print $2}'`
              spills=`echo $spills | awk '{print $2}'`
          fi
          if [ $prog = "sad" ] || [ $prog = "mri-q" ] || [ $prog = "track" ]; then
              regs=`echo $regs | awk '{print $1}'`
              spills=`echo $spills | awk '{print $1}'`
          fi
          # if [ $prog = "track" ]; then
          #     regs=`echo $regs | awk '{print $1}'`
          #     spills=`echo $spills | awk '{print $1}'`
          # fi
					
      fi
      
      if [ $ver = "cuda" ]; then 
          if [ $prog = "mri-q" ] || [ $prog = "mri-gridding" ]; then
              regs=`echo $regs | awk '{print $2}'`
              spills=`echo $spills | awk '{print $2}'`
          else
						if [ $prog = "histo" ]; then
								regs=`echo $regs | awk '{print $1}'`
						else
              regs=`echo $regs | awk '{print $1}'`
              spills=`echo $spills | awk '{print $1}'`
						fi
					fi
      fi
      
      if [ "${showspills}" ]; then
				echo $spills
      fi
      

      # notify if build failed 
      if [ ! -x ${prog} ]; then 
				echo "FAIL: could not generate variant; make failed for $prog"
	  
				if [ ${blocksize} != "default" ]; then
					cp ${srcfile}.orig ${srcfile}
				fi
				popd > /dev/null
        # back in makefile dir
				cp ${MAKEFILE}.orig ${MAKEFILE}
				
				popd > /dev/null
				exit 1
      else
				if [ "${showregs}" ]; then 
						echo $regs
				fi
      fi
			
      if [ "$dataset" = "small" ]; then 
          args=${args_small[$i]} 
      fi
      if [ "$dataset" = "medium" ];then
          args=${args_medium[$i]}
      fi
      if [ "$dataset" = "large" ]; then 
          args=${args_large[$i]}
      fi

	# bundled with launch
#     if [ "${check}" ]; then 
#				check_script="../../tools/compare-output"
   				
#				if [ ! -x ${check_script} ]; then 
#					echo "FAIL: could not find check script, not validating results"
#				else
#					./${prog} -i $args  > $prog.out
#					res=`${check_script} ${ref_output_dir}/${prog}/ref_${dataset}.dat result.dat 2> /dev/null`
#					res=`echo $res | grep "Pass"`
#					if [ ! "${res}" ]; then 
#						res="FAIL"
#					fi
#				fi
#      fi
			
			if [ $ver = "cuda" ]; then 
					kernel=${kernels[$i]}
			else 
				kernel=${kernels_base[$i]}
			fi
			
			if [ "${perf}" ]; then
					get_primary_gpu.sh -m ${perf} -k ${kernel} -- ./${prog} -i $args 
			fi
      # if [ "${res}" = "FAIL" ]; then 
			# 	echo $res ": executable not valid" 
      # fi

			if [ "${launch}" ]; then
					if [ $blocksize == "default" ]; then
							echo ${def_bs[$i]}
					else
						echo $blocksize
					fi
			fi
			
			if [ "${check}" ]; then
        # [ `which nvprof` ] || { echo "could not find nvprof in path. Existing..."; exit 1; }
        # (nvprof --events threads_launched,sm_cta_launched ./${prog} -i $args  > $prog.out) 2> tmp
        # if [ "${debug}" ]; then
        #   cp tmp launch.dbg
        # fi

        check_script="../../tools/compare-output"
				if [ ! -x ${check_script} ]; then
          echo "FAIL: could not find check script, not validating results"
        else
          export PYTHONPATH="${PYTHONPATH}:${PARBOIL_HOME}/common/python"
					./${prog} -i $args  &> $prog.out
          res=`${check_script} ${ref_output_dir}/${prog}/ref_${dataset}.dat result.dat 2> /dev/null`
          res=`echo $res | grep "Pass"`

          if [ ! "${res}" ]; then
            res="FAIL"
          else
						res="PASS"
					fi

					echo $res

					# if [ "${launch}" ]; then
          #   geom=`cat tmp | grep "${kernel}" -A 2 | grep "launched" | awk '{print $NF}'`
          #   thrds_per_block=`echo $geom | awk '{ printf "%5.0f", $1/$2 }'`
          #   blocks_per_grid=`echo $geom | awk '{ print $2 }'`
          #   echo $regs ${blocks_per_grid} ${thrds_per_block}
          # fi
        fi
      fi
#	fi


			
      # clean up and restore
      if [ ${blocksize} != "default" ]; then
				cp ${srcfile}.orig ${srcfile}
      fi
      echo " " > results.dat #can cause check script errors if file is not reset to blank
      rm -rf tmp $prog.out
      popd > /dev/null
  else
      echo "FAIL: $ver not found for prog $prog" 
  fi

  # back in makefile dir
	cp ${MAKEFILE} ${MAKEFILE}.gen
  cp ${MAKEFILE}.orig ${MAKEFILE}
  popd > /dev/null
}

build $prog $ver
