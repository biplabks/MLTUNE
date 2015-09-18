#! /home/b_s183/.local/bin/python

import numpy as np
from sklearn import linear_model
from sklearn import preprocessing
import pickle

import sys
import argparse

def usage():
    print ("This is usage")

def main():
    parser = argparse.ArgumentParser(description='Normalize the feature values')
    required = parser.add_argument_group('required options')

    required.add_argument('-x', '--normfeaturelist', required=True, help='File containing feature values')
    
    args = parser.parse_args()

    X = np.loadtxt(args.normfeaturelist)

    #f = open("trainlist","wb")
    min_max_scaler = preprocessing.MinMaxScaler(feature_range=(-1,1))
    X_train_minmax = min_max_scaler.fit_transform(X)
    np.savetxt('featurelist', X_train_minmax, fmt='%.2g', delimiter='\t')
    #f.close()

if __name__ == "__main__":
    main()
