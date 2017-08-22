#!/bin/bash

if [ $# -lt 1 ]; then
    echo "usage: "
    echo "  ./parboil_cmd_gen.sh <options> prog_num"
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


PARBOIL_HOME=$HOME/Experiments/Parboil
input_dir=${PARBOIL_HOME}/datasets

[ -x ${PARBOIL_HOME} ] || { "unable to cd to Parboil home directory; exiting ..." ; exit 1; }  

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

pushd ${PARBOIL_HOME} &> /dev/null
source parboil_vardefs.sh ${input_dir}

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
execdir=${PARBOIL_HOME}/benchmarks/${progname}/src/${ver}
echo "${kernel} ${execdir}/${progname} -i $args"

popd &> /dev/null
