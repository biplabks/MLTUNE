#!/bin/bash

if [ $# -lt 1 ]; then
  echo "usage :"
  echo "    $0  <options> -- prog [ prog args ]"
  echo " Options "
  echo -e "    -m |--metric\t  [time,pwr,memdiv,ipc] "
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

if [ ${metric} = "time" ]; then 

		# Not using nvprof; getting runtime reported from source for consistency
		if [ $kernel = "eps" ] || [ $kernel = "drelax" ]; then 
				 time=`$execstr | grep "runtime" | awk '{print $4}'`
		else
			(nvprof -u ms --system-profiling on $execstr > prog.out) 2> tmp
			if [ "$kernel" = "none" ]; then 
					time=`cat tmp | grep "Time(%)" -m 1 -A 2 2>&1 | tail -1 | awk '{print $2/($1/100)}'`
			else 
				time=`cat tmp | grep  ${kernel} | awk '{printf $2 " " $4}'`
			fi
			time=`echo $time | awk '{printf "%3.4f", $1}'`
		fi
		echo $time 
		
fi

if [ ${metric} = "pwr" ]; then 
	pwr=`cat tmp  | grep "Power" | awk '{print $4}'`
	pwr=`echo $pwr | awk '{printf "%3.2f", $1/1000}'`
  echo $pwr 
fi

if [ ${metric} = "memdiv" ]; then 
  ctrs=`nvprof --metrics gld_transactions_per_request,gst_transactions_per_request $execstr 2>&1 | grep -A 2 "${kernel}" | grep "transactions_per_request" | awk '{print $NF}'`
	ld_div=`echo $ctrs | awk '{print $1}'`
	st_div=`echo $ctrs | awk '{print $2}'`
	echo ${ld_div},${st_div}
fi

if [ ${metric} = "ipc" ]; then 
		if [ ${kernel} = "none" ]; then
			ipc=`nvprof --metrics ipc $execstr 2>&1 | grep ipc | awk '{print $7}'`
			echo $ipc | awk '{print $1}'
		else
			ipc=`nvprof --metrics ipc $execstr 2>&1 | grep ${kernel} -A 1 | awk '{print $7}'`
			echo $ipc | awk '{print $NF}'
		fi
fi

# clean up 
rm -rf tmp prog.out


