#!/bin/bash

function usage() {
/bin/cat 2>&1 <<"EOF"
     
Usage:  get_primary_gpu.sh [ OPTIONS ] -- prog [ prog args ]

Options: 
   --help          print this help message
   -a              run benchmark with all available input sets 
   -v, --verbose   print data labels and diagnostics (not suitable for generating CSV)

Optionss with values:

	 --more			 
   -m, --metric <metric>    
              The performance <metric> to be evaluated. 
              <metric> can be one of the following
                  time: 
                  pwr: 

									cache: L1 and L2 cache hit rates

                  memdiv: 

                  ipc:

                  intensity: 

									ctrldiv: branch divergence and predicated efficiency

                  parallelism: thread parallelism is measured with achieved_occupancy. ILP is
                               esitmated with issue_slot_utilization

                  reuse: reuse ratio

									fault: fault concurrency

									migration: data migration

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
			i=0
			next_kernel="$2"
			while [ ${next_kernel:0:1} != "-" ]; do
				kernels[$i]=${next_kernel}
				i=$(($i + 1))
				shift
				next_kernel="$2"
			done
			num_kernels=$i
      ;;
		--keep)
      keep=true
      ;;
		--more)
      more=true
      ;;
		-v|--verbose)
      verbose=true
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
[ "$kernels" ] || { kernels[0]=none; }

if [ $DEBUG ]; then 
    echo $metric
    echo ${kernels[@]}
		echo ${num_kernels}
    echo $execstr
		
fi

function cleanup() {
	# clean up 
	if [ ! "$keep" ]; then 
			rm -rf tmp prog.out profile.tmp
	fi
}

if [ ${metric} = "time" ] || [ ${metric} = "pwr" ]; then 

		(nvprof -u ms --system-profiling on  $execstr > prog.out) 2> tmp
		if [ "${kernels[0]}" = "none" ]; then 
				if [ "$verbose" ]; then 
						echo "no kernel specified; cannot measure execution time"
				fi
				time=0.0
		else 
			total_time=0
			for ((i=0; i < ${num_kernels}; i++)); do
				time=`cat tmp | grep  "${kernels[$i]}(" | awk '{if ($1 == "GPU") print $4; else print $2}'` # average time per kernel
				total_time=`echo ${total_time} ${time} | awk '{printf "%3.2f", $1 + $2}'`
			done
		fi
		total_time=`echo ${total_time} | awk '{printf "%3.3f", $1}'`

		h2d=`cat tmp | grep "HtoD" | awk '{if ($1 == "GPU") print $4; else print $2}'`
		d2h=`cat tmp | grep "DtoH" | awk '{if ($1 == "GPU") print $4; else print $2}'`

		pwr=`cat tmp  | grep "Power" | awk '{print $6}'`  # peak
		pwr_avg=`cat tmp  | grep "Power" | awk '{print $4}'`  # average
		pwr=`echo $pwr | awk '{printf "%3.2f", $1/1000}'`
		pwr_avg=`echo $pwr_avg | awk '{printf "%3.2f", $1/1000}'`
fi

if [ ${metric} = "time" ]; then 
		if [ "$verbose" ]; then 
				echo "kernel_execution_time(ms)","H2D_cp_time(ms)","D2H_cp_time(ms)"
		fi
		echo -n ${total_time} 
		if [ ${h2d} ]; then
				echo -n ,$h2d
		fi
		if [ ${d2h} ]; then
				echo -n ,$d2h
		fi
		echo ""
fi

if [ ${metric} = "pwr" ]; then 
    echo $pwr ${pwr_avg}
fi


if [ ${metric} = "ctrldiv" ]; then 

	counter[0]="branch_efficiency"                   # thread parallelism 
	counter[1]="warp_nonpred_execution_efficiency"   # ILP
	
	(nvprof --metrics ${counter[0]},${counter[1]} $execstr > prog.out) 2> profile.tmp
	if [ ${kernels[0]} = "none" ]; then 
		branch=`cat profile.tmp | grep ${counter[0]} | head -1 | awk '{print $NF}'` 
		predicated=`cat profile.tmp | grep ${counter[1]} | head -1 | awk '{print $NF}'` 
	else
		branch=`cat profile.tmp | grep ${kernels[0]} -A 2 | grep ${counter[0]} | awk '{print $NF}'` 
		predicated=`cat profile.tmp | grep ${kernels[0]} -A 2 | grep ${counter[1]} | awk '{print $NF}'` 
	fi
	branch=`echo ${branch} | sed 's/\%//g'` 
	predicated=`echo ${predicated} | sed 's/\%//g'` 
	if [ "$verbose" ]; then 
			echo "branch_efficiency,predicated_efficiency"
	fi
	echo ${branch} ${predicated} | awk '{printf "%3.2f,%3.2f\n", $1, $2}'
