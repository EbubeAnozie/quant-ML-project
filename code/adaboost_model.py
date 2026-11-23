import pandas as pd
import numpy as np
from sklearn.model_selection import train_test_split
from sklearn.compose import ColumnTransformer
from sklearn.preprocessing import OneHotEncoder
from sklearn.pipeline import Pipeline
from sklearn.ensemble import AdaBoostClassifier
from sklearn.tree import DecisionTreeClassifier
from sklearn.metrics import confusion_matrix, accuracy_score

TRAIN_PATH = "data/clean/train_adaboost.csv"
TEST_PATH  = "data/clean/test_adaboost.csv"
NUM = ["Debt_to_Equity", "Profit_Margin", "log_Assets"]
CAT = ["sector"]

def make_pre():
    return ColumnTransformer([
        ("num", "passthrough", NUM),
        ("cat", OneHotEncoder(handle_unknown="ignore"), CAT),
    ])

def make_ada(pre, n, lr):
    return Pipeline([
        ("pre", pre),
        ("m", AdaBoostClassifier(
            estimator=DecisionTreeClassifier(max_depth=1),
            n_estimators=n, learning_rate=lr, random_state=42)),
    ])

def main():
    train = pd.read_csv(TRAIN_PATH)
    test  = pd.read_csv(TEST_PATH)
    pre = make_pre()

    tr, val = train_test_split(train, test_size=0.25, random_state=1,
                               stratify=train["HighROA"])
    rounds = [10, 25, 50, 100, 200, 400]
    accs = {lr: [] for lr in [0.1, 0.5, 1.0]}
    for lr in accs:
        for n in rounds:
            m = make_ada(pre, n, lr).fit(tr[NUM+CAT], tr["HighROA"])
            accs[lr].append(accuracy_score(val["HighROA"], m.predict(val[NUM+CAT])))

    best = max(((lr, n) for lr in accs for n in rounds),
               key=lambda t: accs[t[0]][rounds.index(t[1])])
    print("best (learning_rate, n_estimators) =", best)

    final = make_ada(pre, best[1], best[0]).fit(train[NUM+CAT], train["HighROA"])
    pred = final.predict(test[NUM+CAT])
    cm = confusion_matrix(test["HighROA"], pred)
    acc = accuracy_score(test["HighROA"], pred)
    print("AdaBoost test accuracy =", round(acc, 4))
    print("Confusion matrix:\n", cm)

if __name__ == "__main__":
    main()