#! /bin/bash

likwid-perfctr -e | grep ", PMC" | awk -F ',' '{print $1}' > eventlist
#likwid-perfctr -e | grep "," | awk -F ',' '{print $1}' >> raweventlist

#filter event list
#track=-1
#while read event
#do
#  temp=`echo $event | awk '{print $1}'`
#  if [ `echo $temp` = "Event" ] && [ $track -eq -1 ]; then
#     track=1
#  elif [ $track -eq 1 ]; then
#     printf "${event}\n" >> eventlist
#  fi
#done < raweventlist
