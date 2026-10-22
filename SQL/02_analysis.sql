-- Business analysis queries. Results are printed and saved to results/<name>.csv.
-- Includes GROUP BY, CASE, CTEs and window functions (RANK, running SUM).

-- name: q01_overall
SELECT COUNT(*)                                   AS customers,
       SUM(churn_flag)                            AS churned,
       ROUND(100.0 * AVG(churn_flag), 1)          AS churn_rate_pct,
       ROUND(AVG(monthly_charges), 2)             AS avg_monthly_charges,
       ROUND(SUM(CASE WHEN churn_flag = 1 THEN monthly_charges ELSE 0 END), 2)
                                                  AS monthly_revenue_lost
FROM customers;

-- name: q02_churn_by_contract
SELECT contract,
       COUNT(*)                                   AS customers,
       SUM(churn_flag)                            AS churned,
       ROUND(100.0 * AVG(churn_flag), 1)          AS churn_rate_pct,
       ROUND(AVG(monthly_charges), 2)             AS avg_monthly_charges
FROM customers
GROUP BY contract
ORDER BY churn_rate_pct DESC;

-- name: q03_churn_by_tenure_band
SELECT tenure_band,
       COUNT(*)                                   AS customers,
       SUM(churn_flag)                            AS churned,
       ROUND(100.0 * AVG(churn_flag), 1)          AS churn_rate_pct
FROM customers
GROUP BY tenure_band, tenure_band_order
ORDER BY tenure_band_order;

-- name: q04_churn_by_internet_service
SELECT internet_service,
       COUNT(*)                                   AS customers,
       SUM(churn_flag)                            AS churned,
       ROUND(100.0 * AVG(churn_flag), 1)          AS churn_rate_pct,
       ROUND(AVG(monthly_charges), 2)             AS avg_monthly_charges
FROM customers
GROUP BY internet_service
ORDER BY churn_rate_pct DESC;

-- name: q05_churn_by_payment_method
SELECT payment_method,
       COUNT(*)                                   AS customers,
       SUM(churn_flag)                            AS churned,
       ROUND(100.0 * AVG(churn_flag), 1)          AS churn_rate_pct
FROM customers
GROUP BY payment_method
ORDER BY churn_rate_pct DESC;

-- name: q06_churn_by_addon_services
-- Customers with internet only; number of add-on services (security, backup, protection, support, streaming).
SELECT num_addon_services,
       COUNT(*)                                   AS customers,
       ROUND(100.0 * AVG(churn_flag), 1)          AS churn_rate_pct
FROM customers
WHERE has_internet = 1
GROUP BY num_addon_services
ORDER BY num_addon_services;

-- name: q07_high_risk_segment
-- CTE: compare a candidate high-risk profile against everyone else.
WITH seg AS (
    SELECT CASE
               WHEN contract = 'Month-to-month'
                AND internet_service = 'Fiber optic'
                AND tenure_months <= 12
               THEN 'Month-to-month + Fiber + first year'
               ELSE 'Everyone else'
           END AS segment,
           churn_flag,
           monthly_charges
    FROM customers
)
SELECT segment,
       COUNT(*)                                   AS customers,
       SUM(churn_flag)                            AS churned,
       ROUND(100.0 * AVG(churn_flag), 1)          AS churn_rate_pct,
       ROUND(SUM(CASE WHEN churn_flag = 1 THEN monthly_charges ELSE 0 END), 2)
                                                  AS monthly_revenue_lost
FROM seg
GROUP BY segment
ORDER BY churn_rate_pct DESC;

-- name: q08_payment_rank_within_contract
-- Window function: rank payment methods by churn rate inside each contract type.
WITH rates AS (
    SELECT contract,
           payment_method,
           COUNT(*)                               AS customers,
           ROUND(100.0 * AVG(churn_flag), 1)      AS churn_rate_pct
    FROM customers
    GROUP BY contract, payment_method
)
SELECT contract,
       payment_method,
       customers,
       churn_rate_pct,
       RANK() OVER (PARTITION BY contract ORDER BY churn_rate_pct DESC) AS rank_in_contract
FROM rates
ORDER BY contract, rank_in_contract;

-- name: q09_cumulative_churn_by_tenure
-- Window function: running total of churned customers by tenure month.
WITH by_tenure AS (
    SELECT tenure_months,
           COUNT(*)        AS customers,
           SUM(churn_flag) AS churned
    FROM customers
    GROUP BY tenure_months
)
SELECT tenure_months,
       customers,
       churned,
       SUM(churned) OVER (ORDER BY tenure_months)                         AS cumulative_churned,
       ROUND(100.0 * SUM(churned) OVER (ORDER BY tenure_months)
                   / SUM(churned) OVER (), 1)                             AS cumulative_share_of_churn_pct
FROM by_tenure
ORDER BY tenure_months;

-- name: q10_revenue_lost_by_contract
-- Window function over an aggregate: each contract's share of lost monthly revenue.
SELECT contract,
       ROUND(SUM(CASE WHEN churn_flag = 1 THEN monthly_charges ELSE 0 END), 2) AS monthly_revenue_lost,
       ROUND(100.0 * SUM(CASE WHEN churn_flag = 1 THEN monthly_charges ELSE 0 END)
                   / SUM(SUM(CASE WHEN churn_flag = 1 THEN monthly_charges ELSE 0 END)) OVER (), 1)
                                                                              AS share_of_lost_revenue_pct
FROM customers
GROUP BY contract
ORDER BY monthly_revenue_lost DESC;

-- name: q11_churn_by_demographics
SELECT 'Senior citizen' AS dimension, senior_label AS segment,
       COUNT(*) AS customers, ROUND(100.0 * AVG(churn_flag), 1) AS churn_rate_pct
FROM customers GROUP BY senior_label
UNION ALL
SELECT 'Partner', partner, COUNT(*), ROUND(100.0 * AVG(churn_flag), 1)
FROM customers GROUP BY partner
UNION ALL
SELECT 'Dependents', dependents, COUNT(*), ROUND(100.0 * AVG(churn_flag), 1)
FROM customers GROUP BY dependents
UNION ALL
SELECT 'Paperless billing', paperless_billing, COUNT(*), ROUND(100.0 * AVG(churn_flag), 1)
FROM customers GROUP BY paperless_billing;
