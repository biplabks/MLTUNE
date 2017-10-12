#!/bin/bash

function usage() {
  echo "usage :"                                                               
  echo "    get_gpu_events.sh [OPTIONS] FILE"
  echo "    Collect cuda performance events for CUDA kernels described in FILE"
  echo "    Assumes all events are measurable (i.e., no error checking) "
  echo " "
  echo "        FILE is proglist file "
  echo "Options: "
  echo "      -o, --outpath DIR;  DIR is location of output file"
  echo "      -t, --trim;  trim output, emit one row containing just events vals "
  echo "      -i, --input FILE;  FILE is file containing list of events "
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
      fts_file="$2"
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
  echo ${fts_file}
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

CUDATUNE_HOME=$HOME/code/cudatuner


[ `which nvprof` ] || { echo "Could not find nvprof in path. Exiting..."; exit 1; }
[ `which deviceQuery` ] || { echo "Could not find deviceQuery. Exiting..."; exit 1; }

HOST=`hostname`
if [ $HOST = "ada.cs.txstate.edu" ]; then 
		DEVICE=`deviceQuery | grep "Device 0:" | awk '{print $5}' | sed 's/(//' | sed 's/)//' | sed 's/"//'`
else
		DEVICE=`deviceQuery | grep "Device 0:" | awk '{print $4}' | sed 's/"//'`
fi

# if user didn't supply events file then measure all available 
if [ "${fts_file}" = "" ]; then 
  fts_file=$CUDATUNE_HOME/info/events_${DEVICE}_${HOST}.txt
  [ -r ${fts_file} ] || { echo "No system events file found, generating new one."; gen_fts_file="true";}
else
  [ -r ${fts_file} ] || { echo "Could not open events file: ${fts_file}. Exiting"; exit 0;}
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

j=0
while [ $j -lt $i ]; do
	[ -x ${progs[$j]} ] || { echo "Cannot execute prog: ${progs[$j]}. Exiting"; exit 0;}
  j=$(($j+1))
done

if [ $DEBUG ]; then 
	j=0
  while [ $j -lt $i ]; do
    echo -e ${progs[$j]} "\t" ${prog_args[$j]}
    j=$(($j+1))
  done
fi

outfile=events_${prognames[0]}_${DEVICE}_${HOST}.txt
outfile_vals_only=${prognames[0]}_events_vals.txt
measured_events=${prognames[0]}_events_names.txt

rm -rf ${outfile} ${outfile_vals_only} ${measured_events}

hdr=""
while IFS='' read -r ft_line || [[ -n ${ft_line} ]]; do
	if [ "$hdr" = "" ]; then
		  hdr=${line}
	else
		hdr=${hdr}","${line}
	fi
done <  ${fts_file}

if [ ! ${gen_fts_file} ]; then
    fts=`wc -l ${fts_file} | awk '{print $1}'`
    i=0
		m=1
    while IFS='' read -r line || [[ -n $line ]]; do
        events[$i]=$line
        i=$(($i+1))
				
        if [ $i -eq 4 ]; then
            i=0
            if [ ${kernels[0]} = "none" ]; then
                (nvprof --events ${events[0]},${events[1]},${events[2]},${events[3]} --devices 0 --csv\
                     ${progs[0]} ${prog_args[0]}  > ${progs[0]}.out)  2>&1 | grep ${DEVICE} | head -1 > tmp
            else
                (nvprof --events ${events[0]},${events[1]},${events[2]},${events[3]} --devices 0 --csv\
                     ${progs[0]} ${prog_args[0]} > ${progs[0]}.out)  2>&1 | grep ${DEVICE} | grep "${kernels[0]}"  > tmp
            fi
            
            # vals=`cat tmp | awk -F "," '{ first = NF-3; second = NF-2; third = NF-1; printf $first " "  $second " " $third " " $NF }'`
            vals=`cat tmp | awk -F "," '{ print $NF }'`
            j=0;
            isCategory=""
            for v in $vals; do
              if [ "${isCategory}" = "true" ]; then 
                  v=${prev}","${v}
                  isCategory="false"
              fi
              if [ "$v" = "\"Low" ] || [ "$v" = "\"Mid" ] || \
                 [ "$v" = "\"High" ] || [ "$v" = "\"Idle" ]; then
                  isCategory="true"
                  prev=$v
              else
                  if [ "$v" != "\"<OVERFLOW>\"" ] && [ "$v" != "\"<INVALID>\"" ]; then
										 if [ $m -lt $fts ]; then 
											 echo -n ${events[$j]}"," >> ${measured_events}
											 echo $v","  >> ${outfile_vals_only}
										 else
											 echo ${events[$j]} >> ${measured_events}
											 echo $v  >> ${outfile_vals_only}
										 fi
									fi
									j=$(($j+1))
									m=$(($m+1))
							fi
            done            
            cat tmp >> ${outfile}
            rm -rf tmp
        fi
    done <  ${fts_file}

    j=0
    while [ $j -lt $i ]; do
        if [ ${kernels[0]} = "none" ]; then
            (nvprof --events ${events[$j]} --devices 0 --csv \
                 ${progs[0]} ${prog_args[0]} > ${progs[0]}.out) 2>&1 |  grep ${DEVICE}  > tmp 
        else
            (nvprof --events ${events[$j]} --devices 0 --csv \
                 ${progs[0]} ${prog_args[0]} > ${progs[0]}.out)  2>&1 |  grep ${DEVICE}  | grep "${kernels[0]}"  > tmp 
        fi
            
        val=`cat tmp | awk -F "," '{ print $NF }'`
        if [ "$val" != "\"<OVERFLOW>\"" ] && [ "$val" != "\"<INVALID>\"" ]; then
						if [ $j -lt $(($i - 1)) ]; then 
								echo -n ${events[$j]}"," >> ${measured_events}
								echo $val"," >> ${outfile_vals_only}
						else
								echo ${events[$j]}  >> ${measured_events}
								echo $val  >> ${outfile_vals_only}
							
						fi
				fi
        cat tmp >> ${outfile}
        rm -rf tmp

        j=$(($j+1))
    done    
else 
    nvprof --query-events --devices 0 | grep ":" | awk -F ":" '{print $1}' | awk '{print $1}' \
                                       |  grep -v -E "Available|Device" > ${fts_file}
fi

#echo $hdr
if [ ${trim} ]; then
  trim_gpu_events_file.sh ${outfile_vals_only}
fi
