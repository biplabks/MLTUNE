#!/bin/bash

infile=$1

# get value, assume value in last col of space-delimited file
m1=`cat ${infile} | awk '{print $NF}'`

# remove rate unit (e.g., /s /GP etc.)
m1=`echo $m1 | sed "s/\/s//g" | sed 's/\%//g' | sed 's/GB//g' | sed 's/MB//g' | sed 's/B//g' | sed 's/K//g'`

# parentheses and quotes
m1=`echo $m1 | sed 's/\"//g' | sed "s/(//g" | sed 's/)//g'`

# remove category values 
m1=`echo $m1 | sed 's/Idle,\|Low,\|Mid,\|High,//g'` 

# remove spaces
m1=`echo $m1 | sed 's/\ //g'`

echo $m1


