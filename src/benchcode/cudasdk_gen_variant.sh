#!/bin/bash

if [ $# -lt 1 ]; then
    echo "usage: "
    echo "  ./cudasdk_gen_variant.sh <options> prog_num"
		echo "builds a cudasdk executable with specified regs, blocksizes etc."
		echo ""
    echo "Options: "
    echo "      -v, --verify; check output agains reference"
		echo "      -s, --showregs, show registe allocation"
		echo "      -l, --launch, get launch configuration"
    echo "      -r, --regs REGS; REGS legal values, {16..512}" 
    echo "      -d, --dataset [small, medium, large]"
    echo "      -b, --blocksize BLOCKSIZE; BLOCKSIZE legal values {32..1024}" 
    exit 0
fi

while [ $# -gt 0 ]; do
  key="$1"
  case $key in
    -r|--regs)
      maxreg="$2"
      shift 
      ;;
    -v|--verify)
      check=true
      ;;
    -d|--dataset)
      dataset="$2"
      shift 
      ;;
    -b|--blocksize)
      blocksize="$2"
      shift 
      ;;
    -l|--launch)
      launch=true
      ;;
    -s|--showregs)
      showregs=true
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


# enviornment specific variables; needs to be set at install time 

CUDASDK_HOME=${HOME}/Experiments/CUDA_SDK
[ -x ${CUDASDK_HOME} ] || { "unable to cd to Cudasdk home directory; exiting ..." ; exit 1; }  

input_dir=${CUDASDK_HOME}/datasets
ref_output_dir=${input_dir}

MAKEFILE_DIR=${CUDASDK_HOME}/benchmarks
MAKEFILE="Makefile.conf"


if [ "${maxreg}" = "" ]; then 
	maxreg=default
fi
if [ "${blocksize}" = "" ]; then 
	blocksize=default
fi
if [ "${dataset}" = "" ]; then 
	dataset=small
fi

if [ $DEBUG ]; then 
   echo $prog
   echo $maxreg
   echo $blocksize
fi

cd ${CUDASDK_HOME}
source cudasdk_vardefs.sh ${input_dir}

function build {
  i=$1
  prog=${progs[$i]}

  srcdir="${CUDASDK_HOME}/benchmarks/$prog/src"

  pushd ${MAKEFILE_DIR}  > /dev/null
  cp ${MAKEFILE} ${MAKEFILE}.orig
  if [ ${maxreg} != "default" ]; then
    sed -i "s/REGCAP=/REGCAP=--maxrregcount=${maxreg}/" ${MAKEFILE}
  fi
  if [ ${blocksize} != "default" ]; then
    sed -i "s/BLOCKPARAM=/BLOCKPARAM=-DML/" ${MAKEFILE}
	fi  

  if [ -d  $srcdir ]; then 
      pushd $srcdir > /dev/null
      make clean &> /dev/null

      if [ ${blocksize} != "default" ]; then
				case ${prog} in 
					"SobolQRNG") 
						srcfile=sobol_gpu.cu
						;;
					*)
						srcfile=${prog}.cu
						;;
				esac
				cp ${srcfile} ${srcfile}.orig
				sed -i "s/__BLOCKSIZE0/${blocksize}/" ${srcfile}
      fi  

      regs=`make 2>&1 | grep "registers" | awk '{ print $5 }'`

			case ${prog} in 
				"matrixMul") 
					regs=`echo $regs | awk '{print $1}'`
					;;
			esac
				
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

      if [ "${check}" ]; then 
					./${prog} -i $args  > $prog.out
					res=`cat ${prog}.out | grep "PASS"`
					if [ ! "${res}" ]; then 
						res="FAIL"
					fi
      fi

			
      if [ "${res}" = "FAIL" ]; then 
				echo $res ": executable not valid" 
      fi
			
			if [ "${launch}" ]; then 
				(nvprof --events threads_launched,sm_cta_launched ./${prog} -i $args  > $prog.out) 2> tmp
				geom=`cat tmp | grep "${kernel}" -A 2 | grep "launched" | awk '{print $NF}'`
				thrds_per_block=`echo $geom | awk '{ print $1/$2 }'`
				blocks_per_grid=`echo $geom | awk '{ print $2 }'`
				echo $blocks_per_grid $thrds_per_block
      fi

      # clean up and restore
      if [ ${blocksize} != "default" ]; then
				cp ${srcfile} ${srcfile}.gen
				cp ${srcfile}.orig ${srcfile}
      fi
      rm -rf tmp $prog.out
      popd > /dev/null
  else
      echo "FAIL: $srcdir not found for prog $prog" 
  fi

  # back in makefile dir
  cp ${MAKEFILE}.orig ${MAKEFILE}
  popd > /dev/null
}

build $prog
