#! /home/b_s183/.local/bin/python

import numpy as np
from sklearn import cross_validation
from sklearn import svm
import pickle
import sys
import argparse
import math
import io

def usage():
    print ("This is usage")

def main():
    parser = argparse.ArgumentParser(description='Normalize the feature values')
    required = parser.add_argument_group('required options')
    
    required.add_argument('-x','--featurelist', required=True, help='File containing feature values')
    required.add_argument('-y','--targetdata', required=True, help='File containing target data')
    required.add_argument('-z','--splitpercent', required=True, type=float, help='It will take split percentage, for example 70 means, 70% train and 30% test split')

    args = parser.parse_args()  
    X = np.loadtxt(args.featurelist)
    #Y = np.loadtxt(args.targetdata)
    Y = np.genfromtxt(args.targetdata,dtype='str')

    #print(len(X))
    #print(len(Y))	
    #To process this script we have to ensure that the number of rows of feature list,target data,training list is same
    if len(X) != len(Y): sys.exit("Length of feature list and target data does not match")
	
    #Lets say we want to split 70% training and 30% testing data
    trainList,testList,targetDataList,targetDataTestPart=cross_validation.train_test_split(X, Y, train_size=args.splitpercent, random_state=0)
    #trainSplit = args.splitpercent
    #totalRows = len(X) #total number of rows, we are using feature list as base 
    #numRowsForTraining = math.ceil((len(X)*trainSplit)/100)
    #numRowsForTesting = totalRows-numRowsForTraining #estimating for 30% testing data
    
    #split testing, training and target data
    #trainList = X[0:numRowsForTraining]
    #testList = X[numRowsForTraining:totalRows]
    #targetDataList = Y[0:numRowsForTraining]

    np.savetxt('trainlist',trainList,fmt='%.2f',delimiter='\t')
    np.savetxt('testlist',testList,fmt='%.2f',delimiter='\t')
    #np.savetxt('targetDataToTrain',targetDataList,fmt='%.2g',delimiter='\t')
    np.savetxt('targetDataToTrain',targetDataList,fmt='%s')    
    np.savetxt('targetDataTestPart',targetDataTestPart,fmt='%s')

if __name__ == "__main__":
    main()
