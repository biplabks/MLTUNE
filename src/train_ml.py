#! /home/b_s183/.local/bin/python

#TODO delimiter from user

# CAVEATS
# all training data must be numeric


import numpy as np
from sklearn import linear_model
from sklearn import svm
from sklearn import naive_bayes
from sklearn import tree
from sklearn import metrics
from sklearn import cross_validation
import pickle
import io

import sys
import argparse

def usage():
    print ("This is usage")

def main():
    
    parser = argparse.ArgumentParser(description='Train an ML model')
    required = parser.add_argument_group('required options')

    required.add_argument('-x', '--trainfile', required=True, help='File containing training data')
    required.add_argument('-y', '--targetfile', required=True, help='File containing target data')
    #required.add_argument('-o', '--modelfile', required=True, help='Output filename for trained model object')
    #required.add_argument('-t', '--targettype', default=int)
    
    args = parser.parse_args()

    #X = np.loadtxt(args.trainfile, skiprows=1)
    X = np.loadtxt(args.trainfile)
    #Y = np.loadtxt(args.targetfile, dtype=args.targettype)
    #Y = np.loadtxt(args.targetfile)   
    Y = np.genfromtxt(args.targetfile,dtype='str')

    assert len(X) == len(Y), "length mismatch between train and target data"

    clf1 = linear_model.LogisticRegression(penalty='l2',C=1e5,solver='newton-cg',tol=0.00001)
    clf1.fit(X, Y)
    predicted1=cross_validation.cross_val_predict(clf1,X,Y,cv=2)
    print("Prediction accuracy of logistic regression : ", metrics.accuracy_score(Y, predicted1))
    #predicted=cross_validation.cross_val_predict(clf1,x,x_tr,cv=2)
    
    clf2 = svm.SVC(C=1e5,kernel='rbf')
    clf2.fit(X, Y)
    predicted2=cross_validation.cross_val_predict(clf2,X,Y,cv=2)
    print("Prediction accuracy of SVM : ", metrics.accuracy_score(Y, predicted2))

    clf3 = naive_bayes.BernoulliNB(alpha=1.9)
    clf3.fit(X, Y)
    predicted3=cross_validation.cross_val_predict(clf3,X,Y,cv=2)
    print("Prediction accuracy of naive bayes : ", metrics.accuracy_score(Y, predicted3))

    clf4 = tree.DecisionTreeClassifier(criterion='entropy')
    clf4.fit(X, Y)
    predicted4=cross_validation.cross_val_predict(clf4,X,Y,cv=2)
    print("Prediction accuracy of decision trees : ", metrics.accuracy_score(Y, predicted4))
        
    #with open(args.modelfile, "wb") as outfile:
    #    pickle.dump(clf1, outfile, pickle.HIGHEST_PROTOCOL)
    
    with open('bin_file_lr',"wb") as outfile1:
         pickle.dump(clf1, outfile1, pickle.HIGHEST_PROTOCOL)

    with open('bin_file_svm',"wb") as outfile2:
         pickle.dump(clf2, outfile2, pickle.HIGHEST_PROTOCOL)

    with open('bin_file_bayes',"wb") as outfile3:
         pickle.dump(clf3, outfile3, pickle.HIGHEST_PROTOCOL)

    with open('bin_file_dtree',"wb") as outfile4:
         pickle.dump(clf4, outfile4, pickle.HIGHEST_PROTOCOL)

if __name__ == "__main__":
    main()
