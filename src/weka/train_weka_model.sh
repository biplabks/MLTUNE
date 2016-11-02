#!/bin/bash

if [ $# -lt 1 ]; then
  echo "usage :"
  echo "    $0 <options> train_data_file"
  echo ""
  echo "   OPTIONS"
  echo "      -m, --model MODEL,  model is weka model: logit, dtree"
  echo "      -f, --fold NUM, cross validation fold"
  echo "      -o, --output  FILENAME, name of model file" 
  echo ""
  exit 0
fi

while [ $# -gt 0 ]; do
  key="$1"
  case $key in
      -f|--fold)
        folds="$2"
        shift # option has parameter
        ;;
      -m|--model)
        model="$2"
        shift # option has parameter
        ;;
      -o|--output)
        outfile="$2"  
        shift
        ;;
      *)
        # unknown option
        if [ "$datafile" = "" ]; then
            datafile=$1
        else
            echo Unknown option: $key
            exit 0
        fi
        ;;
    esac
  shift # option(s) fully processed, proceed to next input argument
done

[ -r $datafile ] || { echo "could not read training data from $datafile. Exiting..."; exit 0; }

dfilename=`echo $datafile | awk -F "." '{print $1}'`

[ "${model}" ] || { model=logit; }
[ "${outfile}" ] || { outfile=${dfilename}_${model}; }
[ "${folds}" ] || { folds=10; }

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

java ${weka_model} -U -d ${outfile} -x ${folds} -t ${datafile} 



