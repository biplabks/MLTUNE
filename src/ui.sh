#! /bin/bash

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
      ./retevents.sh      
      
      #generate training data, normalize, scaling, split and train model
      ./train_data_gen.sh eventlist outlist proglist -l $metric -c $clf -u automatic
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
	    ./retevents.sh
	    echo "Please check file <eventlist> for event lists"
	    ;;
	 2) 
	    echo "Please enter metric(power/energy/exec):"
            read metric
            echo "Please enter classification(bin/mult):"
            read clf
            ./train_data_gen.sh eventlist outlist proglist -l $metric -c $clf -u manual
	    echo "Please check file <targetdata>"
	    ;;
         3)
	    echo "Please enter the filename of unnormalized featurelist(outlist):"
            read fileName1
	    echo "Please enter the filename of program exec time list(execlist):"
	    read fileName2
            ./normalize.py -x $fileName1 -y $fileName2
            echo "Please check file <normfeaturelist> for normalized features"
            ;;
         4)
            echo "Please enter the filename of normalized feature(normfeaturelist):"
	    read fileName
	    ./scale.py -x $fileName
	    echo "Please check file <scaledfeaturelist> for scaled features"
	    ;;
         5)
	    echo "Please enter the filename of scaled feature list(scaledfeaturelist):"
	    read fileName1
	    echo "Please enter the filename of target data(targetdata):"
            read fileName2

            ./featureselection.py -x $fileName1 -y $fileName2
            echo "Please check file <featurelist> for final feature list"
	    ;;
	 6)
	    echo "Please enter the filename of feature list(featurelist):"
            read fetList
            echo "Please enter the filename of target data(targetdata):"
            read tardata
            echo "Please enter the split percentage:"
            read splitper
            ./split_train_test.py -x $fetList -y $tardata -z $splitper
            echo "Please check <trainlist>,<testlist>,and <targetDataToTrain> for output"
	    ;;
         7)
	    echo "Please enter the filename of feature list(trainlist):"
	    read trainfile
            echo "Please enter the filename of targetdata(targetDataToTrain):"
	    read trdata
            ./train_ml.py -x $trainfile -y $trdata -o bin_file
            echo "Model has been deployed in bin_file" 
	    ;;
         8) 
	    echo "Please enter the filename of test data(testlist):"
            read tlist
            ./test_ml.py -x $tlist -m bin_file
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
