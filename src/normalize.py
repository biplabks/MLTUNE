#! /home/b_s183/.local/bin/python

import numpy as np
from sklearn import linear_model
from sklearn import preprocessing
from sklearn.feature_selection import VarianceThreshold
import pickle

import sys
import os
import argparse

def usage():
    print ("This is usage")

def main():
    parser = argparse.ArgumentParser(description='Normalize the feature values')
    required = parser.add_argument_group('required options')

    required.add_argument('-x', '--outlist', required=True, help='File containing feature values')
    required.add_argument('-y', '--execlist', required=True, help='File containing exec list')
    
    args = parser.parse_args()

    #X = np.loadtxt(args.outlist, skiprows=1)
    np.set_printoptions(precision=2)
    X = np.genfromtxt(args.outlist, skiprows=1)
    X=np.nan_to_num(X)
    Y = np.loadtxt(args.execlist, ndmin=2)

    #f = open("trainlist","wb")
    #newResult = X/Y
    #sel = VarianceThreshold(threshold=(.8*(1-.8)))
    sel = VarianceThreshold(threshold=(.8*(1-.8)))
    result1 = sel.fit_transform(X)
    newResult = result1/Y
    #result2 = sel.fit_transform(newResult)

    #feature collection for test programs
    if os.path.isfile('eventlist'):
       features = np.genfromtxt('eventlist',dtype='str')
       featureFromVariance = sel.get_support(indices=True)
       text_file = open("variancefeatures.txt","w")
       for i in featureFromVariance:
           text_file.write(features[i])
           text_file.write("\n")
       text_file.close()

    np.savetxt('normfeaturelist', newResult, fmt='%.2f', delimiter='\t')
    #f.close()

if __name__ == "__main__":
    main()
