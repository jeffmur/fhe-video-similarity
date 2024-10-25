import glob
import pandas as pd
import matplotlib.pyplot as plt
from sklearn.model_selection import train_test_split
from sklearn.neural_network import MLPClassifier
from sklearn.model_selection import GridSearchCV
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

def _split_train_test(data: pd.DataFrame) -> dict:
    # Prepare data
    # Assume the first column is the label and the remaining columns are features
    X = data.iloc[:, 1:]  # Features (all columns except the first one)
    y = data.iloc[:, 0]   # Labels (first column)

    # Split the dataset into training (80%) and testing (20%)
    X_train, X_test, y_train, y_test = train_test_split(X, y, test_size=0.2, random_state=42)
    return {
        'X_train': X_train,
        'X_test': X_test,
        'y_train': y_train,
        'y_test': y_test,
    }

def _score_model(clf: MLPClassifier, X_test, y_test) -> dict:
    # Make predictions on the test data
    y_pred = clf.predict(X_test)

    # Get predicted probabilities
    y_pred_proba = clf.predict_proba(X_test)[:, 1]

    # Evaluate the model's performance
    accuracy = accuracy_score(y_test, y_pred)
    precision = precision_score(y_test, y_pred, average='weighted')
    recall = recall_score(y_test, y_pred, average='weighted')
    f1 = f1_score(y_test, y_pred, average='weighted')

    print(f"Accuracy: {accuracy * 100:.2f}%")
    print(f"Error: {(1 - accuracy) * 100:.2f}%")
    print(f"Precision: {precision * 100:.2f}%")
    print(f"Recall: {recall * 100:.2f}%")
    print(f"F1 Score: {f1 * 100:.2f}%")

    return {
        'y_test': y_test,
        'y_pred': y_pred,
        'y_pred_proba': y_pred_proba,
    }

def train_test_ann(data: pd.DataFrame) -> dict:
    X_train, X_test, y_train, y_test = _split_train_test(data).values()

    # Initialize and train the model
    # MLPClassifier is a simple feedforward artificial neural network (ANN)
    clf = MLPClassifier(solver='lbfgs', hidden_layer_sizes=(10, 10), activation='relu', max_iter=2500, random_state=42)
    clf.fit(X_train, y_train)

    return _score_model(clf, X_test, y_test)

# Optional: Save the model to reuse later
# from sklearn.externals import joblib
# joblib.dump(clf, 'best_model.pkl')

def grid_search_ann(data: pd.DataFrame) -> dict:
    X_train, X_test, y_train, y_test = _split_train_test(data).values()

    # MLPClassifier is a simple feedforward artificial neural network (ANN)
    clf = MLPClassifier(max_iter=1000, random_state=42)

    # Grid search
    param_grid = {
        'hidden_layer_sizes': [(10,), (50,), (100,)],
        'activation': ['identity', 'logistic', 'tanh', 'relu'],
        'solver': ['lbfgs', 'sgd', 'adam']
    }

    grid_search = GridSearchCV(clf, param_grid, cv=5, n_jobs=-1)
    grid_search.fit(X_train, y_train)

    # Print the best parameters
    print(grid_search.best_params_)

    return _score_model(grid_search, X_test, y_test)

def drawROC(LabelRecord, PredRecord, models):
    from sklearn.metrics import roc_curve, auc
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

def confusionMatrix(y_test, y_pred):
    from sklearn.metrics import confusion_matrix
    import seaborn as sns

    cm = confusion_matrix(y_test, y_pred)
    sns.heatmap(cm, annot=True, fmt='d', cmap='Blues')

    plt.xlabel('Predicted labels')
    plt.ylabel('True labels')
    plt.title('Confusion Matrix')
    plt.show()
