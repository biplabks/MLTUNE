#! /bin/bash

function usage() {
    echo "usage: train_data_gen.sh [OPTIONS] FEATURE_LIST PROG_LIST"
    echo "Generate training data based on features in FEATURE_LIST and executable command in PROG_LIST"
    echo ""
    echo "See \${MLTUNE_ROOT}/README.md for FEATURE_LIST and PROG_LIST descriptions"
		echo " "
		echo "Options:"
		echo -e "   --help\t\t  print this help message"
    echo -e "   -m, --metric METRIC\t  METRIC can be power, energy or exec; default is exec"
    echo -e "   -c, --class CLASS\t  CLASS can be bin or mult for binary or multiple classification; \
                                     default is bin"
    echo -e "   -o, --outfile FILE\t  name of output file; default is METRIC_train_data.csv"
    echo -e "   -p, --processor PROC\t  PROC can be cpu or gpu; default is cpu"
    echo -e "   -n, --models NUM\t  number of ML models; default is 1"
    echo -e "   -s, --source, collect source code features"
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
    -n|--models)
			models="$2"
      shift # option has parameter
      ;;
    -s|--source)
			src=1
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
[ "$metric" ] || { metric=exec; }
[ "$outfile" ] || { outfile=${metric}_train_data.csv; }
[ "$classification" ] || { classification=bin; }
[ "$proc" ] || { proc=cpu; }
[ "$models" ] || { models=1; }
[ "$src" ] || { src=0; }

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

# create header
while read event
do
  printf "${event}\t" >> $outfile
done < $eventfile
printf "\n" >> $outfile

# conversion of events in eventfile to hexcodes
get_hex_codes_from_names $eventfile > temp_hex_codes

# read each line of prog and prog_args
while read line
do
	meta=`echo $line | awk -F ";;" '{print $1}'`
	build=`echo $line | awk -F ";;" '{print $2}'`
	exec=`echo $line | awk -F ";;" '{print $3}'`

	if [ "${meta}" = "" ]; then 
		echo "train_data_gen.sh : proglist file not formatted correctly. Exiting"
		exit 0
	fi
	if [ ${meta} = "+" ]; then 
		if [ $proc = "gpu" ]; then			
			$build
			echo $exec > gpu_proglist
			fts=`get_gpu_metrics.sh -i $eventfile -t gpu_proglist` 
			if [ $src -eq 1 ]; then
				if [ "$build" ]; then 
					prog=`echo $build | awk '{print $NF}'`				
				fi
			  res=`parboil_gen_variant.sh -s -l 0`				
				res=`echo $res | awk '{ for (i = 1; i <= NF; i++) printf "%3.0f,",$i;}'`
			fi
			fts=$res$fts
			
  		# TODO: add a check to see if all metrics were measured. Handle mismatches accordingly
			echo $fts | awk '{ for (i = 1; i <= NF; i++) printf "%3.5f,",$i; printf "\n"}' >> forcsv.txt
			rm -rf gpu_proglist
		else 
			perf_counter $outfile temp_hex_codes $exec   
		fi
  fi
done < $progfile

# cleanup
rm -f temp_hex_codes

if [ "$classification" = "bin" ] || [ "$classification" = "mult" ]; then
  energy_power_runtime.sh -n $models -p ${proc} -m $metric -c $classification $progfile 
fi 

