#! /home/b_s183/.local/bin/python

import numpy as np
from sklearn import linear_model
from sklearn import preprocessing
from sklearn.feature_selection import VarianceThreshold
import pickle

import sys
import argparse

def usage():
    print ("This is usage")

def main():
    parser = argparse.ArgumentParser(description='Normalize the feature values')
    required = parser.add_argument_group('required options')

    required.add_argument('-x', '--outlist', required=True, help='File containing feature values')
    required.add_argument('-y', '--execlist', required=True, help='File containing exec list')
    
    args = parser.parse_args()

    X = np.loadtxt(args.outlist, skiprows=1)
    Y = np.loadtxt(args.execlist, ndmin=2)

    #f = open("trainlist","wb")
    newResult = X/Y
    sel = VarianceThreshold(threshold=(.8*(1-.8)))
    result = sel.fit_transform(newResult)
    np.savetxt('normfeaturelist', result, fmt='%.2f', delimiter='\t')
    #f.close()

if __name__ == "__main__":
    main()
