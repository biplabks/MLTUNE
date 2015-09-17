#!/bin/bash

# likwid-based script to measure several primary performance metrics for
# workloads or application binaies 

if [ $# -lt 1 ]; then
  echo "usage :"
  echo "    $0 prog [ prog args ]"
  echo "    prog = path to executable or script (for workloads)"
  echo "    prog args = arguments to program or script"
  exit
fi


execstr=$@


# determine number of cores using nproc
NPROC=`which nproc`
[ $NPROC  ] || { echo  "could not determine number of cores\nexiting ...;"; exit; }

CORES=`${NPROC}`
CORES=$(($CORES - 1))

# get all basic stats from single run 
stats=`likwid-perfctr -g ENERGY -c 0-${CORES} $execstr 2> /dev/null\
  | grep -E "UNHALTED\_CORE STAT | INSTR\_RETIRED\_ANY STAT | Energy \[J\] STAT | Power \[W\] STAT | Runtime \(RDTSC\) \[s\] STAT" | awk -F "|" '{ if ($2 == "CPU_CLK_UNHALTED_CORE STAT") print $4; else print $3}'`


# runtime = sum of time on all cores / number of cores 
runtime=`echo -n ${stats} | awk -v CORES="${CORES}" '{printf "%3.2f", ($3 / CORES) }'`

# energy and power for entire processor, as reported by likwid
energy=`echo -n ${stats} | awk '{print $4}'`
power=`echo -n ${stats} | awk '{print $5}'`

# instructions per cycle = total instructions retired / MAX cycle count 
ipc=`echo -n ${stats} | awk '{printf "%3.2f",  ( $1 / $2 ) }'`

# MIPS (milllions of instructions per second) = total instructions retired / runtime 
ips=`echo -n ${stats} | awk -v TIME=${runtime} '{printf "%3.2f",  ( $1 / TIME ) }'`
ips=`echo "scale=2; $ips / 1000000" | bc -q 2> /dev/null`

# performance per watt : IPC / Power  
perfwatt=`echo "scale=2; $ipc / $power" | bc -q 2> /dev/null`

# performance per watt : IPS / Power 
perfwatt_ips=`echo "scale=2; $ips / $power" | bc -q 2> /dev/null`

if [ ! $outfile ]; then 
    echo $runtime $power
else 
    echo $runtime $power 
fi