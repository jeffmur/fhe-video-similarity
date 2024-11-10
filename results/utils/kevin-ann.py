# This python code trained multiple Supervised learning algorithm
#  and compare their performance based on their accuracy, precision, recall, and F1
#  -- For ANN, the top 3 result from the Grid-search-ann.py is presented 

# -- It will further display graphs and tables to aid visualizing the results!





#BEST::::::::::::::::;;
# 76 :  ========================     UPDATED!!!       =======================
#  Best acc average updated. Accuracy = 92.727%
# 76 :   When parameters =  ('lbfgs', 4, 7, 'relu')


#====>>>>>>>>>>>>>>>>>>

# Best case:model 3 testSize =  0.1
# ---------------   Result:   ----------------
# f1        = 96.55172  
# accuracy  = 97.436  
# error     = 2.564  
# precision = 93.333  
# recall    = 100.000  
# MSE: 0.02564102564102564
# R^2: 0.8885714285714286
import math
import time 
import pandas as pd
from sklearn.metrics import accuracy_score,confusion_matrix
import threading
# algorithms ::::
from sklearn.naive_bayes import GaussianNB
from sklearn import svm, tree, metrics
from sklearn.neighbors import KNeighborsClassifier
from sklearn.neural_network import MLPClassifier
from sklearn.metrics import recall_score, f1_score, precision_score
import matplotlib.pyplot as plt
import numpy as np
from sklearn.metrics import roc_curve
from sklearn.model_selection import train_test_split
from sklearn.metrics import mean_squared_error
from sklearn.metrics import r2_score
from sklearn.preprocessing import StandardScaler

indoor_data = pd.read_csv('shuffle_features_data.csv', header = 0)
openspace_data = pd.read_csv('shuffle_openspace_features_data.csv', header = 0)
case3_test_data = pd.read_csv('case3_test_data.csv', header = 0)
case6_test_data = pd.read_csv('case6_test_data.csv', header = 0)
case7_train_data = pd.read_csv('case7_train_data.csv', header = 0)
case8_train_data = pd.read_csv('case8_train_data.csv', header = 0)

case9_train_data = pd.read_csv('case9_train_data.csv', header = 0)
case9_test_data = pd.read_csv('case9_test_data.csv', header = 0)


AccuracyRecord = []
PrecisionRecord = []
RecallRecord = []
FscoreRecord = []
models = []
LabelRecord = []
PredRecord = []


best_train_data = []
best_train_label = []
best_test_data = []
best_test_label = []

