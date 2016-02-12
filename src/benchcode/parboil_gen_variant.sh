#!/bin/bash

if [ $# -lt 1 ]; then
    echo "usage: "
    echo "  ./parboil_gen_variant.sh <options> prog_num"
		echo "builds a parboil executable with specified regs, blocksizes etc."
		echo ""
    echo "Options: "
    echo "      -v, --verify; check output agains reference"
		echo "      -l, --launch, get launch configuration"
		echo "      -s, --showregs, show register allocation"
    echo "      -c, --codetype [cuda_base, cuda]"
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

PARBOIL_HOME=$HOME/Experiments/Parboil
input_dir=${PARBOIL_HOME}/datasets
ref_output_dir=${input_dir}

MAKEFILE_DIR=${PARBOIL_HOME}/benchmarks
MAKEFILE="Makefile.conf"

[ -x ${PARBOIL_HOME} ] || { "unable to cd to Parboil home directory; exiting ..." ; exit 1; }  


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

if [ $DEBUG ]; then 
   echo $prog
   echo $ver
   echo $maxreg
   echo $blocksize
fi

cd ${PARBOIL_HOME}
source parboil_vardefs.sh ${input_dir}

function build {
  i=$1
  prog=${progs[$i]}
  ver=$2

  srcdir="${PARBOIL_HOME}/benchmarks/$prog/src/$ver"

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
				cp ${srcfile} ${srcfile}.orig
				sed -i "s/__BLOCKSIZE0/${blocksize}/" ${srcfile}
      fi  

      regs=`make 2>&1 | grep "registers" | awk '{ print $5 }'`

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

			if [ "${showregs}" ]; then 
				echo $regs
			fi

      # notify if buld failed 
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
				check_script="../../tools/compare-output"
				
				if [ ! -x ${check_script} ]; then 
					echo "FAIL: could not find check script, not validating results"
				else
					./${prog} -i $args  > $prog.out
					res=`${check_script} ${ref_output_dir}/${prog}/ref_${dataset}.dat result.dat 2> /dev/null`
					res=`echo $res | grep "Pass"`
					if [ ! "${res}" ]; then 
						res="FAIL"
					fi
				fi
      fi
			
      if [ "${res}" = "FAIL" ]; then 
				echo $res ": executable not valid" 
      fi
			
      if [ "${launch}" ]; then 
        kernel=${kernels_base[$i]}
			  (nvprof --events threads_launched,sm_cta_launched ./${prog} -i $args  > $prog.out) 2> tmp
				geom=`cat tmp | grep "${kernel}" -A 2 | grep "launched" | awk '{print $NF}'`
				thrds_per_block=`echo $geom | awk '{ printf "%5.0f", $1/$2 }'`
				blocks_per_grid=`echo $geom | awk '{ print $2 }'`
				echo ${blocks_per_grid} ${thrds_per_block}
      fi

      # clean up and restore
      if [ ${blocksize} != "default" ]; then
				cp ${srcfile} ${srcfile}.gen
				cp ${srcfile}.orig ${srcfile}
      fi
      rm -rf tmp $prog.out
      popd > /dev/null
  else
      echo "FAIL: $ver not found for prog $prog" 
  fi

  # back in makefile dir
  cp ${MAKEFILE}.orig ${MAKEFILE}
  popd > /dev/null
}

build $prog $ver
