import glob
import pandas as pd
from sklearn.model_selection import train_test_split
from sklearn.neural_network import MLPClassifier
from sklearn.metrics import accuracy_score, precision_score, recall_score, f1_score

def csv_to_df(file: str) -> pd.DataFrame:
    return pd.read_csv(file)

def dir_to_df(directory: str) -> pd.DataFrame:
    # 1. Load dataset
    all_files = glob.glob(directory + "/*.csv")

    dfs = []
    for filename in all_files:
        df = pd.read_csv(filename, index_col=None, header=0)
        dfs.append(df)

    return pd.concat(dfs, axis=0, ignore_index=True)

def train_test_ann(data: pd.DataFrame):
    # 2. Prepare data
    # Assume the first column is the label and the remaining columns are features
    X = data.iloc[:, 1:]  # Features (all columns except the first one)
    y = data.iloc[:, 0]   # Labels (first column)

    # 3. Split the dataset into training (80%) and testing (20%)
    X_train, X_test, y_train, y_test = train_test_split(X, y, test_size=0.2, random_state=42)

    # 4. Initialize and train the model
    # MLPClassifier is a simple feedforward artificial neural network (ANN)
    clf = MLPClassifier(solver='lbfgs', hidden_layer_sizes=(10, 10), activation='relu', max_iter=1000, random_state=42)
    clf.fit(X_train, y_train)

    # 5. Make predictions on the test data
    y_pred = clf.predict(X_test)

    # 6. Evaluate the model's performance
    accuracy = accuracy_score(y_test, y_pred)
    precision = precision_score(y_test, y_pred, average='weighted')
    recall = recall_score(y_test, y_pred, average='weighted')
    f1 = f1_score(y_test, y_pred, average='weighted')

    # 7. Print out the results
    print(f"Accuracy: {accuracy * 100:.2f}%")
    print(f"Error: {(1 - accuracy) * 100:.2f}%")
    print(f"Precision: {precision * 100:.2f}%")
    print(f"Recall: {recall * 100:.2f}%")
    print(f"F1 Score: {f1 * 100:.2f}%")

# Optional: Save the model to reuse later
# from sklearn.externals import joblib
# joblib.dump(clf, 'best_model.pkl')

import matplotlib.pyplot as plt
from sklearn.metrics import roc_curve, auc

def drawROC(LabelRecord, PredRecord, models):
    plt.figure()
    plt.plot([0, 1], [0, 1], 'k--')  # Diagonal line

    for i in range(len(models)):
        fpr, tpr, _ = roc_curve(LabelRecord[i], PredRecord[i])
        roc_auc = auc(fpr, tpr)
        lab = f'({roc_auc:.2f}) {models[i]}'
        plt.plot(fpr, tpr, label=lab)

    plt.xlabel('False Positive Rate')
    plt.ylabel('True Positive Rate')
    plt.title('ROC Curve')
    plt.legend(loc='best')
    plt.grid(True)  # Add grid
    plt.xlim([0.0, 1.0])  # Set x-axis limits
    plt.ylim([0.0, 1.0])  # Set y-axis limits
    plt.show()  # Show the plot
