#!/bin/bash

if [ $# -lt 3 ]; then
    echo "usage:"
    echo "    $0 outfile eventfile program [program arguments]"
    exit
fi


outfile=$1          # file to write counter values to
counterfile=$2      # file containing counter hex codes
prog=$3             # program being profiled
prog_args=${@:4}    # arguments of the program being profiled


# read events from event file, 4 when knuth or shadowfax
# otherwise 2 at a time
while read ev[0]
do
    read ev[1]

    if [ $HOST == "knuth" ] || [ $HOST == "shadowfax" ]; then 
        read ev[2]
        read ev[3]
    fi

    # concatenation of events to be passed to perf as a list of events to measure
    ev_arg=''
    for e in ${ev[@]}
    do
        if [ -z $ev_arg ]; then
            ev_arg="r${e}"
        else
            ev_arg="${ev_arg},r${e}"
        fi
    done

    # performance profiling
    #echo "perf stat -a -e ${ev_arg} -x '\t' $prog $prog_args"
    #echo "-----------Biplab1----------"
    res=$((perf stat -a -e $ev_arg -x '\t' $prog $prog_args) 2>&1>/dev/null | awk '{print $1}')
    #echo $res
    #echo "-----------Biplab2----------"
    for r in $res; do
        #if [ $r == "++" ]; then
	#   echo "Hello1"
	#elif [ $r == "+" ]; then
	#   echo "Hello2"
	#else
	#   printf "${r}\t" >> $outfile
	#fi
	if [ $r != "++" ] && [ $r != "+" ]; then
	    printf "${r}\t" >> $outfile
      printf "${r}," >> forcsv.txt
	fi
    done    
done < $counterfile

printf "\n" >> $outfile
printf "\n" >> forcsv.txt


