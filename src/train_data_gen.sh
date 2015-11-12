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
#rm -f temp_hex_codes
get_hex_codes_from_names $eventfile > temp_hex_codes

# read each line of prog and prog_args
while read line
do
  perf_counter $outfile temp_hex_codes $line   
	# skipping next line; want to get features baseline only
  if [ "$metric" = "power" ] || [ "$metric" = "energy" ] || [ "$metric" = "exec" ]; then
    read line
  fi
done < $progfile


if [ "$classification" = "bin" ] || [ "$classification" = "mult" ]; then
   energy_power_runtime.sh $metric $progfile $classification
fi 

# cleanup
rm -f temp_hex_codes
