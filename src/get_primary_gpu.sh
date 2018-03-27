#!/bin/bash

if [ $# -lt 1 ]; then
  echo "usage :"
  echo "    $0  <options> -- prog [ prog args ]"
  echo " Options "
  echo -e "    -m |--metric\t  [time,pwr,memdiv,ipc,intensity] "
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
			time=`cat tmp | grep  "${kernel}(" | awk '{printf $2 " " $4}'`
		fi
		time=`echo $time | awk '{printf "%3.4f", $1}'`
		
		pwr=`cat tmp  | grep "Power" | awk '{print $4}'`
		pwr=`echo $pwr | awk '{printf "%3.2f", $1/1000}'`
fi

if [ ${metric} = "time" ]; then 
    echo $time 
fi

if [ ${metric} = "pwr" ]; then 
    echo $pwr 
fi

# clean up 
rm -rf tmp prog.out



if [ ${metric} = "memdiv" ]; then 
  ctrs=`nvprof --metrics gld_transactions_per_request,gst_transactions_per_request $execstr 2>&1 | grep "transactions_per_request" | awk '{print $NF}'`
	ld_div=`echo $ctrs | awk '{print $1}'`
	st_div=`echo $ctrs | awk '{print $2}'`
	echo ${ld_div} ${st_div} | awk '{printf "%3.2f,%3.2f\n", $1, $2 }'
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

if [ ${metric} = "intensity" ]; then
		# try single precision first
		counter="flop_count_sp"
		if [ $kernel = "none" ]; then 
			flop=`nvprof --metrics ${counter} $execstr 2>&1 | grep ${counter} | awk '{print $NF}'`		
		else
			flop=`nvprof --metrics ${counter} $execstr 2>&1 | grep ${kernel} -A 1 | grep ${counter} | awk '{print $NF}'`		
		fi
		# if no SP count, try double precision
		if [ "$flop" -eq 0 ]; then
				counter="flop_count_dp"
				flop=`nvprof --metrics ${counter} $execstr 2>&1 | grep ${kernel} -A 1 | grep ${counter} | awk '{print $NF}'`		
				if [ "$flop" -eq 0 ]; then
						counter="inst_executed"
						flop=`nvprof --metrics ${counter} $execstr 2>&1 | grep ${kernel} -A 1 | grep ${counter} | awk '{print $NF}'`		
				fi
				if [ "$flop" -eq 0 ]; then
						echo "not a floating-point application. Can only compute intensity of FP applications"
						exit 0
				fi
		fi
		data=`nvprof --print-gpu-trace $execstr 2>&1 | grep "HtoD\|DtoH" | awk '{print $8}'`
		units="KB MB GB"
		byte_convert_factor[0]="1024"
		byte_convert_factor[1]="1048576"
		byte_convert_factor[2]="1073741824"
		
		total=0
		for d in $data; do
			i=0
			this_data=0
			for u in $units; do
				if [ `echo $d | grep "$u"` ]; then
						this_data=`echo $d | sed 's/$u//' | awk -v val="${byte_convert_factor[$i]}" '{printf "%i", $1 * val}'`  
				fi 
				i=$(($i+1))
			done
			total=$((${this_data}+${total}))
		done
		data=$total
		# adjust for measurement errors. nvprof under reports amount of data transferred
		# when probing with print-gpu-trace HtoD and DtoH
		# adjustment factor calculated with applications with known data transfer amount (i.e., dlbench)
		# reports correct numbers with unified memory profiling
		# should have a separate case to handle intensity for UM applications
    #	 data=`echo $total | awk '{printf "%i", $1 + $1 * 0.0483789}'`
		echo -n $flop","$data"," 
		echo $flop $data  | awk '{printf "%3.2f\n", $1 / $2 }'
fi

if [ ${metric} = "occupancy" ]; then 
		if [ ${kernel} = "none" ]; then
			occupancy=`nvprof --metrics achieved_occupancy $execstr 2>&1 | grep achieved_occupancy | awk '{print $7}'`
			echo $occupancy | awk '{print $1}'
		else
			occupancy=`nvprof --metrics achieved_occupancy $execstr 2>&1 | grep ${kernel} -A 1 | awk '{print $7}'`
			echo $occupancy | awk '{print $NF}'
		fi
fi
