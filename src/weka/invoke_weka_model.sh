#!/bin/bash

if [ $# -lt 2 ]; then
  echo "usage :"
  echo "    $0 <options> model_file test_data_file"
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
			if  [ "$modelfile" = "" ]; then 
				modelfile=$1
  		elif [ "$datafile" = "" ]; then
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
[ -r $modelfile ] || { echo "could not locate model file $datafile. Exiting..."; exit 0; }

[ "${model}" ] || { model=dtree; }

case ${model} in
    logit)
        weka_model="weka.classifiers.functions.Logistic"
        ;;
    dtree)
        weka_model="weka.classifiers.trees.J48"
        ;;
    m5p)
        weka_model="weka.classifiers.trees.M5P"
        ;;
    regr)
        weka_model="weka.classifiers.functions.LinearRegression"
        ;;
    ibk)
        weka_model="weka.classifiers.lazy.IBk"
        ;;
    svm) 
		   weka_model="weka.classifiers.functions.SMO"
			  ;;
	  bayes) 
		 weka_model="weka.classifiers.bayes.NaiveBayes"
		   ;;
	   *)
        echo "Unknown model: $model. Swithing to default: logit"
        ;;
esac

#java ${weka_model} -l ${modelfile} -T ${datafile} -p 0 | grep predicted -A 1 | tail -1 | awk '{print $3}' | awk -F ":" '{print $2}'

java ${weka_model} -l ${modelfile} -T ${datafile} -p 0 



