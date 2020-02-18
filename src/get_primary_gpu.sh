#!/bin/bash

function usage() {
/bin/cat 2>&1 <<"EOF"
     
Usage:  get_primary_gpu.sh [ OPTIONS ] -- prog [ prog args ]

Options: 
   --help    print this help message
   -a        run benchmark with all available input sets 

Optionss with values:

   -m, --metric <metric>    
              The performance <metric> to be evaluated. 
              <metric> can be one of the following
                  time: 
                  pwr: 
                  memdiv: 
                  ipc:
                  intensity: 
                  occupancy:
                  reuse: reuse ratio

   -k, --kernel <kernel>    <kernel> to profile
   -b <bench>               <bench> is a Hetero-Mark executable

Examples:

   ./get_primary_gpu.sh -m pwr -k matrix_multiply -- mm 1000  

EOF
	exit 1
}

if [ "$1" = "--help" ] || [ $# -lt 1 ]; then
	usage
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
		--keep)
      keep=true
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

function cleanup() {
	# clean up 
	if [ ! "$keep" ]; then 
			rm -rf tmp prog.out, profile.tmp
	fi
}

if [ ${metric} = "time" ] || [ ${metric} = "pwr" ]; then 

		(nvprof -u ms --system-profiling on  $execstr > prog.out) 2> tmp
		if [ "$kernel" = "none" ]; then 
			time=`cat tmp | grep "Time(%)" -m 1 -A 2 2>&1 | tail -1 | awk '{print $2/($1/100)}'`
		else 
			time=`cat tmp | grep  "${kernel}(" | awk '{if ($1 == "GPU") print $4; else print $2}'`
		fi
		time=`echo $time | awk '{printf "%3.3f", $1}'`

		h2d=`cat tmp | grep "HtoD" | awk '{if ($1 == "GPU") print $4; else print $2}'`
		d2h=`cat tmp | grep "DtoH" | awk '{if ($1 == "GPU") print $4; else print $2}'`

		pwr=`cat tmp  | grep "Power" | awk '{print $6}'`  # peak
#		pwr=`cat tmp  | grep "Power" | awk '{print $4}'`  # average
		pwr=`echo $pwr | awk '{printf "%3.2f", $1/1000}'`
fi

if [ ${metric} = "time" ]; then 
    echo -n $time 
		if [ ${h2d} ]; then
				echo -n ,$h2d
		fi
		if [ ${d2h} ]; then
				echo -n ,$d2h
		fi
		echo ""
fi

if [ ${metric} = "pwr" ]; then 
    echo $pwr 
fi


if [ ${metric} = "memdiv" ]; then 
  ctrs=`nvprof --metrics gld_transactions_per_request,gst_transactions_per_request $execstr 2>&1 | grep "transactions_per_request" | awk '{print $NF}'`
	ld_div=`echo $ctrs | awk '{print $1}'`
	st_div=`echo $ctrs | awk '{print $2}'`
	echo ${ld_div} ${st_div} | awk '{printf "%3.2f,%3.2f\n", $1, $2 }'
fi

if [ ${metric} = "ipc" ]; then 
		if [ ${kernel} = "none" ]; then
			ipc=`nvprof --metrics ipc $execstr 2>&1 | grep ipc | awk '{print $7}'`
			echo $ipc | awk '{printf "%3.3f\n", $1}'
		else
			ipc=`nvprof --metrics ipc $execstr 2>&1 | grep ${kernel} -A 1 | awk '{print $7}'`
			echo $ipc | awk '{printf "%3.3f\n", $NF}'
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

if [ ${metric} = "gflops" ]; then 
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

		(nvprof -u ms --system-profiling on  $execstr > prog.out) 2> tmp
		if [ "$kernel" = "none" ]; then 
			time=`cat tmp | grep "Time(%)" -m 1 -A 2 2>&1 | tail -1 | awk '{print $2/($1/100)}'`
		else 
			time=`cat tmp | grep  "${kernel}(" | awk '{if ($1 == "GPU") print $4; else print $2}'`
		fi
		time=`echo $time | awk '{printf "%3.3f", $1}'`
		h2d=`cat tmp | grep "HtoD" | awk '{if ($1 == "GPU") print $4; else print $2}'`
		d2h=`cat tmp | grep "DtoH" | awk '{if ($1 == "GPU") print $4; else print $2}'`

		if [ ${h2d} ]; then
			echo -n $time,$h2d,
		else
			h2d=0.0
			echo -n $time,$h2d,
		fi
		echo $flop $time $h2d | awk '{printf "%3.2f\n", ($1 /1000000000) / (($2 + $3)/1000) }'

fi

if [ ${metric} = "reuse" ]; then
    # get volume of data copied over PCIe using memcpy
		nvprof -u ms  --print-gpu-trace --system-profiling on $execstr 2> profile.tmp

		# get unit
		unit=`cat profile.tmp | head -5 | tail -1 | awk '{print $5}'`

		case $unit in
    "B")
			multiplier=1
			;;
    "KB")
			multiplier=1.0e+3
			;;
    "MB")
			multiplier=1.0e+6
			;;
    "GB")
			multiplier=1.0e+9
			;;
    *)
      echo "Could not determine unit of data copy, bailing..."
			cleanup
      exit 0
      ;;
		esac

		h2d_copy=`cat profile.tmp | grep memcpy | grep HtoD | awk -v byte_convert=$multiplier '{print $8 * byte_convert}'`
		sum=0
		for i in ${h2d_copy}; do
			# only consider whole bytes (strip out digits right of the decimal
			i=`echo $i | awk -F "." '{print $1}'`
			sum=$(($sum+$i)) 
		done 
		h2d_copy=$sum
		
		d2h_copy=`cat profile.tmp | grep memcpy | grep DtoH | awk -v byte_convert=$multiplier '{print $8 * byte_convert}'`
		sum=0
		for i in ${d2h_copy}; do
			sum=$(($sum+$i)) 
		done 
		d2h_copy=$sum
		
		# get volume of traffice between devicem memory and L2 cache 
    nvprof -u ms -m dram_read_bytes,dram_write_bytes --system-profiling on $execstr 2> profile.tmp
    dram2l2=`cat profile.tmp | grep dram_read | awk '{print $NF}'`
    l22dram=`cat profile.tmp | grep dram_write | awk '{print $NF}'`

		reuse_ratio=`echo $h2d_copy $d2h_copy $dram2l2 $l22dram | awk '{printf "%3.2f", ($3 + $4)/($1 + $2)}'`
		echo $h2d_copy,$d2h_copy,$dram2l2,$l22dram,${reuse_ratio}

		
				#				cat profile.tmp | grep memcpy | awk '{print $9}'
		
fi


