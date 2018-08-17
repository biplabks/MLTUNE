#!/bin/bash


if [ $# -lt 1 ] || [ $1 == "--help" ]; then
    echo "Usage: "
    echo "       lone_star_gen_variant.sh <options> prog_num"
		echo "Script to build lonestar executables with specified regs, blocksizes etc."
		echo ""
    echo "Options: "
    echo "      -v, --verify; check output agains reference"
    echo "      -p, --profile <metric>; profile the code"
		echo "      -i, --input <index>; input graph index; input graphs are numbered from 0-32 (see lonestar_vardefs.sh)"
		echo "      -l, --launch, get launch configuration"
		echo "      -s, --showregs, show register allocation"
    echo "      -c, --codetype [cuda_base, cuda]"
    echo "      -r, --regs REGS; REGS legal values, {16..512}" 
    echo "      -d, --dataset [small, medium, large]"
    echo "      -b, --blocksize BLOCKSIZE; BLOCKSIZE legal values {32..1024}" 
		echo "      -g, --debug"
    exit 0
fi

while [ $# -gt 0 ]; do
  key="$1"
  case $key in
    -r|--regs)
      maxreg="$2"
      shift 
      ;;
		-i|--input)
			input_index="$2"
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
      profile=$2
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
    -g|--debug)
      debug=true
      ;;
    -d|--dataset)
      dataset="$2"
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
    --managed)
      placement="managed"
      ;;
    --embed)
      embed=true
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
LONESTAR_HOME=${HOME}/Experiments/Lonestar
input_dir=${LONESTAR_HOME}/datasets
ref_output_dir=${input_dir}

MAKEFILE_DIR=${LONESTAR_HOME}/benchmarks
MAKEFILE="Makefile.conf"

[ -x ${LONESTAR_HOME} ] || { "unable to cd to Lonestar home directory; exiting ..." ; exit 1; }  


[ "${opts}" ] || { opts="default"; }
[ "${placement}" ] || { placement="copy"; }
[ "${ptx_opts}" ] || { ptx_opts="default"; }
[ "${input_index}" ] || { input_index=0; }

if [ "${maxreg}" = "" ]; then 
	maxreg=default
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

#DEBUG=1
if [ $DEBUG ]; then 
   echo $prog
   echo $ver
   echo $maxreg
   echo ${max_thrds}
   echo ${min_blks}
   echo $blocksize
	 exit 
fi

cd ${LONESTAR_HOME}
source ${HOME}/code/MLTUNE/src/benchcode/lonestar_vardefs.sh ${input_dir}

