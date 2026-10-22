-- Data quality checks on the raw table (run before cleaning).
-- Each query starts with a "-- name:" line so run_pipeline.py can run and label it.

-- name: dq_row_counts
SELECT COUNT(*) AS raw_rows,
       COUNT(DISTINCT customerID) AS distinct_customers
FROM raw_customers;

-- name: dq_duplicate_ids
SELECT customerID, COUNT(*) AS n
FROM raw_customers
GROUP BY customerID
HAVING COUNT(*) > 1;

-- name: dq_blank_total_charges
SELECT COUNT(*) AS blank_total_charges,
       MIN(CAST(tenure AS INTEGER)) AS min_tenure_of_blank_rows,
       MAX(CAST(tenure AS INTEGER)) AS max_tenure_of_blank_rows
FROM raw_customers
WHERE TRIM(TotalCharges) = '';

-- name: dq_churn_values
SELECT Churn, COUNT(*) AS customers
FROM raw_customers
GROUP BY Churn;
