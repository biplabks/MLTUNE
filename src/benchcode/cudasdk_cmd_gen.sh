#!/bin/bash

if [ $# -lt 1 ]; then
    echo "usage: "
    echo "  ./cudasdk_cmd_gen.sh <options> prog_num"
		echo "generate execution command for proglist file" 
    echo "options: "
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

CUDASDK_HOME=$HOME/Experiments/CUDA_SDK
input_dir=${CUDASDK_HOME}/datasets

[ -x ${CUDASDK_HOME} ] || { "unable to cd to CUDASDK home directory; exiting ..." ; exit 1; }  

if [ "${dataset}" = "" ]; then 
	dataset=small
fi

if [ $DEBUG ]; then 
   echo $prog
   echo $dataset
fi

pushd ${CUDASDK_HOME} &> /dev/null
source cudasdk_vardefs.sh ${input_dir}

progname=${progs[$prog]}
if [ "$dataset" = "small" ]; then 
  args=${args_small[$prog]} 
fi
if [ "$dataset" = "medium" ];then
  args=${args_medium[$prog]}
fi
if [ "$dataset" = "large" ]; then 
  args=${args_large[$prog]}
fi

execdir=${CUDASDK_HOME}/benchmarks/${progname}/src/
echo "${execdir}/${progname} -i $args"

popd &> /dev/null
