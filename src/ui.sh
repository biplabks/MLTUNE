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
      ./train_data_gen.sh eventlist outlist proglist -l $metric -c $clf -u automatic
	;;
   2)
      echo "Please choose from following options. "
      echo "1. Retrieve Event list"
      echo "2. Generate Target Data"
      echo "3. Normalize feature list"
      echo "4. Split feature list"
      echo "5. Train Model"
      echo "6. Test Model"
      read secOption
      
      case $secOption in
         1) likwid-perfctr -e | grep ", PMC" | awk -F ',' '{print $1}' >> alleventlist
	    echo "Please check file <alleventlist> for event lists"
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
            read fileName
            ./normalize.py -x $fileName
            echo "Please check file <featurelist> for normalized features"
            ;;
	 4)
	    echo "Please enter the filename of feature list(featurelist):"
            read fetList
            echo "Please enter the filename of target data(targetdata):"
            read tardata
            echo "Please enter the split percentage:"
            read splitper
            ./split_train_test.py -x $fetList -y $tardata -z $splitper
            echo "Please check <trainlist>,<testlist>,and <targetDataToTrain> for output"
	    ;;
         5)
	    echo "Please enter the filename of feature list(trainlist):"
	    read trainfile
            echo "Please enter the filename of targetdata(targetDataToTrain):"
	    read trdata
            ./train_ml.py -x $trainfile -y $trdata -o bin_file
            echo "Model has been deployed in bin_file" 
	    ;;
         6) 
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