fi

if [ ${metric} = "memdiv" ]; then 

	(nvprof --metrics gld_transactions_per_request,gst_transactions_per_request $execstr > prog.out) 2> profile.tmp
	if [ ${kernels[0]} = "none" ]; then 
		ld_div=`cat profile.tmp | grep "gld_transactions_per_request" | head -1 | awk '{print $NF}'` 
		st_div=`cat profile.tmp | grep "gst_transactions_per_request" | head -1 | awk '{print $NF}'` 
	else
		ld_div=`cat profile.tmp | grep ${kernels[0]} -A 3 | grep "gld_transactions_per_request" | awk '{print $NF}'` 
		st_div=`cat profile.tmp | grep ${kernels[0]} -A 3 | grep "gst_transactions_per_request" | awk '{print $NF}'` 
	fi
	ld_clsc=`echo ${ld_div} | awk '{ if ($1 == 0.0) printf "%3.4f", 1.00; else printf "%3.4f", 1/$1 }'` 
	st_clsc=`echo ${st_div} | awk '{ if ($1 == 0.0) printf "%3.4f", 1.00; else printf "%3.4f", 1/$1 }'` 

	if [ "$verbose" ]; then 
			if [ "$more" ]; then
					echo "load_div,store_div"
			fi
			echo "ld_coalesce,st_coalesce"
	fi
	if [ "$more" ]; then
			echo ${ld_div},${st_div}			
	fi
	echo ${ld_clsc} ${st_clsc} | awk '{printf "%3.2f,%3.2f\n", $1, $2}'
fi

if [ ${metric} = "ipc" ]; then 
		if [ ${kernel} = "none" ]; then
			ipc=`nvprof --metrics ipc $execstr 2>&1 | grep ipc | awk '{print $7}'`
			echo $ipc | awk '{printf "%3.3f\n", $1}'
		else
			ipc=`nvprof --metrics ipc $execstr 2>&1 | grep ${kernels[0]} -A 1 | awk '{print $7}'`
			echo $ipc | awk '{printf "%3.3f\n", $NF}'
		fi
fi

if [ ${metric} = "intensity" ]; then
		# try single precision first
		counter="flop_count_sp"
		if [ ${kernels[0]} = "none" ]; then 
			flop=`nvprof --metrics ${counter} $execstr 2>&1 | grep ${counter} | awk '{print $NF}'`		
		else
			flop=`nvprof --metrics ${counter} $execstr 2>&1 | grep ${kernels[0]} -A 1 | grep ${counter} | awk '{print $NF}'`		
		fi
		# if no SP count, try double precision
		if [ "$flop" -eq 0 ]; then
				counter="flop_count_dp"
				flop=`nvprof --metrics ${counter} $execstr 2>&1 | grep ${kernels[0]} -A 1 | grep ${counter} | awk '{print $NF}'`		
				if [ "$flop" -eq 0 ]; then
						counter="inst_executed"
						flop=`nvprof --metrics ${counter} $execstr 2>&1 | grep ${kernels[0]} -A 1 | grep ${counter} | awk '{print $NF}'`		
				else
						echo "Cannot determine intensity, no arithmetic operations performed"
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

		if [ "$more" ]; then 
				echo -n $flop","$data"," 
		fi
		echo -n -e $flop $data  | awk '{printf "%3.2f,", $1 / $2 }'
#		echo $data $flop  | awk '{printf "%3.2f\n", $1 / $2 }'
fi

