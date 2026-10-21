# Telco Customer Churn Prediction

Predicts which telecom customers are likely to leave, using scikit-learn pipelines and stratified cross-validation, and shows which factors drive churn.

## Data
- Telco Customer Churn data (7,043 customers, 21 columns, target `Churn`), provided with the Intellipaat Data Science course capstone project
- 26.5% of customers churned, so always predicting "stay" gives 73.5% accuracy (the baseline to beat)
- Not included in this repo. Place `customer_churn.csv` in the same folder as the notebook to run it.
  
## Approach
1. Cleaned `TotalCharges` (11 blanks for new customers) and dropped `customerID`
2. 80/20 stratified train/test split (seed 42)
3. Scaling and one-hot encoding inside a pipeline, fitted on training data only (no leakage)
4. Compared 4 models with stratified 5-fold CV on the training data
5. Evaluated the best model once on the held-out test set

## Results
5-fold cross-validation (training data):

| Model | Accuracy | Precision | Recall | F1 | ROC-AUC |
|---|---|---|---|---|---|
| Majority baseline | 0.735 | 0.000 | 0.000 | 0.000 | 0.500 |
| Logistic Regression | 0.749 | 0.517 | 0.801 | 0.629 | 0.846 |
| Decision Tree | 0.742 | 0.510 | 0.777 | 0.615 | 0.827 |
| Random Forest | 0.775 | 0.559 | 0.724 | 0.631 | 0.845 |

Test set (1,409 customers), Random Forest: accuracy 0.771, churn precision 0.55, **recall 0.74**, **F1 0.63**, **ROC-AUC 0.842**.
It caught 276 of 374 churners, with 225 false alarms and 98 missed.

![Confusion matrix](images/confusion_matrix.png)

![ROC curve](images/roc_curve.png)

**Cutoff trade-off:** at 0.5 the model flags 501 customers (recall 0.74); at 0.4 it flags 599 (recall 0.82, same F1 0.63).

**Lift:** the riskiest 10% of customers hold 29% of all churners (2.9x), and the riskiest 20% hold 50% (2.5x).

**Main drivers** (permutation importance):

![Feature importance](images/feature_importance.png)

**Tuning:** randomized search improved cross-validated F1 only from 0.631 to 0.637, so the default settings were already good.

## Conclusions
- Contract type is the strongest churn driver, followed by internet service and tenure.
- A retention team can reach about half of all churners by contacting the riskiest 20% of customers.
- The three models perform about the same, so a simple, explainable model like logistic regression is a reasonable choice.

## Limitations
- One public dataset; results may not transfer to other companies.
- No time dimension: the model uses a snapshot of each customer.
- Patterns are descriptive, not proof of cause.

## How to run
```bash
pip install -r requirements.txt
jupyter notebook Telco_Customer_Churn.ipynb
```
Put `customer_churn.csv` in the same folder as the notebook.

## Tech stack
Python, Pandas, NumPy, Scikit-Learn, Matplotlib
