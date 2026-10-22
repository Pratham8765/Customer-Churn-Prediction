-- Views that Power BI can read (or that run_pipeline.py exports to CSV).

DROP VIEW IF EXISTS vw_customers_powerbi;
CREATE VIEW vw_customers_powerbi AS
SELECT * FROM customers;

DROP VIEW IF EXISTS vw_churn_summary;
CREATE VIEW vw_churn_summary AS
SELECT 'Contract' AS dimension, contract AS segment,
       COUNT(*) AS customers, SUM(churn_flag) AS churned,
       ROUND(100.0 * AVG(churn_flag), 1) AS churn_rate_pct
FROM customers GROUP BY contract
UNION ALL
SELECT 'Internet service', internet_service, COUNT(*), SUM(churn_flag),
       ROUND(100.0 * AVG(churn_flag), 1)
FROM customers GROUP BY internet_service
UNION ALL
SELECT 'Payment method', payment_method, COUNT(*), SUM(churn_flag),
       ROUND(100.0 * AVG(churn_flag), 1)
FROM customers GROUP BY payment_method
UNION ALL
SELECT 'Tenure band', tenure_band, COUNT(*), SUM(churn_flag),
       ROUND(100.0 * AVG(churn_flag), 1)
FROM customers GROUP BY tenure_band
UNION ALL
SELECT 'Senior citizen', senior_label, COUNT(*), SUM(churn_flag),
       ROUND(100.0 * AVG(churn_flag), 1)
FROM customers GROUP BY senior_label;