if [ ${metric} = "parallelism" ]; then 

		counter[0]="achieved_occupancy"       # thread parallelism 
		counter[1]="issue_slot_utilization"   # ILP

		(nvprof --metrics ${counter[0]},${counter[1]} $execstr > prog.out) 2> profile.tmp

		if [ ${kernel} = "none" ]; then
			occupancy=`cat profile.tmp | grep ${counter[0]} | awk '{print $NF}'`
			occupancy=`echo $occupancy | awk '{print $1}'`

			ilp=`cat profile.tmp | grep ${counter[1]} | awk '{print $NF}'`
			ilp=`echo $ilp | awk '{print $1}'`
			ilp=`echo $ilp | sed 's/\%//g'`
		else
			occupancy=`cat profile.tmp | grep ${kernels[0]} -A 2  | grep ${counter[0]} | awk '{print $NF}'`
			ilp=`cat profile.tmp | grep ${kernels[0]} -A 2  | grep ${counter[1]} | awk '{print $NF}'`
			ilp=`echo $ilp | sed 's/\%//g'`
		fi

		if [ "$verbose" ]; then 
				echo "achieved_occupancy,issue_slot_utilization"
		fi
		echo $occupancy,$ilp
fi

if [ ${metric} = "gflops" ]; then 
    # try single precision first
		counter="flop_count_sp"
		if [ ${kernels[0]} = "none" ]; then 
			flop=`nvprof --metrics ${counter} $execstr 2>&1 | grep ${counter} | awk '{print $NF}'`		
		else
#			echo "nvprof --metrics ${counter} $execstr 2>&1 | grep ${kernels[0]} -A 1 | grep ${counter} | awk '{print $NF}'"
			flop=`nvprof --metrics ${counter} $execstr 2>&1 | grep ${kernels[0]} -A 1 | grep ${counter} | awk '{print $NF}'`		
		fi
		if [ "$flop" = "" ]; then
				echo "something wrong"
				exit 0
		fi
		# if no SP count, try double precision
		if [ "$flop" -eq 0 ]; then
				counter="flop_count_dp"
				flop=`nvprof --metrics ${counter} $execstr 2>&1 | grep ${kernels[0]} -A 1 | grep ${counter} | awk '{print $NF}'`		
				if [ "$flop" -eq 0 ]; then
						counter="inst_executed"
						flop=`nvprof --metrics ${counter} $execstr 2>&1 | grep ${kernels[0]} -A 1 | grep ${counter} | awk '{print $NF}'`		
				fi
				if [ "$flop" -eq 0 ]; then
						echo "not a floating-point application. Can only compute intensity of FP applications"
						exit 0
				fi
		fi

		(nvprof -u ms --system-profiling on  $execstr > prog.out) 2> tmp
		if [ "${kernels[0]}" = "none" ]; then 
			time=`cat tmp | grep "Time(%)" -m 1 -A 2 2>&1 | tail -1 | awk '{print $2/($1/100)}'`
		else 
			time=`cat tmp | grep  "${kernels[0]}(" | awk '{if ($1 == "GPU") print $4; else print $2}'`
		fi
		time=`echo $time | awk '{printf "%3.3f", $1}'`
		h2d=`cat tmp | grep "HtoD" | awk '{if ($1 == "GPU") print $4; else print $2}'`
		d2h=`cat tmp | grep "DtoH" | awk '{if ($1 == "GPU") print $4; else print $2}'`

		# if [ ${h2d} ]; then
		# 	echo -n $time,$h2d,
		# else
		# 	h2d=0.0
		# 	echo -n $time,$h2d,
		# fi
#		echo $flop $time $h2d | awk '{printf "%3.2f,", ($1 /1000000000) / (($2 + $3)/1000) }'
		echo -n $time,
		echo $flop $time | awk '{printf "%3.2f\n", ($1 /1000000000) / ($2/1000) }'

fi

if [ ${metric} = "cache" ]; then
		(nvprof -u ms -m l2_tex_read_hit_rate,l2_tex_write_hit_rate,tex_cache_hit_rate --system-profiling on $execstr > prog.out) 2> profile.tmp
		l2_read=`cat profile.tmp | grep -A 3 "${kernels[0]}(" | grep read_hit | awk '{print $NF}'`		
		l2_read=`echo ${l2_read} | sed 's/\%//g'`
		l2_write=`cat profile.tmp | grep -A 3 "${kernels[0]}(" | grep write_hit | awk '{print $NF}'`		
		l2_write=`echo ${l2_write} | sed 's/\%//g'`
		l1=`cat profile.tmp | grep -A 3 "${kernels[0]}(" | grep tex_cache | awk '{print $NF}'`		
		l1=`echo ${l1} | sed 's/\%//g'`
		if [ "$verbose" ]; then 
				echo -n -e "L2_read_hit_rate",
				if [ "$more" ]; then 
						echo -n -e  "L2_write_hit_rate",
				fi
				echo "L1_hit_rate"
		fi

		echo -n -e $l2_read,
		if [ "$more" ]; then 
				echo -n -e $l2_write,
		fi
		echo $l1
