#!/bin/bash

if [ $# -lt 1 ]; then
  echo "usage :"
  echo "    $0  <options> -- prog [ prog args ]"
  echo " Options "
  echo -e "    -m |--metric\t  [time,pwr] "
  echo -e "    -k |--kernel\t  kernel name"
  echo "    prog = path to executable or script (for workloads)"
  echo "    prog args = arguments to program or script"
  exit
fi


while [ $# -gt 0 ]; do
  key="$1"
  case $key in
    -m|--metric)
      metric="$2"
      shift # option has parameter
      ;;
    -k|--kernel)
      kernel="$2"
      shift # option has parameter
      ;;
    --)
      shift;
      execstr="$@"
      break;
      ;;
    *)
      echo Unknown option: $key
      exit 0
      ;;
  esac
  shift # option(s) fully processed, proceed to next input argument
done

[ "$metric" ] || { metric=time; }
[ "$kernel" ] || { kernel=none; }

if [ $DEBUG ]; then 
    echo $metric
    echo $kernel
    echo $execstr
fi

if [ ${metric} = "time" ] || [ ${metric} = "pwr" ]; then 

	(nvprof -u ms --system-profiling on $execstr > prog.out) 2> tmp

	if [ "$kernel" = "none" ]; then 
		time=`cat tmp | grep "Time(%)" -m 1 -A 2 2>&1 | tail -1 | awk '{print $2/($1/100)}'`
	else 
		time=`cat tmp | grep  ${kernel} | awk '{printf $2 " " $4}'`
	fi
	time=`echo $time | awk '{printf "%3.2f", $1}'`
	
	pwr=`cat tmp  | grep "Power" | awk '{print $4}'`
	pwr=`echo $pwr | awk '{printf "%3.2f", $1/1000}'`
	
	if [ ${metric} = "time" ]; then 
    echo $time 
	fi
	
	if [ ${metric} = "pwr" ]; then 
    echo $pwr 
	fi
  # clean up 
  rm -rf tmp prog.out
fi


if [ ${metric} = "memdiv" ]; then 
  ctrs=`nvprof --metrics gld_transactions_per_request,gst_transactions_per_request $execstr 2>&1 | grep "transactions_per_request" | awk '{print $NF}'`
	echo $ctrs 
fi
