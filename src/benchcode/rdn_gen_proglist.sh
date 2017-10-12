#!/bin/bash

if [ $# -lt 1 ]; then
    echo "usage: "
    echo "  ./rdn_cmd_gen.sh <options> prog_num"
		echo "generate execution command for proglist file" 
    echo "options: "
    echo "      -c, --codetype [cuda_base, cuda]"
    echo "      -d, --dataset [small, medium, large]"
    echo ""
    exit 0
fi

while [ $# -gt 0 ]; do
  key="$1"
  case $key in
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


RODINIA_HOME=$HOME/Experiments/Rodinia
input_dir=${RODINIA_HOME}/datasets

[ -x ${RODINIA_HOME} ] || { "unable to cd to Parboil home directory; exiting ..." ; exit 1; }  

if [ "${dataset}" = "" ]; then 
	dataset=small
fi
if [ "${ver}" = "" ]; then 
	ver="cuda_base"
fi

if [ $DEBUG ]; then 
   echo $prog
   echo $ver
   echo $dataset
fi

pushd ${RODINIA_HOME} &> /dev/null
source ${HOME}/code/MLTUNE/src/benchcode/rdn_vardefs.sh ${input_dir}

progname=${progs[$prog]}
kernel=${kernels_base[$prog]}
if [ "$dataset" = "small" ]; then 
  args=${args_small[$prog]} 
fi
if [ "$dataset" = "medium" ];then
  args=${args_medium[$prog]}
fi
if [ "$dataset" = "large" ]; then 
  args=${args_large[$prog]}
fi
execdir=${RODINIA_HOME}/benchmarks/${progname}/src/${ver}
echo "${kernel} ${execdir}/${progname} $args"

popd &> /dev/null
