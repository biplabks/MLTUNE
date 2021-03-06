#! /bin/bash

[ `which train_ml` ] || { echo "MLTUNE not installed. Exiting...."; exit 1; }
[ `which test_ml` ] || { echo "MLTUNE not installed. Exiting...."; exit 1; } 

echo "*****Welcome to MLTUNE tool*****"
echo "WARNING: The wrong input may lead to error and wrong output"
echo ""

while :
do
echo "Please choose from following option. "
echo "1. Automatic Model Training"
echo "2. Manual Model Training"
echo "3. QUIT!!"
read option

case $option in
   1) 
      echo "Please enter metric(power/energy/exec):"
      read metric
      echo "Please enter classification(bin/mult):"
      read clf
      #retrieve event list
      retevents.sh      
      numberOfEvents=`wc -l eventlist | awk '{print $1}'`
      echo $numberOfEvents "Events have been extracted from this machine"
      echo "Please check file <eventlist> for event lists"      
      
      #generate training data, normalize, scaling, split and train model
      automated.sh $metric $clf
      #train_data_gen.sh eventlist outlist proglist -l $metric -c $clf -u automatic
	;;
   2)
      echo "Please choose from following options. "
      echo "1. Retrieve Event list"
      echo "2. Generate Target Data"
      echo "3. Normalize feature list"
      echo "4. Scale Feature list"
      echo "5. Feature selection"
      echo "6. Split feature list"
      echo "7. Train Model"
      echo "8. Test Model"
      read secOption
      
      case $secOption in
         1) 
	    retevents.sh
            numberOfEvents=`wc -l eventlist | awk '{print $1}'`
	    echo $numberOfEvents "Events have been extracted from this machine"
	    echo "Please check file <eventlist> for event lists"
	    ;;
	 2) 
	    echo "Please enter metric(power/energy/exec):"
            read metric
            echo "Please enter classification(bin/mult):"
            read clf
            train_data_gen.sh eventlist outlist proglist -l $metric -c $clf
	    echo "Please check file <targetdata> for classified target data"
	    ;;
         3)
	    echo "Please enter the filename of unnormalized featurelist(outlist):"
            read fileName1
	    echo "Please enter the filename of program exec time list(execlist):"
	    read fileName2
            normalize.py -x $fileName1 -y $fileName2
            echo "Please check file <normfeaturelist> for normalized features"
            ;;
         4)
            echo "Please enter the filename of normalized feature(normfeaturelist):"
	    read fileName
	    scale.py -x $fileName
	    echo "Please check file <scaledfeaturelist> for scaled features"
	    ;;
         5)
	    echo "Please enter the filename of scaled feature list(scaledfeaturelist):"
	    read fileName1
	    echo "Please enter the filename of target data(targetdata):"
            read fileName2
            echo "Please enter the percentage to select highest features(0-100):"
            read fetpercent

            featureselection.py -x $fileName1 -y $fileName2 -z $fetpercent
            echo "Please check file <featurelist> for final feature list"
	    ;;
	 6)
	    echo "Please enter the filename of feature list(featurelist):"
            read fetList
            echo "Please enter the filename of target data(targetdata):"
            read tardata
            echo "Please enter the split percentage(0-1):"
            read splitper
            split_train_test.py -x $fetList -y $tardata -z $splitper
            echo "Please check <trainlist>,<testlist>,and <targetDataToTrain> for splitted information"
	    ;;
         7)
	    echo "Please enter the filename of feature list(trainlist/featurelist):"
	    read trainfile
            echo "Please enter the filename of targetdata(targetDataToTrain/targetdata):"
	    read trdata
            #train_ml.py -x $trainfile -y $trdata -o bin_file
#            train_ml.py -x $trainfile -y $trdata
            train_ml -x $trainfile -y $trdata
            echo "Model has been deployed in bin_file_*" 
	    ;;
         8) 
	    echo "Please enter the filename of test data(testlist):"
            read tlist
            echo "Please choose which model you want to test:"
            echo "1. Logistic Regression"
            echo "2. SVM"
            echo "3. Naive Bayes"
            echo "4. Decision Trees"
            read modelOption
            case $modelOption in
            1)
              test_ml.py -x $tlist -m bin_file_lr 
              ;;
            2)
              test_ml.py -x $tlist -m bin_file_svm
              ;;
            3)
              test_ml.py -x $tlist -m bin_file_bayes
              ;;
            4)
              test_ml.py -x $tlist -m bin_file_dtree
              ;;
            *) echo "Invalid choice!!";;
            esac
            ;;
	 *) echo "Invalid Choice!!";; 
      esac      
	;; 
   3) 
      echo "Thanks for using MLTUNE"
      exit;;
   *) echo "Invalid Choice!!";;
esac
done
