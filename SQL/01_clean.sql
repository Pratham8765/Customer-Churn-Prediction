-- Build the cleaned, typed table with derived features used for analysis and Power BI.
-- Raw columns are loaded as text, so every cast is explicit here.

DROP TABLE IF EXISTS customers;

CREATE TABLE customers AS
SELECT
    customerID                                   AS customer_id,
    gender,
    CAST(SeniorCitizen AS INTEGER)               AS senior_citizen,
    CASE WHEN SeniorCitizen = '1' THEN 'Senior' ELSE 'Non-senior' END AS senior_label,
    Partner                                      AS partner,
    Dependents                                   AS dependents,
    CAST(tenure AS INTEGER)                      AS tenure_months,
    CASE
        WHEN CAST(tenure AS INTEGER) <= 12 THEN '0-12 months'
        WHEN CAST(tenure AS INTEGER) <= 24 THEN '13-24 months'
        WHEN CAST(tenure AS INTEGER) <= 48 THEN '25-48 months'
        ELSE '49-72 months'
    END                                          AS tenure_band,
    CASE
        WHEN CAST(tenure AS INTEGER) <= 12 THEN 1
        WHEN CAST(tenure AS INTEGER) <= 24 THEN 2
        WHEN CAST(tenure AS INTEGER) <= 48 THEN 3
        ELSE 4
    END                                          AS tenure_band_order,
    PhoneService                                 AS phone_service,
    MultipleLines                                AS multiple_lines,
    InternetService                              AS internet_service,
    CASE WHEN InternetService = 'No' THEN 0 ELSE 1 END AS has_internet,
    OnlineSecurity                               AS online_security,
    OnlineBackup                                 AS online_backup,
    DeviceProtection                             AS device_protection,
    TechSupport                                  AS tech_support,
    StreamingTV                                  AS streaming_tv,
    StreamingMovies                              AS streaming_movies,
    ( (OnlineSecurity = 'Yes') + (OnlineBackup = 'Yes') + (DeviceProtection = 'Yes')
    + (TechSupport = 'Yes') + (StreamingTV = 'Yes') + (StreamingMovies = 'Yes') )
                                                 AS num_addon_services,
    Contract                                     AS contract,
    PaperlessBilling                             AS paperless_billing,
    PaymentMethod                                AS payment_method,
    CAST(MonthlyCharges AS REAL)                 AS monthly_charges,
    CASE
        WHEN CAST(MonthlyCharges AS REAL) < 35 THEN 'Low (<35)'
        WHEN CAST(MonthlyCharges AS REAL) < 70 THEN 'Medium (35-70)'
        ELSE 'High (70+)'
    END                                          AS monthly_charge_band,
    -- 11 rows in the Telco data have a blank TotalCharges; they are customers with tenure 0,
    -- so 0 is a reasonable fill. Check dq_blank_total_charges to confirm on your copy.
    CASE WHEN TRIM(TotalCharges) = '' THEN 0.0 ELSE CAST(TotalCharges AS REAL) END
                                                 AS total_charges,
    Churn                                        AS churn_label,
    CASE WHEN Churn = 'Yes' THEN 1 ELSE 0 END    AS churn_flag
FROM raw_customers;

CREATE INDEX IF NOT EXISTS idx_customers_contract ON customers(contract);
CREATE INDEX IF NOT EXISTS idx_customers_tenure   ON customers(tenure_months);
