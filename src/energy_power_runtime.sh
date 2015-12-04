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
	build=`echo $line | awk -F ";;" '{print $1}'`
	exec=`echo $line | awk -F ";;" '{print $2}'`

	if [ $proc = "gpu" ]; then
		# gpu proglist has kernel name and execute command 
		kernel=`echo $exec | awk '{print $1}'`
		exec=`echo $exec | awk '{ for (i = 2; i <= NF; i++) print $i}'`
		$build
		if [ $metric = "power" ]; then
      echo "biplab" ${kernel}          
      get_primary_gpu.sh -m pwr -k ${kernel} -- $exec >> ${outfile}
		elif [ $metric = "energy" ]; then
      get_primary_gpu.sh -m energy -k ${kernel} -- $exec >> ${outifle}
		elif [ $metric = "exec" ]; then
      get_primary_gpu.sh -m time -k ${kernel} -- $exec >> ${outfile}
		fi
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
while read line; do
	numerator=$line
	m=0
	while [ $m -lt $models ]; do
		read line
		denominator=$line
		# compute speedup/power/energy gain 
		result=`echo "scale=2; $numerator/$denominator" | bc`
		echo $result >> ${m}_speedups.txt 

		# running total of all speedups, for averaging later (used in picking labels)
		resultavg=`echo "scale=2; $result+$resultavg" | bc`
		track=$((track+1))
		m=$(($m+1))
	done
done < $metric"_data.txt"

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

trackcsv=1
csvVal=$trackcsv'p'
while read line
do
	numerator=$line
	m=0
	while [ $m -lt $models ]; do
		read line
		denominator=$line

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
		echo `sed -n $csvVal forcsv.txt`$trainVal >> ${m}_${metric}"_training_data.csv"
		m=$(($m+1))
	done
	trackcsv=$((trackcsv+1))
	csvVal=$trackcsv'p'
done < $metric"_data.txt"

m=0
while [ $m -lt $models ]; do
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
		echo `sed -n $csvVal forcsv.txt`$trainVal >> ${m}_avg_training_data.csv
		trackcsv=$((trackcsv+1))
		csvVal=$trackcsv'p'
	done < ${m}_speedups.txt
	m=$(($m+1))
	
done

# clean up 
rm -rf forcsv.txt *_speedups.txt avg_training_data.txt targetdata execlist ${metric}_*.txt 
