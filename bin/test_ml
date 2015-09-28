#! /home/b_s183/.local/bin/python

# TODO
# get delimiter to loadtxt from user

# CAVEATS
# all training data must be numeric


import numpy as np
from sklearn import linear_model
import pickle

import sys
import argparse

def main():

    parser = argparse.ArgumentParser(description='Test a trained ML model')
    required = parser.add_argument_group('required options')

    required.add_argument('-x', '--testfile', required=True, help='File containing test instances')
    required.add_argument('-m', '--modelfile', required=True, help='File containing the trained ML model object')

    args = parser.parse_args()

    #X = np.loadtxt(args.testfile, skiprows=1)
    X = np.loadtxt(args.testfile)

    with open(args.modelfile, "rb") as infile:
        clf = pickle.load(infile)

    Y = clf.predict(X)

    print (Y)



if __name__ == "__main__":
    main()
