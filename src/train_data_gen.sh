#! /bin/bash

if [ $# -lt 3 ] && [ "$1" = "--help" ]; then
    echo "usage: "
    echo "    $0 <options> -- <PROG> [<ARGS>]"
    echo "         "
    echo "Options: "
    echo "      eventfile EVENTS TO BE MEASURED"
    echo "      outfile OUTPUT FILE TO STORE FEATURE VALUES"
    echo "      progfile WORKLOADS TO PRODUCE FEATURE VALUES"
    echo "      -l, --metric METRIC(power/energy/exec) TO GENERATE TARGET DATA"
    echo "      -c, --class CLASSIFICATION(bin/mult) TO CHOOSE BINARY OR MULTIPLE CLASSIFICATION"
    exit 0
fi
eventfile=$1
outfile=$2
progfile=$3

MINARGS=3
if [ $# -lt $MINARGS ]; then
   echo "Usage:"
   echo "     $0 eventfile outfile progfile metric classification"
   echo "Try '$0 --help' for information"
   exit 0
fi

if [ $# -gt 3 ]; then
while [ $# -gt 3 ]; do
    key="$4"
    case $key in
        -l|--metric)
            metric="$5"
            shift # option has parameter
	    ;;
        -c|--class)
	    classification="$5"
            shift # option has parameter
            ;;
        --)
				prog="$5"
        shift
				shift
				args=$@
				break
	    ;;
      *)
	    # unknown option
	    echo Unknown option: $key
 	    exit 0
	    ;;
    esac
    shift
done
fi


rm -f $outfile

# create header
while read event
do
    printf "${event}\t" >> $outfile
    #printf "${event}\t" >> trainlist
done < $eventfile
printf "\n" >> $outfile
#printf "\n" >> trainlist

# conversion of events in eventfile to hexcodes
rm -f temp_hex_codes
get_hex_codes_from_names $eventfile >> temp_hex_codes

# read each line of prog and prog_args
while read line
do
    perf_counter $outfile temp_hex_codes $line   
    if [ "$metric" = "power" ] || [ "$metric" = "energy" ] || [ "$metric" = "exec" ]; then
       read line
    fi
done < $progfile


if [ "$classification" = "bin" ] || [ "$classification" = "mult" ]; then
   energy_power_runtime.sh $metric $progfile $classification
fi 

rm -f temp_hex_codes
