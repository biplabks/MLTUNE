#! /bin/bash

# Simple shell script to get hexadecimal parameter code
# for perfomance monitoring units.
# Use this as an aid for perf stat -e
# Instructions for this mapping found at https://software.intel.com/en-us/forums/topic/494707

# function pads and extracts digits from hex values
# in: 0x23 out: 23
# in: 0x2  out: 02
function pad_value {
    if [ ${#1} -eq 4 ];then
        echo ${1:2:3}
    else
        echo 0${1:2:2}
    fi
}


likwid-perfctr -e | tail -n +6  | grep -v "BOX" | while read event
do
    IFS=', '
    read -a tokens <<< "$event"
    evnum=$(pad_value ${tokens[1]})
    umask=$(pad_value ${tokens[2]})
    echo -e ${tokens[0]}"\t" $umask$evnum
done
