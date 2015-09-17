#! /bin/bash

# script to generate hex codes for events specified in a file

if [ ! $# -eq 1 ]; then
    echo "usage:"
    echo "    $0 eventfile"
    exit
fi

file=$1
#SCRIPTDIR=/home/s_r248/prefetch_exp/scripts

hex_codes=$(get_perf_hex_codes.sh)

while read line
do
    ev_line=$(echo "$hex_codes" | grep -w $line)
    if [ $? == 1 ]; then
        echo "event name $line not found"
    else    
        echo $ev_line | awk '{printf "%s\n", $2}'
    fi
done < $file
