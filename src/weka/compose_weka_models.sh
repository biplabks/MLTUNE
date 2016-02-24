#!/bin/bash

if [ $# -lt 2 ]; then
  echo "usage :"
  echo "    $0 <options> test_data_file"
  echo "   OPTIONS"
  echo "      -m, --model MODEL,  model is weka model: logit, dtree"
  echo ""
  echo ""
  exit 0
fi


while [ $# -gt 0 ]; do
  key="$1"
  case $key in
      -m|--model)
        model="$2"
        shift # option has parameter
        ;;
      *)
  		if [ "$datafile" = "" ]; then
				datafile=$1
			else
				echo "Unknown option:" $key
				exit 0
			fi
      ;;
    esac
  shift # option(s) fully processed, proceed to next input argument
done

[ -r $datafile ] || { echo "could not read test data from $datafile. Exiting..."; exit 0; }
[ "${model}" ] || { model=dtree; }


i=0
for m in *${model}.model; do 
	preds[$i]=`invoke_weka_model.sh -m ${model} $m $datafile`
	i=$(($i+1))
done

j=1
while [ $j -lt $i ]; do 
	if [ ${preds[$j]} = "good" ]; then 
		echo "best: $j"
		break
	fi
	j=$(($j+1))
done

if [ $j -eq $i ]; then 
	echo "best: 0"
fi
