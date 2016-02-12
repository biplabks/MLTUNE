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

for m in *${model}.model; do 
#	invoke_weka_model.sh -m ${model} $m $datafile
	echo $m
done

