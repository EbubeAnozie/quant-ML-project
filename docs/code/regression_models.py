import pandas as pd
import numpy as np
import json
from sklearn.linear_model import LinearRegression, LogisticRegression
from sklearn.preprocessing import OneHotEncoder
from sklearn.compose import ColumnTransformer
from sklearn.pipeline import Pipeline
from sklearn.metrics import root_mean_squared_error, r2_score, confusion_matrix, accuracy_score

TRAIN_PATH = "data/clean/train_regression.csv"
TEST_PATH  = "data/clean/test_regression.csv"
NUM = ["Debt_to_Equity", "Profit_Margin", "log_Assets"]
CAT = ["sector"]

def make_pre():
    return ColumnTransformer([
        ("num", "passthrough", NUM),
        ("cat", OneHotEncoder(handle_unknown="ignore"), CAT),
    ])

def main():
    train = pd.read_csv(TRAIN_PATH)
    test  = pd.read_csv(TEST_PATH)
    pre = make_pre()

    lin = Pipeline([("pre", pre), ("m", LinearRegression())]).fit(train[NUM+CAT], train["ROA"])
    pred_lin = lin.predict(test[NUM+CAT])
    rmse = root_mean_squared_error(test["ROA"], pred_lin)
    r2   = r2_score(test["ROA"], pred_lin)

    log = Pipeline([("pre", pre), ("m", LogisticRegression(max_iter=1000))]).fit(train[NUM+CAT], train["HighROA"])
    pred_log = log.predict(test[NUM+CAT])
    acc = accuracy_score(test["HighROA"], pred_log)
    cm  = confusion_matrix(test["HighROA"], pred_log)

    names = NUM + list(lin.named_steps["pre"].named_transformers_["cat"].get_feature_names_out(CAT))
    coefs_lin = dict(zip(names, lin.named_steps["m"].coef_))
    coefs_log = dict(zip(names, log.named_steps["m"].coef_[0]))

    print(f"Linear   RMSE = {rmse:.4f}   R2 = {r2:.4f}")
    print(f"Logistic accuracy = {acc:.4f}")
    print("Confusion matrix:\n", cm)
    print("Linear coefficients:",   json.dumps({k: round(v,4) for k,v in coefs_lin.items()}, indent=2))
    print("Logistic coefficients:", json.dumps({k: round(v,4) for k,v in coefs_log.items()}, indent=2))

if __name__ == "__main__":
    main()