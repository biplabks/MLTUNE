#! /bin/bash

metric=$1
classification=$2

#echo $metric
#echo $classification

train_data_gen.sh eventlist outlist proglist -l $metric -c $classification

echo "Please check file <targetdata> for classified target data"

#normalize outlist
normalize.py -x outlist -y execlist
echo "Please check file <normfeaturelist> for normalized features"

#scale the normalized featurelist
scale.py -x normfeaturelist
echo "Please check file <scaledfeaturelist> for scale features"

#feature selection
featureselection.py -x scaledfeaturelist -y targetdata -z 80
echo "Please check file <featurelist> for final feature list"

#split featurelist(normalized outlist) to trainlist and testlist, and targetdata to targetDataToTrain(By default split is 70(train)-30(test))
#split_train_test.py -x featurelist -y targetdata -z 70
#echo "Please check <trainlist>,<testlist>,and <targetDataToTrain> for splitted information"

#train the model
#train_ml.py -x trainlist -y targetDataToTrain
train_ml.py -x featurelist -y targetdata
echo "Model has been deployed in bin_file*"