#=========================================================================
# K-fold cross-validation,  K is set at 10
# Runs through each fold and retrieve the best fold to train the model
# Output the accuracy, fscore, precision, recall rate 
def k_fold(algorithm, test_case):
    global PrecisionRecord, RecallRecord, FscoreRecord, models
    global best_train_data, best_train_label, best_test_data, best_test_label
    global data, openspace_data
    models.append(algorithm)
    average_accuracy = 0.0
    best_accuracy = 0.0

    recall = 0.0
    precision = 0.0
    f1 = 0.0
    print ('\n============================================')

    #Test cases:::::::::::::::::::::::::::::::::::::::::::::::::::::::
    if test_case == 1:
        print('Train with indoor, test with indoor')
        df = pd.DataFrame(indoor_data)

        testSize = 0.1
        data = df.iloc[:,1:]
        label = df.iloc[:,0]
        TotalDataSample = data.shape[0] + 1

        X_train, X_test, y_train, y_test = train_test_split(data, label, test_size = testSize, shuffle = False)
    elif test_case == 2:
        print('Train with indoor, test with outdoor')

        df = pd.DataFrame(indoor_data)
        tr_data = df.iloc[:,1:]
        tr_label = df.iloc[:,0]
        #print (tr_data)

        open_df = pd.DataFrame(openspace_data)
        te_data = open_df.iloc[:,1:]
        te_label = open_df.iloc[:,0]
        ANN_testcase_results(tr_data, tr_label, te_data, te_label )
        return
    elif test_case == 3:
        print('Train with indoor, test with both')

        df = pd.DataFrame(indoor_data)
        in_data = df.iloc[:,1:]
        TotalDataSample = in_data.shape[0] + 1

        tr_data = df.iloc[0:int(TotalDataSample*0.9),1:]
        tr_label = df.iloc[0:int(TotalDataSample*0.9),0]


        open_df = pd.DataFrame(case3_test_data)
        te_data = open_df.iloc[:,1:]
        te_label = open_df.iloc[:,0]



        ANN_testcase_results(tr_data, tr_label, te_data, te_label )
        return



    elif test_case == 4:
        print('Train with outdoor, test with outdoor')
        adf = pd.DataFrame(openspace_data)

        testSize = 0.1
        data = adf.iloc[:,1:]
        label = adf.iloc[:,0]
        TotalDataSample = data.shape[0] + 1

        X_train, X_test, y_train, y_test = train_test_split(data, label, test_size = testSize, shuffle = True)
    elif test_case == 5:
        print('Train with outdoor, test with indoor')

        df = pd.DataFrame(openspace_data)
        tr_data = df.iloc[:,1:]
        tr_label = df.iloc[:,0]
        #print (tr_data)

        open_df = pd.DataFrame(indoor_data)

        te_data = open_df.iloc[:,1:]
        te_label = open_df.iloc[:,0]
        ANN_testcase_results(tr_data, tr_label, te_data, te_label )
        return
    elif test_case == 6:
        print('Train with outdoor, test with both')
        df = pd.DataFrame(openspace_data)
        in_data = df.iloc[:,1:]
        TotalDataSample = in_data.shape[0] + 1

        tr_data = df.iloc[0:343,1:]
        tr_label = df.iloc[0:343,0]


        open_df = pd.DataFrame(case6_test_data)
        te_data = open_df.iloc[:,1:]
        te_label = open_df.iloc[:,0]
        #print(te_data)



        ANN_testcase_results(tr_data, tr_label, te_data, te_label )
        return
    elif test_case == 7:
        print('Train with both, test with indoor')
        df = pd.DataFrame(case7_train_data)
        tr_data = df.iloc[:,1:]
        tr_label = df.iloc[:,0]


        open_df = pd.DataFrame(indoor_data)
        in_data = open_df.iloc[:,1:]
        TotalDataSample = in_data.shape[0] + 1

        te_data = open_df.iloc[int(TotalDataSample*0.9):,1:]
        te_label = open_df.iloc[int(TotalDataSample*0.9):,0]



        ANN_testcase_results(tr_data, tr_label, te_data, te_label )
        return
    elif test_case == 8:
        print('Train with both, test with outdoor')
        df = pd.DataFrame(case8_train_data)
        tr_data = df.iloc[:,1:]
        tr_label = df.iloc[:,0]


        open_df = pd.DataFrame(openspace_data)
        in_data = open_df.iloc[:,1:]
        TotalDataSample = in_data.shape[0] + 1

        te_data = open_df.iloc[int(TotalDataSample*0.9):,1:]
        te_label = open_df.iloc[int(TotalDataSample*0.9):,0]



        ANN_testcase_results(tr_data, tr_label, te_data, te_label )
        return

    elif test_case == 9:
        print('Train with both, test with indoor')
        df = pd.DataFrame(case9_train_data)
        tr_data = df.iloc[:,1:]
        tr_label = df.iloc[:,0]


        open_df = pd.DataFrame(case9_test_data)

        te_data = open_df.iloc[:,1:]
        te_label = open_df.iloc[:,0]



        ANN_testcase_results(tr_data, tr_label, te_data, te_label )
        return



        







    
    data_size = int (TotalDataSample * (1 - testSize ))
    fold_size = int (data_size * 0.1)
    #print ('ALOG:::', algorithm)
    for i in range(1,11):

        start_fold = (i - 1) * fold_size

        test_data  = X_train[start_fold:start_fold + fold_size]
        train_data = X_train[0:start_fold].append( X_train[start_fold+fold_size:data_size] )

        test_label  = y_train[start_fold:start_fold+fold_size]
        train_label = y_train[0:start_fold].append(y_train[start_fold+fold_size:data_size] )



        clf = MLPClassifier(solver='lbfgs', hidden_layer_sizes=(3,13),activation='logistic')

        t = time.time()
        clf.fit(train_data,train_label)
        ft = time.time()
        pred = clf.predict(test_data)

        accuracy = accuracy_score(test_label ,pred)*100
        #print ('fold: {: 2d}  accuracy = {:.2f}  '.format(i, accuracy ))
        #print ('time: ',ft-t )
        average_accuracy += accuracy
        precision += precision_score(test_label, pred) * 100
        recall += recall_score(test_label, pred) * 100
        f1 += f1_score(test_label, pred)

        
        if accuracy > best_accuracy :
            best_accuracy = accuracy

            tLabel = test_label
            Pred = pred

            best_train_data = train_data
            best_train_label = train_label
            best_test_data = test_data
            best_test_label = test_label


    # Print out information on the results of the K-fold 
    #print ('---------------   Result:   ----------------')
    #print ('average accuracy :: {:.3f}'.format(average_accuracy/10) )
    AccuracyRecord.append(average_accuracy/10)
    #print ('average Precision:: {:.3f}'.format(precision/10))
    PrecisionRecord.append(precision/10)
    #print ('average Recall   :: {:.3f}'.format(recall/10))
    RecallRecord.append(recall/10)
    #print ('average F1       :: {:.3f}\n'.format(f1/10))
    FscoreRecord.append(f1/10)
    
    LabelRecord.append(tLabel)
    PredRecord.append(Pred)

    bestCase()