fi


if [ ${metric} = "migration" ]; then

		(nvprof -u ms --system-profiling on $execstr > prog.out) 2> profile.tmp
		h2d=`cat profile.tmp | grep "Host To" | awk  '{print $5}'`

		for m in B KB MB GB; do 
			unit_check=`echo $h2d | grep $m`
			if [ ${unit_check} ]; then
					unit=$m
					h2d=`echo $h2d | sed 's/$m//'`
			fi
		done

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
		
		h2d=`echo $h2d | awk -v byte_convert=$multiplier '{print $1 * byte_convert}'`

		d2h=`cat profile.tmp | grep "Device To" | awk  '{print $5}'`

		for m in B KB MB GB; do 
			unit_check=`echo $d2h | grep $m`
			if [ ${unit_check} ]; then
					unit=$m
					d2h=`echo $d2h | sed 's/$m//'`
			fi
		done

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

		d2h=`echo $d2h | awk -v byte_convert=$multiplier '{print $1 * byte_convert}'`
		echo $h2d,$d2h

fi


if [ ${metric} = "fault" ]; then
    # get volume of data copied over PCIe using memcpy
		(nvprof -u ms  --print-gpu-trace --system-profiling on $execstr > prog.out) 2> profile.tmp

		# get unit
		faults=`cat profile.tmp | grep "GPU page" | awk '{print $18}'`
		sum=0
		num_groups=0
		for i in ${faults}; do
			sum=$(($sum + $i)) 
			num_groups=$((${num_groups} + 1))
		done 
		faults=$sum
		candidate_faults=$(($faults - 1))

		concurrent_faults=$(($faults - ${num_groups}))
		fault_concurrency=`echo ${concurrent_faults} ${candidate_faults} | awk '{printf "%3.2f", $1 / $2}'`

		if [ "$more" ]; then
				echo -n -e $faults,${num_groups},
		fi
		echo ${fault_concurrency}
fi

if [ ${metric} = "reuse" ]; then
    # get volume of data copied over PCIe using memcpy
		(nvprof -u ms  --print-gpu-trace --system-profiling on $execstr > prog.out) 2> profile.tmp

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
			# only consider whole bytes (strip out digits right of the decimal
			i=`echo $i | awk -F "." '{print $1}'`
			sum=$(($sum+$i)) 
		done 
		d2h_copy=$sum
		
		# get volume of traffice between device memory and L2 cache 
    (nvprof -u ms -m dram_read_bytes,dram_write_bytes --system-profiling on $execstr > prog.out) 2> profile.tmp
		invocations=`cat profile.tmp | grep dram_read | awk '{print $1}'`
		if [ "${kernels[0]}" = "none" ]; then 
				dram2l2=`cat profile.tmp | grep dram_read | awk '{print $NF}'`
				dram2l2=`echo $dram2l2 | awk '{print $1}'`
		else
				dram2l2=`cat profile.tmp | grep -A 1 "${kernels[0]}(" | grep dram_read | awk '{print $NF}'`
		fi
		dram2l2=`echo $dram2l2 $invocations | awk '{print $1 * $2}'`
		if [ "${kernels[0]}" = "none" ]; then 
				l22dram=`cat profile.tmp | grep dram_write | awk '{print $NF}'`
				l22dram=`echo $l22dram | awk '{print $1}'`
		else
				l22dram=`cat profile.tmp | grep -A 2 "${kernels[0]}(" | grep dram_write | awk '{print $NF}'`
		fi
		l22dram=`echo $l22dram $invocations | awk '{print $1 * $2}'`
		reuse_ratio=`echo $h2d_copy $d2h_copy $dram2l2 $l22dram | awk '{printf "%3.2f", ($3 + $4)/($1 + $2)}'`
		reuse_ratio=`echo ${reuse_ratio} | awk '{if ($1 == 0.0) printf "%3.2f", 0.05; else printf "%3.2f", $1}'` 
		if [ "$verbose" ]; then 
				if [ "$more" ]; then 
						echo "H2D_copy(B)", "D2H_copy(B)","HBM-L2_traffic(B)", "L2-HBM_traffic(B)"
				fi
				echo "reuse_ratio"
		fi
		if [ "$more" ]; then 
				echo -n -e $h2d_copy,$d2h_copy,$dram2l2,$l22dram,
		fi

		echo ${reuse_ratio}
fi


cleanup
