#! /bin/bash

if [ $# -lt 3 ]; then
    echo "usage:"
    echo "    $0 metric progfile classification"
    exit
fi

perfile=$1
progfile=$2
classification=$3
#flag=$2

#if [ $flag = "-l" ]; then
#   echo "flag"
#else
#   echo "Hello1"
#fi

#touch $perfile"_training_data.txt"

echo "Performing $perfile data collection"
#outfile=$perfile"_data.txt"

while read line
do
   if [ $perfile == "power" ]; then
      get_primary_power.sh $line >> power_data.txt
   elif [ $perfile == "energy" ]; then
      get_primary_energy.sh $line >> energy_data.txt
   elif [ $perfile == "exec" ]; then
      get_primary_runtime.sh $line >> exec_data.txt
   fi
   #if [ $flag != "-l" ]; then
   #  read line
   #fi
done < $progfile

#get only execution time
echo "Generating execution time for optimized program"
while read line
do
  read line
  #echo $line
  get_primary_runtime.sh $line >> execlist
done < $progfile

#echo "Performing power data collection"
#while read line
#do
#   get_primary_power.sh $line >> power_data.txt
   #if [ $flag != -l ]; then
   #  read line
   #fi
#done < $progfile

#m=5
#n=2
#k=`echo "scale=2; $m/$n" | bc`
#echo $k

resultavg=0
track=0

##calculating average
echo "Calculating average for $perfile data"
while read line
do
 numerator=$line
 read line
 denominator=$line
 result=`echo "scale=2; $numerator/$denominator" | bc`
 resultavg=`echo "scale=2; $result+$resultavg" | bc`
 track=$((track+1))
 #echo $track
 echo $result >> tasty.txt 
done < $perfile"_data.txt"

average=`echo "scale=2; $resultavg/$track" | bc`
percent=0.30
goodup=`echo "scale=2; $average+($average*$percent)" | bc`

#echo "average : " $average
#echo "scaled average : " $goodup


echo "Creating target data for $perfile data"
goodlow=1.05
if [ $(bc <<< "$goodup < $goodlow") -eq 1 ]; then
 goodup=$goodlow
fi
#echo "good up : " $goodup
top=$goodup
neutralup=1.05
neutrallow=0.95
bad=0.95

trackcsv=1
csvVal=$trackcsv'p'

while read line
do
 numerator=$line
 read line
 denominator=$line
 result=`echo "scale=2; $numerator/$denominator" | bc`
 #resultavg=`echo "scale=2; $result+$resultavg" | bc`
 #track=$((track+1))
 #echo $track
 #echo $result >> tasty.txt
 a=1
 if [ $classification = "bin" ]; then
   if [ $(bc <<< "$result > $a") -eq 1 ]; then
      echo "good" >> $perfile"_training_data.txt"
      #echo "1" >> targetdata
      echo "good" >> targetdata
      trainVal=good
      #echo `sed -n $csvVal forcsv.txt`"good" >> $perfile"_training_data.csv"
   else
      echo "bad" >> $perfile"_training_data.txt"
      #echo "0" >> targetdata
      echo "bad" >> targetdata
      trainVal=bad
      #echo `sed -n $csvVal forcsv.txt`"bad" >> $perfile"_training_data.csv"
   fi
 elif [ $classification = "mult" ]; then
   #top=1.40
   #goodup=1.40
   #goodlow=1.05
   #neutralup=1.05
   #neutrallow=0.95
   #bad=0.95
   if [ $(bc <<< "$result > $top") -eq 1 ]; then
       echo "top" >> $perfile"_training_data.txt"
       echo "top" >> targetdata
       trainVal=top
   elif [ $(bc <<< "$result <= $goodup") -eq 1 ] && [ $(bc <<< "$result > $goodlow") -eq 1 ]; then
       echo "good" >> $perfile"_training_data.txt"
       echo "good" >> targetdata
       trainVal=good
   elif [ $(bc <<< "$result <= $neutralup") -eq 1 ] && [ $(bc <<< "$result > $neutrallow") -eq 1 ]; then
       echo "neutral" >> $perfile"_training_data.txt"
       echo "neutral" >> targetdata
       trainVal=neutral
   elif [ $(bc <<< "$result <= $bad") -eq 1 ]; then
       echo "bad" >> $perfile"_training_data.txt"
       echo "bad" >> targetdata
       trainVal=bad
   fi
 fi
 echo `sed -n $csvVal forcsv.txt`$trainVal >> $perfile"_training_data.csv"
 trackcsv=$((trackcsv+1))
 csvVal=$trackcsv'p'
done < $perfile"_data.txt"

#if [ $(bc <<< "$goodup < $goodlow") -eq 1 ]; then
# goodup=$goodlow


#percent=0.25
#resultavg=`echo "scale=2; $resultavg/$track" | bc`
#resultavg=`echo "scale=2; $resultavg+($resultavg*$percent)" | bc`

#echo $resultavg
trackcsv=1
csvVal=$trackcsv'p'

while read line
do
  trainres=$line
  #echo $trainres $average
  #if [ $line -gt $resultavg ]; then
  if [ $(bc <<< "$trainres > $average") -eq 1 ]; then 
    echo "good" >> avg_training_data.txt
    trainVal=good
  else
    echo "bad" >> avg_training_data.txt
    trainVal=bad
  fi
  echo `sed -n $csvVal forcsv.txt`$trainVal >> avg_training_data.csv
  trackcsv=$((trackcsv+1))
  csvVal=$trackcsv'p'
done < tasty.txt


#echo "Creating training data for power data"
#while read line
#do
# numerator=$line
# read line
# denominator=$line
# result=`echo "scale=2; $numerator/$denominator" | bc`
# echo $result
# a=1
# if [ $(bc <<< "$result > $a") -eq 1 ]; then
#   echo "1" >> power_training_data.txt
# else
#   echo "0" >> power_training_data.txt
# fi
#done < power_data.txt

#rm energy_data.txt
#rm power_data.txt
#rm runtime_data.txt