'''
    # #Graph the confusion matrix for each classifier
    cm = confusion_matrix(tLabel, Pred)
    #print(cm)
    fig = plt.figure()
    ax = fig.add_subplot(111)
    cax = ax.matshow(cm)
    plt.title('Confusion matrix of the ' + algorithm)
    fig.colorbar(cax)
    ax.set_xticklabels([''] + ['valid', 'invalid'])
    ax.set_yticklabels([''] + ['valid', 'invalid'])
    plt.xlabel('Predicted')
    plt.ylabel('True')
'''

    


#Draw the ROC curve of the classifiers
def drawROC():
    global LabelRecord, PredRecord, models
    plt.figure()
    plt.plot([0, 1], [0, 1], 'k--')
    for i in range(len(models)):
        print ('draw roc:', models[i])
        fpr, tpr, _ = roc_curve(LabelRecord[i], PredRecord[i])
        lab = '('+ str(format(metrics.auc(fpr, tpr), '.2f')) + ') '+ models[i]
        plt.plot(fpr,tpr , label = lab )

    plt.xlabel('False positive rate')
    plt.ylabel('True positive rate')
    plt.title('ROC curve')
    plt.legend(loc='best')
    


# Display information of the selected best case: model 3
def bestCase():
    global best_test_label, best_test_data, best_train_label, best_train_data


    clf = MLPClassifier(solver='lbfgs', hidden_layer_sizes=(3,13),activation='logistic')
    clf.fit(best_train_data, best_train_label)
    pred = clf.predict(best_test_data)
    
    accuracy = accuracy_score(best_test_label ,pred) * 100
    precision = precision_score(best_test_label, pred) * 100
    recall = recall_score(best_test_label, pred) * 100
    f1 = f1_score(best_test_label, pred) * 100
    print ('---------------   Result:   ----------------')
    print ('f1        = {:.5f}  '.format( f1 ))
    print ('accuracy  = {:.3f}  '.format( accuracy ))
    print ('error     = {:.3f}  '.format(100 - accuracy ))
    print ('precision = {:.3f}  '.format( precision ))
    print ('recall    = {:.3f}  '.format( recall ))



    #print ('MSE:', mean_squared_error(best_test_label, pred))
    #print ('R^2:', r2_score(best_test_label, pred))


def ANN_testcase_results(train_data, train_label, test_data, test_label):
    clf = MLPClassifier(solver='lbfgs', hidden_layer_sizes=(3,13),activation='logistic')
    clf.fit(train_data, train_label)
    pred = clf.predict(test_data)
    
    accuracy = accuracy_score(test_label ,pred) * 100
    precision = precision_score(test_label, pred) * 100
    recall = recall_score(test_label, pred) * 100
    f1 = f1_score(test_label, pred) * 100
    print ('---------------   Result:   ----------------')
    print ('f1        = {:.5f}  '.format( f1 ))
    print ('accuracy  = {:.3f}  '.format( accuracy ))
    print ('error     = {:.3f}  '.format(100 - accuracy ))
    print ('precision = {:.3f}  '.format( precision ))
    print ('recall    = {:.3f}  '.format( recall ))
        

##############################################################
#MAIN STARTS HERE
k_fold('ANN', 1)
# k_fold('ANN', 2)
# k_fold('ANN', 3)
# k_fold('ANN', 4)
# k_fold('ANN', 5)
# k_fold('ANN', 6)
# k_fold('ANN', 7)
# k_fold('ANN', 8)
# k_fold('ANN', 9)




#drawROC()
#showPrecisionRecallFscore()
