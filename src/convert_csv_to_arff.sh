#!/bin/bash

#
# converts csv datafile to weka input file  in arff format
# needed if we are using MLTUNE with weka ML engine 
#

if [ $# -lt 3 ]; then
  echo "usage :"
  echo "    `basename $0` datafile attrib_file model [objective]"
  echo "        data_file = file containing data in csv format (.csv extension expected)"
  echo "        attrib_file = file containing (pruned) attribute names"
  echo "        model = {regr, logit}"
  echo "        objective = {# of cycles, avg power}"
  exit
fi

# process command-line args 
datafile="$1"
[ -r $datafile ] || { echo "could not find data file: $datafile. exiting ..."; exit 1; }

attrib_names="$2"
[ -r $attrib_file ] || { echo "could not find attribute file: $attrib_file. exiting ..."; exit 1; }

model="$3"


echo "Checking CSV file and gathering class information"


lines=`wc -l ${datafile} | awk '{print $1}'`

[ $lines -gt 10 ] || { echo "not enough instances. Not converting."; exit 0; }

cp ${datafile} ${datafile}_copy
i=1
class_cnt=0
mod=0
while read line; do
  class=`echo $line | awk -F "," '{print $NF}'`

  new=true
  j=0
  while [ $j -lt ${class_cnt} ]; do
      if [ ${classes[$j]} = $class ]; then
          new=false
          break
      fi
      j=$(($j + 1))
  done

  if [ $new = "true" ]; then
      classes[${class_cnt}]=$class
      class_cnt=$((${class_cnt} + 1))
  fi
  cur_fields=`echo $line | awk -F "," '{print NF}'`
  if [ $i -eq 1 ]; then
     fields=${cur_fields} 
  fi
  if [ $fields -ne ${cur_fields} ]; then
    echo "CSV file not formatted correctly. Deleting entry";
    sed -i "$i d" ${datafile}_copy
		mod=1
  else
      i=$(($i + 1))
  fi
done < $datafile


# data.csv => data.arff
arff_file=`basename $datafile .csv`.arff

# write header info into arff file 
echo "@relation perf" > $arff_file
cat $attrib_names | awk '{printf "@attribute " $1 " numeric\n"}' >> $arff_file

# predictive models
if [ $model = "regr" ]; then
  if [ $obj = "#ofcycles" ]; then 
    echo "@attribute speedup numeric" >> $arff_file
  else
    if [ $obj = "avgpower" ]; then 
        echo "@attribute power numeric" >> $arff_file
    else
        echo "unknown or no objective specified, defaulting to speedup"
        echo "@attribute speedup numeric" >> $arff_file
    fi
  fi
fi

i=0;
class_str="{"
while [ $i -lt ${class_cnt} ]; do
  if [ $i -lt $((${class_cnt} - 1 )) ]; then 
      class_str="${class_str}${classes[$i]},"
  else
      class_str="${class_str}${classes[$i]}"
  fi
  i=$(($i + 1))
done
class_str="${class_str}}"

# classification model
if [ $model = "logit" ]; then
    labels=`cat ${datafile}_copy | awk -F "," '{print $NF}'` 
    echo "@attribute class ${class_str}" >> $arff_file
fi

echo "@data" >> $arff_file

# add data to arff file 
cat ${datafile}_copy >> $arff_file

# if rows were deleted ...
if [ $mod -eq 1 ]; then 
	mv  ${datafile}_copy ${datafile}.reduced
fi