function build {
  i=$1
  prog=${progs[$i]}
  algm=${progs_main[$i]}

	if [ "$algm" = "bfs" ]; then 
		algm_index=0
	else
		algm_index=1		
	fi
  ver=$2

	if [ $ver = "cuda" ]; then 
		kernel=${kernels[$i]}
	else 
		kernel=${kernels_base[$i]}
	fi

  srcdir="${LONESTAR_HOME}/benchmarks/${algm}/src/$ver"

  pushd ${MAKEFILE_DIR}  > /dev/null
  cp ${MAKEFILE} ${MAKEFILE}.orig
  
	sed -i "s/RALEVEL=/RALEVEL=${ra_level}/" ${MAKEFILE}
  if [ ${opts} != "default" ]; then
    sed -i "s/CC_OPTLEVEL=-O3/CC_OPTLEVEL=-O${opts}/" ${MAKEFILE}
  fi
  if [ ${ptx_opts} != "default" ]; then
    sed -i "s/PTX_OPTLEVEL=-O3/PTX_OPTLEVEL=-O${ptx_opts}/" ${MAKEFILE}
  fi
  if [ ${maxreg} != "default" ]; then
    sed -i "s/REGCAP=/REGCAP=--maxrregcount=${maxreg}/" ${MAKEFILE}
  fi
  if [ ${blocksize} != "default" ]; then
    sed -i "s/BLOCKPARAM=/BLOCKPARAM=-DML/" ${MAKEFILE}
	fi  

	if [ "${embed}" ]; then 
		sed -i "s/TILED=/TILED=-DTILED/" ${MAKEFILE}
	fi
	if [ ${placement} = "managed" ]; then
		sed -i "s/MANAGED=/MANAGED=-DMANAGED/" ${MAKEFILE}
	fi
  if [ ${max_thrds} != "default" ] || [ ${min_blks} != "default" ]; then 
		sed -i "s/LAUNCH=/LAUNCH=-DLAUNCH/" ${MAKEFILE}
		sed -i "s/ML_MAX_THRDS_PER_BLK=/ML_MAX_THRDS_PER_BLK=-DML_MAX_THRDS_PER_BLK=${max_thrds}/" ${MAKEFILE}
		sed -i "s/ML_MIN_BLKS_PER_MP=/ML_MIN_BLKS_PER_MP=-DML_MIN_BLKS_PER_MP=${min_blks}/" ${MAKEFILE}
		cp ${MAKEFILE} ~/makefile.tmp
	fi

  if [ -d  $srcdir ]; then 
      pushd $srcdir > /dev/null
      make clean &> /dev/null

      if [ ${blocksize} != "default" ]; then
				case ${prog} in 
					"bfs") 
						srcfile=bfs_ls.h
						;;
					"bfs-atomic") 
						srcfile=bfs_topo_atomic.h
						;;
					"bfs-wlc")
						srcfile=bfs_worklistc.h
						;;
					"bfs-wla")
						srcfile=bfs_worklista.h
						;;
					"bfs-wlw")
						srcfile=bfs_worklistw.h
						;;
					"eps")
						srcfile=comm.h
						;;
					*)
						srcfile=main.cu
						;;
				esac
				#commented out because we want to copy the src to src.orig only once, upon install
				#otherwise the .orig will become corrupted if this .sh file terminates before restore
				#and impact all future runs. Can be easily fixed, but users may not notice.
				cp ${srcfile} ${srcfile}.orig
				sed -i "s/__BLOCKSIZE0/${blocksize}/g" ${srcfile}
      fi  

      (make ${prog} 2>&1) > tmp

      spills=`cat tmp | grep "spill" | awk '{print $5 + $9}'`
			if [ ${kernel} = "eps" ]; then 
				regs=`cat tmp | grep "registers" | awk '{ print $5 }'`
			else
				regs=`cat tmp | grep ${kernel} -A 2 | grep "registers" | awk '{ print $5 }'`
			fi
      if [ "${debug}" ]; then 
				cp tmp regs.dbg
      fi
      

      if [ $ver = "cuda_base" ]; then 
          if [ $prog = "histo" ]; then
              regs=`echo $regs | awk '{print $3}'`
          fi
          if [ $prog = "mri-gridding" ]; then
              regs=`echo $regs | awk '{print $2}'`
          fi
          if [ $prog = "sad" ]; then
              regs=`echo $regs | awk '{print $1}'`
          fi
          if [ $prog = "track" ]; then
              regs=`echo $regs | awk '{print $1}'`
          fi
      fi
      
      if [ $ver = "cuda" ]; then 
          if [ $prog = "mri-q" ] || [ $prog = "mri-gridding" ]; then
              regs=`echo $regs | awk '{print $2}'`
          else
              regs=`echo $regs | awk '{print $1}'`
          fi
      fi
      
      if [ "${showspills}" ]; then
				echo $spills
      fi
      
      # deprecated (bundled with launch configuration)
      if [ "${showregs}" ]; then 
				echo $regs
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

			if [ $kernel = "eps" ]; then 
				beg_file=`echo ${args_eps[${input_index}]} | awk '{print $1}'`
				csr_file=`echo ${args_eps[${input_index}]} | awk '{print $2}'`
 				infile="${input_dir}/${beg_file} ${input_dir}/${csr_file}"
			elif [ $kernel = "drelax" ]; then 
 			 	infile="${input_dir}/${args_bfs[${input_index}]}"
			fi

			if [ "${check}" ]; then 
					if [ $kernel = "eps" ] || [ $kernel = "drelax" ]; then 
							./${prog} $infile  > $prog.out
					else
						./${prog} ${args}  > $prog.out
					fi
					errors=`cat ${prog}.out | grep errors | awk '{print $5}' | awk -F "." '{print $1}'`
					if [ "${errors}" -gt 0 ]; then
							echo "FAIL : incorrect results" 
					fi
			fi
		 
		 if [ "${profile}" ]; then
			 if [ $verbos ]; then
			   echo "profiling $prog ..." 
			 fi
			 if [ $kernel = "eps" ] || [ $kernel = "drelax" ]; then 
				 get_primary_lsg.sh -m ${profile} -k ${kernel} -- ./${prog} $infile
			 else
				 get_primary_lsg.sh -m ${profile} -k ${kernel} -- ./${prog} $args
			 fi
		 fi
     if [ "${res}" = "FAIL" ]; then 
			 echo $res ": executable not valid" 
     fi
		 
		 if [ "${launch}" ]; then
       [ `which nvprof` ] || { echo "could not find nvprof in path. Existing..."; exit 1; }
				 if [ $kernel = "eps" ] || [ $kernel = "drelax" ]; then 
						 (nvprof --events threads_launched,sm_cta_launched ./${prog} $infile  > $prog.out) 2> tmp
				 else
						 (nvprof --events threads_launched,sm_cta_launched ./${prog} $infile  > $prog.out) 2> tmp
				 fi
				 if [ ${kernel} = "eps" ]; then 
						 geom=`cat tmp | grep "THD_expand" -A 2 | grep "launched" | awk '{print $NF}'`
				 else 
					 geom=`cat tmp | grep "${kernel}" -A 2 | grep "launched" | awk '{print $NF}'`
				 fi

				 thrds_per_block=`echo $geom | awk '{ print $1/$2 }'`
				 blocks_per_grid=`echo $geom | awk '{ print $2 }'`
				 echo $blocks_per_grid $thrds_per_block
				 
				 if [ "${debug}" ]; then
						 cp tmp launch.dbg
				 fi
     fi
		 
      # clean up and restore
      if [ ${blocksize} != "default" ]; then
				cp ${srcfile} ${srcfile}.gen
				cp ${srcfile}.orig ${srcfile}
      fi
      echo " " > results.dat #can cause check script errors if file is not reset to blank
      rm -rf tmp $prog.out
      popd > /dev/null
  else
      echo "FAIL: $ver not found for prog $prog" 
  fi

  # back in makefile dir
  cp ${MAKEFILE}.orig ${MAKEFILE}
	cp ${MAKEFILE} ${MAKEFILE}.tmp
  popd > /dev/null
}

build $prog $ver


