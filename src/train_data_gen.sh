#! /bin/bash

function usage() {
    echo "usage: train_data_gen.sh [OPTIONS] FEATURE_LIST PROG_LIST"
    echo "Generate training data based on features in FEATURE_LIST and executable command in PROG_LIST"
    echo ""
    echo "See \${MLTUNE_ROOT}/README.md for FEATURE_LIST and PROG_LIST descriptions"
		echo " "
		echo "Options:"
		echo -e "   --help\t\t  print this help message"
    echo -e "   -m, --metric METRIC\t  METRIC can be pwr, time; default is time"
    echo -e "   -c, --class CLASS\t  CLASS can be bin or mult; default is bin"
    echo -e "   -o, --outfile FILE\t  name of output file; default is METRIC_train_data.csv"
    echo -e "   -p, --processor PROC\t  PROC can be cpu or gpu; default is cpu"
    echo -e "   -s, --source\t collect source code features"
}

MINARGS=2
if [ $# -lt ${MINARGS} ] || [ "$1" = "--help" ]; then
	usage
  exit 0
fi

while [ $# -gt 0 ]; do
  key="$1"
  case $key in
    -m|--metric)
      metric="$2"
      shift # option has parameter
			;;
    -c|--class)
			classification="$2"
      shift # option has parameter
      ;;
    -o|--outfile)
			outfile="$2"
      shift # option has parameter
      ;;
    -p|--processor)
			proc="$2"
      shift # option has parameter
      ;;
    -s|--source)
			src="true"
      ;;
    *)
			if [ "$eventfile" = "" ]; then
				eventfile=$1
			elif  [ "$progfile" = "" ]; then 
				progfile=$1
			else
				echo "Unknown option:" $key
				exit 0
			fi
			;;
  esac
  shift
done

# set default values 
[ "$metric" ] || { metric=time; }
[ "$outfile" ] || { outfile=${metric}_train_data.csv; }
[ "$classification" ] || { classification=bin; }
[ "$proc" ] || { proc=cpu; }
[ "$src" ] || { src=""; }

# check input files 
[ -r "$eventfile" ] || { echo "could not read feature list file. exiting ..."; exit 0; }
[ -r "$progfile" ] || { echo "could not read proglist file. exiting ..."; exit 0; }
 
DEBUG=""
if [ $DEBUG ]; then 
	echo $eventfile
	echo $progfile
	echo $metric
	echo $classification
	echo $outfile
	echo $src
fi
# clean up previous train data files 
rm -f $outfile

if [ $src ]; then
    echo -n "reg blks thrds " > ${outfile}
fi
          
# create header
while read event
do
  printf "${event}\t" >> $outfile
done < $eventfile
printf "\n" >> $outfile

if [ $proc = "cpu" ]; then			
  # conversion of events in eventfile to hexcodes
	get_hex_codes_from_names $eventfile > temp_hex_codes
fi

# 
# Extract feature values 
# 
while read line
do
	meta=`echo $line | awk -F ";;" '{print $1}'`
	build=`echo $line | awk -F ";;" '{print $2}'`
	exec=`echo $line | awk -F ";;" '{print $3}'`

	if [ "${meta}" = "" ]; then 
		echo "train_data_gen.sh: proglist file not formatted correctly. Exiting"
		exit 0
	fi
	if [ ${meta} = "+" ]; then 
		if [ $proc = "gpu" ]; then			
      if [ "$build" ]; then
				$build
      fi
			echo $exec > gpu_proglist

			# extract feature values 
			fts=`get_gpu_metrics.sh -i $eventfile -t gpu_proglist` 

			# extract register count and launch configuration from build cmd
			if [ $src ]; then
				if [ "$build" ]; then 
					prog=`echo $build | awk '{print $NF}'`				
					build_str=`echo $build | awk '{ for(i=1; i < NF; i++) printf $i" "}'`                
					build_str=$build_str"-l ""$prog"                
					res=`$build_str`
				fi
			fi
			fts=$res" "$fts			
  	# TODO: add a check to see if all metrics were measured. Handle mismatches accordingly
			echo $fts | awk '{ for (i = 1; i <= NF; i++) printf "%3.5f,",$i; printf "\n"}' >> forcsv.txt
			rm -rf gpu_proglist
		else 
		  perf_counter $outfile temp_hex_codes $exec   
		fi
	fi
done < $progfile

# cleanup tmp files 
rm -f temp_hex_codes

# 
# Collect performance metrics 
# 
outfile=$metric"_data.txt"
while read line
do
	meta=`echo $line | awk -F ";;" '{print $1}'`
	build=`echo $line | awk -F ";;" '{print $2}'`
	exec=`echo $line | awk -F ";;" '{print $3}'`

	if [ $proc = "gpu" ]; then

		# gpu exec cmd includes kernel name 
		kernel=`echo $exec | awk '{print $1}'`
		exec=`echo $exec | awk '{ for (i = 2; i <= NF; i++) print $i}'`

    if [ "$build" ]; then
		    $build
    fi

    res=`get_primary_gpu.sh -m pwr -k ${kernel} -- $exec`
		echo $meta $res >> ${outfile}

	else
		if [ $metric == "power" ]; then
      get_primary_power.sh $exec >> ${outfile} 
		elif [ $metric == "energy" ]; then
      get_primary_energy.sh $exec >> ${outfile} 
		elif [ $metric == "exec" ]; then
      get_primary_runtime.sh $exec >> ${outfile} 
		fi
	fi
done < $progfile

# 
# Labeling 
# 
trackcsv=0
csvVal=$trackcsv'p'
classification=bin
while read line
do
	meta=`echo $line | awk '{print $1}'`
	if [ "${meta}" = "" ]; then 
		echo "train_data_gen.sh : proglist file not formatted correctly. Exiting"
		exit 0
	fi

	if [ ${meta} = "+" ]; then 
		numerator=`echo $line | awk '{print $2}'`
		trackcsv=$((trackcsv+1))
		csvVal=$trackcsv'p'
	else 
		denominator=`echo $line | awk '{print $2}'`

		# compute speedup/power/energy gain 
		result=`echo "scale=2; $numerator/$denominator" | bc`

		a=1
		if [ $classification = "bin" ]; then
			if [ $(bc <<< "$result > $a") -eq 1 ]; then
				echo "good" >> $metric"_training_data.txt"
       # echo "1" >> targetdata
				echo "good" >> targetdata
				trainVal=good
			else
				echo "bad" >> $metric"_training_data.txt"
      #echo "0" >> targetdata
				echo "bad" >> targetdata
				trainVal=bad
			fi
		else 
			echo "multi classification not supported." ; exit 0
		fi
		
		echo `sed -n $csvVal forcsv.txt`$trainVal >> ${meta}_${metric}"_training_data.csv"
	fi
done < ${outfile}

rm -rf metrics_*.txt forcsv.txt *_speedups.txt avg_training_data.txt targetdata execlist  ${metric}_*.txt 
