#! /bin/bash

if [ $# -lt 3 ]; then
    echo "usage:"
    echo "    $0 [options] proglist"
    exit
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
    -n|--models)
			models="$2"
      shift # option has parameter
      ;;
    *)
			if  [ "$progfile" = "" ]; then 
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
[ "$metric" ] || { metric=exec; }
[ "$classification" ] || { classification=bin; }
[ "$outfile" ] || { outfile=${metric}_train_data.csv; }
[ "$proc" ] || { proc=cpu; }
[ "$models" ] || { models=1; }


# threshold values for multi classification 
PCT=0.30

echo "Performing $metric data collection"
outfile=$metric"_data.txt"
while read line
do
	meta=`echo $line | awk -F ";;" '{print $1}'`
	build=`echo $line | awk -F ";;" '{print $2}'`
	exec=`echo $line | awk -F ";;" '{print $3}'`

	if [ $proc = "gpu" ]; then
		# gpu proglist has kernel name and execute command 
		kernel=`echo $exec | awk '{print $1}'`
		exec=`echo $exec | awk '{ for (i = 2; i <= NF; i++) print $i}'`
		$build
		if [ $metric = "power" ]; then
      echo "biplab" ${kernel}          
      res=`get_primary_gpu.sh -m pwr -k ${kernel} -- $exec`
		elif [ $metric = "energy" ]; then
      res=`get_primary_gpu.sh -m energy -k ${kernel} -- $exec`
		elif [ $metric = "exec" ]; then
      res=`get_primary_gpu.sh -m time -k ${kernel} -- $exec`
		fi
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

# get only execution time :: Why do we need this?
if [ $GETOPTIMIZED ]; then
	echo "Generating execution time for optimized program"
	while read line
	do
#		read line
		build=`echo $line | awk -F ";;" '{print $1}'`
		exec=`echo $line | awk -F ";;" '{print $2}'`
		
		if [ $proc = "gpu" ]; then
			kernel=`echo $exec | awk '{print $1}'`
			exec=`echo $exec | awk '{print $2}'`
			get_primary_gpu.sh -m time -k ${kernel} -- $exec >> execlist
		else
			get_primary_runtime.sh $exec >> execlist
		fi
	done < $progfile
fi

# calculating average
echo "Calculating average for $metric data"

resultavg=0
track=0
numerator=0

rm -rf *_speedups.txt
while read line; do
	meta=`echo $line | awk '{print $1}'`
	if [ "${meta}" = "" ]; then 
		echo "train_data_gen.sh : proglist file not formatted correctly. Exiting"
		exit 0
	fi

	if [ ${meta} = "+" ]; then 
		numerator=`echo $line | awk '{print $2}'`
	else 
		denominator=`echo $line | awk '{print $2}'`
		result=`echo "scale=2; $numerator/$denominator" | bc`
		echo $result >> ${meta}_speedups.txt 
		resultavg=`echo "scale=2; $result+$resultavg" | bc`
		track=$((track+1))
	fi
done < ${outfile} 
#	numerator=$line
	# m=0
	# while [ $m -lt $models ]; do
	# 	read line
	# 	denominator=$line
	# 	# compute speedup/power/energy gain 
	# 	result=`echo "scale=2; $numerator/$denominator" | bc`
	# 	echo $result >> ${m}_speedups.txt 

	# 	# running total of all speedups, for averaging later (used in picking labels)
	# 	resultavg=`echo "scale=2; $result+$resultavg" | bc`
	# 	track=$((track+1))
	# 	m=$(($m+1))
	# done

average=`echo "scale=2; $resultavg/$track" | bc`
goodup=`echo "scale=2; $average+($average*$PCT)" | bc`

if [ $DEBUG ]; then 
	echo "average : " $average
	echo "scaled average : " $goodup
fi

echo "Creating target data for $metric data"
goodlow=1.05
if [ $(bc <<< "$goodup < $goodlow") -eq 1 ]; then
 goodup=$goodlow
fi

# multi classifcation
top=$goodup
neutralup=1.05
neutrallow=0.95
bad=0.95

trackcsv=0
csvVal=$trackcsv'p'
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

#	numerator=$line
#	m=0
#	while [ $m -lt $models ]; do
#		read line
#		denominator=$line

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
		elif [ $classification = "mult" ]; then
			if [ $(bc <<< "$result > $top") -eq 1 ]; then
				echo "top" >> $metric"_training_data.txt"
				echo "top" >> targetdata
				trainVal=top
			elif [ $(bc <<< "$result <= $goodup") -eq 1 ] && [ $(bc <<< "$result > $goodlow") -eq 1 ]; then
				echo "good" >> $metric"_training_data.txt"
				echo "good" >> targetdata
				trainVal=good
			elif [ $(bc <<< "$result <= $neutralup") -eq 1 ] && [ $(bc <<< "$result > $neutrallow") -eq 1 ]; then
				echo "neutral" >> $metric"_training_data.txt"
				echo "neutral" >> targetdata
				trainVal=neutral
			elif [ $(bc <<< "$result <= $bad") -eq 1 ]; then
				echo "bad" >> $metric"_training_data.txt"
				echo "bad" >> targetdata
				trainVal=bad
			fi
		fi
		echo $csvVal
		echo `sed -n $csvVal forcsv.txt`$trainVal >> ${meta}_${metric}"_training_data.csv"
#		m=$(($m+1))
	fi
#	done
done < ${outfile}

#m=0
#while [ $m -lt $models ]; do
for resfile in `ls *_speedups.txt`; do
	model=`echo $resfile | awk -F "_" '{print $1}'`
	trackcsv=1
	csvVal=$trackcsv'p'
	while read line
	do
		trainres=$line
		if [ $(bc <<< "$trainres > $average") -eq 1 ]; then 
			echo "good" >> avg_training_data.txt
			trainVal=good
		else
			echo "bad" >> avg_training_data.txt
			trainVal=bad
		fi
		echo `sed -n $csvVal forcsv.txt`$trainVal >> ${model}_avg_training_data.csv
		echo $csvVal
		trackcsv=$((trackcsv+1))
		csvVal=$trackcsv'p'
	done < $resfile
done

# clean up 
rm -rf forcsv.txt *_speedups.txt avg_training_data.txt targetdata execlist  ${metric}_*.txt 
