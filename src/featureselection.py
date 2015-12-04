#! /home/b_s183/.local/bin/python

import numpy as np
from sklearn.feature_selection import SelectKBest,chi2,SelectPercentile,f_classif
import pickle

import sys
import argparse

def usage():
    print("This is usage")

def main():
    parser = argparse.ArgumentParser(description='Feature Selection') 
    required = parser.add_argument_group('required options') 
    
    required.add_argument('-x', '--scaledfeaturelist', required=True, help='File containing feature values') 
    required.add_argument('-y', '--targetdata', required=True, help='File containiing target data')
    required.add_argument('-z', '--fetpercentile', required=True, type=int, help='Percentile to select highest scoring percentage of features')
    
    args = parser.parse_args()

    X = np.loadtxt(args.scaledfeaturelist) 
    Y = np.genfromtxt(args.targetdata,dtype='str')
    #sel = VarianceThreshold(threshold=(.8 * (1 - .8)))
    #result = sel.fit_transform(X)
    result = SelectPercentile(f_classif, percentile=args.fetpercentile).fit_transform(X,Y)
    
    np.savetxt('featurelist', result, fmt='%.2f', delimiter='\t')

if __name__ == "__main__":
    main()
