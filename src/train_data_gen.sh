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

MINARGS=4
if [ $# -lt $MINARGS ]; then
   echo "Usage:"
   echo "     $0 eventfile outfile progfile metric classification"
   echo "Try '$0 --help' for information"
   exit 0
fi

if [ $# -gt 4 ]; then
while [ $# -gt 4 ]; do
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
	-u|--user)
	    user="$5"
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

#eventfile=$1    # file that contains names of events that will be measured
#outfile=$2      # file to write the training data to
#progfile=$3     # file with a list of programs and program arguments
#metric=$4
#classification=$5
#echo $eventfile
#echo $outfile
#echo $progfile
#echo $metric
#echo $classification
#echo $user
#if [[ "$flagmetric" == "" ]]; then
# flagmetric="-k"
#fi


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
    #echo $metric    
    if [ "$metric" = "power" ] || [ "$metric" = "energy" ] || [ "$metric" = "exec" ]; then
       read line
    fi
    #if [ $flagmetric = "-l" ]; then
    #  read line
    #fi
done < $progfile

#cp trainlist testlist

if [ "$classification" = "bin" ] || [ "$classification" = "mult" ]; then
   #echo $classification
   energy_power_runtime.sh $metric $progfile $classification
fi

if [ "$user" = "automatic" ]; then
   echo "Please check file <targetdata> for classified target data"

#normalize outlist
   normalize.py -x $outfile -y execlist
   echo "Please check file <normfeaturelist> for normalized features"

#scale the normalized featurelist
   scale.py -x normfeaturelist
   echo "Please check file <scaledfeaturelist> for scale features"

#feature selection
   featureselection.py -x scaledfeaturelist -y targetdata -z 80
   echo "Please check file <featurelist> for final feature list"

#split featurelist(normalized outlist) to trainlist and testlist, and targetdata to targetDataToTrain(By default split is 70(train)-30(test))
   split_train_test.py -x featurelist -y targetdata -z 70
   echo "Please check <trainlist>,<testlist>,and <targetDataToTrain> for splitted information"

#train the model
   train_ml.py -x trainlist -y targetDataToTrain -o bin_file
   echo "Model has been deployed in bin_file"
fi

rm -f temp_hex_codes
