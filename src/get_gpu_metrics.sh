#!/bin/bash

function usage() {
  echo "usage :"                                                               
  echo "    get_gpu_metrics.sh [OPTIONS] FILE"
  echo "    Collect cuda performance metrics for CUDA kernels described in FILE"
  echo " "
  echo "        FILE is proglist file "
  echo "Options: "
  echo "      -o, --outpath DIR;  DIR is location of output file"
  echo "      -t, --trim;  trim output, emit one row containing just metrics vals "
  echo "      -i, --input FILE;  FILE is file containing list of metrics "
  echo ""
}


if [ $# -eq 1 ] && [ "$1" = "--help" ]; then
  usage 
  exit 0
fi

MINARGS=1
if [ $# -lt $MINARGS ]; then
  usage
  exit 0
fi

while [ $# -gt 0 ]; do
  key="$1"
  case $key in
    -i|--input)
      metrics_file="$2"
      shift # option has parameter
      ;;
    -t|--trim)
      trim="true"
      ;;
    -o|--outpath)
      outpath="$2"
      shift # option has parameter
      ;;
    *)
           # unknown option
      if [ "$proglist" = "" ]; then
        proglist="$1"
      else
        echo Unknown option: $key
        exit 0
      fi
      ;;
  esac
  shift # option(s) fully processed, proceed to next input argument
done

if [ $DEBUG ]; then 
  echo ${metrics_file}
  echo $outpath
  echo ${trim}
  echo $proglist
fi

if [ "$outpath" = "" ]; then
  outpath="."
fi

if [ "$proglist" = "" ]; then
  echo "must specify proglist file"
  exit 0 
fi

[ -r ${proglist} ] || { echo "Could not open proglist file: ${proglist}. Exiting"; exit 0;}

CUDATUNE_HOME=$HOME/cudatuner


[ `which nvprof` ] || { echo "could not find nvprof in path. Exiting..."; exit 1; }
[ `which deviceQuery` ] || { echo "could not find deviceQuery. Exiting..."; exit 1; }

HOST=`hostname`
DEVICE=`deviceQuery | grep "Device 0:" | awk '{print $4}' | sed 's/"//'`
#DEVICE=K20c

# if user didn't supply metrics file then measure all available 

if [ "${metrics_file}" = "" ]; then 
  metrics_file=$CUDATUNE_HOME/info/metrics_${DEVICE}_${HOST}.txt
  [ -r ${metrics_file} ] || { echo "No system metrics file found, generating new one."; gen_metrics_file="true";}
else
  [ -r ${metrics_file} ] || { echo "Could not open metrics file: ${metrics_file}. Exiting"; exit 0;}
fi

# read prog list : <kernel> <prog> <prog args>
i=0
while IFS='' read -r line || [[ -n $line ]]; do
  kernels[$i]=`echo $line | awk '{print $1}'`
  progs[$i]=`echo $line | awk '{print $2}'`
	prognames[$i]=`basename ${progs[$i]}`
  prog_args[$i]=`echo $line | awk '{$1=""; $2=""; print $0}'`
  i=$(($i+1))
done <  ${proglist}

if [ $DEBUG ]; then 
  j=0
  while [ $j -lt $i ]; do
    echo -e ${progs[$j]} "\t" ${prog_args[$j]}
    j=$(($j+1))
  done
fi

outfile=metrics_${prognames[0]}_${DEVICE}_${HOST}.txt
outfile_vals_only=${prognames[0]}_metrics_vals.txt
measured_metrics=${prognames[0]}_metrics_names.txt

rm -rf ${outfile} ${outfile_vals_only} ${measured_metrics}


if [ ! ${gen_metrics_file} ]; then
    
    i=0
    while IFS='' read -r line || [[ -n $line ]]; do
        metrics[$i]=$line
        i=$(($i+1))

        if [ $i -eq 4 ]; then
            i=0
            if [ ${kernels[0]} = "none" ]; then
                (nvprof --print-gpu-trace --metrics ${metrics[0]},${metrics[1]},${metrics[2]},${metrics[3]} --devices 0 --csv\
                     ${progs[0]} ${prog_args[0]}  > ${progs[0]}.out)  2>&1 | grep "Tesla" | head -1 > tmp
            else
                (nvprof --print-gpu-trace --metrics ${metrics[0]},${metrics[1]},${metrics[2]},${metrics[3]} --devices 0 --csv\
                     ${progs[0]} ${prog_args[0]} > ${progs[0]}.out)  2>&1 | grep "Tesla" | grep "${kernels[0]}" | head -1 > tmp
            fi
            
            vals=`cat tmp | awk -F "," '{ first = NF-3; second = NF-2; third = NF-1; printf $first " "  $second " " $third " " $NF }'`
            j=0;
            isCategory=""
            for v in $vals; do
              if [ "${isCategory}" = "true" ]; then 
                  v=${prev}" "${v}
                  isCategory="false"
              fi
              if [ "$v" = "\"Low" ] || [ "$v" = "\"Mid" ] || \
                 [ "$v" = "\"High" ] || [ "$v" = "\"Idle" ]; then
                  isCategory="true"
                  prev=$v
              else
                  if [ "$v" != "\"<OVERFLOW>\"" ] && [ "$v" != "\"<INVALID>\"" ]; then
                    echo ${metrics[$j]} >> ${measured_metrics}
                    echo $v  >> ${outfile_vals_only}
                  fi
                  j=$(($j+1))
              fi
            done            
            cat tmp >> ${outfile}
            rm -rf tmp
        fi
    done <  ${metrics_file}

    j=0
    while [ $j -lt $i ]; do
        if [ ${kernels[0]} = "none" ]; then
            (nvprof  --print-gpu-trace --metrics ${metrics[$j]} --devices 0 --csv \
                 ${progs[0]} ${prog_args[0]} > ${progs[0]}.out) 2>&1 |  grep "Tesla" | head -1 > tmp 
        else
            (nvprof  --print-gpu-trace --metrics ${metrics[$j]} --devices 0 --csv \
                 ${progs[0]} ${prog_args[0]} > ${progs[0]}.out)  2>&1 |  grep "Tesla" | grep "${kernels[0]}" | head -1 > tmp 
        fi
            
        val=`cat tmp | awk -F "," '{ print $NF }'`
        if [ "$val" != "\"<OVERFLOW>\"" ] && [ "$val" != "\"<INVALID>\"" ]; then
            echo ${metrics[$j]} >> ${measured_metrics}
            echo $val >> ${outfile_vals_only}
        fi

        cat tmp >> ${outfile}
        rm -rf tmp

        j=$(($j+1))
    done    
else 
    nvprof --query-metrics --devices 0 | grep ":" | awk -F ":" '{print $1}' | awk '{print $1}' \
                                       |  grep -v -E "Available|Device" > ${metrics_file}
fi


if [ ${trim} ]; then
  trim_gpu_metrics_file.sh ${outfile_vals_only} 
fi