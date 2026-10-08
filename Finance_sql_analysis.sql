/* =====================================================================
   FINANCE ANALYTICS PROJECT  |  SQL ANALYSIS SCRIPT (MySQL 8+ / DBeaver)
   Database : finance_db
   Tables   : fact_transaction (50,000 rows)  |  dim_customer (5,000 rows)
   Join key : fact_transaction.customer_id = dim_customer.customer_id
   Run      : DBeaver -> Execute SQL Script (Alt + X)
   Each query is preceded by the business question it answers.
   ===================================================================== */

USE finance_db;

/* ---------------------------------------------------------------------
   OPTIONAL PERFORMANCE INDEXES (run ONCE; skip any that already exist)
   They make the fact-to-customer join fast on 50K+ rows.
   If a statement errors with "Duplicate key name" / "multiple primary key",
   the index already exists - just ignore that line.
   --------------------------------------------------------------------- */
-- ALTER TABLE dim_customer     ADD PRIMARY KEY (customer_id);
-- ALTER TABLE fact_transaction ADD INDEX idx_f_customer (customer_id);
-- ALTER TABLE fact_transaction ADD INDEX idx_f_year (year);

/* ---------------------------------------------------------------------
   DASHBOARD SLICERS (Year | Dynamic Measure | Occupation | Category)
   Set a value to filter, or NULL for "All".
   p_category      -> merchant_category (e.g. 'Rent', 'Groceries')
   p_measure       -> 'Amount' | 'Transactions' | 'Fees' | 'Tax' | 'Avg Value'
   --------------------------------------------------------------------- */
SET @p_year       = NULL;      -- e.g. 2025
SET @p_occupation = NULL;      -- e.g. 'Salaried'
SET @p_category   = NULL;      -- e.g. 'Rent'
SET @p_measure    = 'Amount';


/* =====================================================================
   SECTION 0 : DATA QUALITY CHECKS
   ===================================================================== */

-- Q0.1 How many rows are in each table?
SELECT 'fact_transaction' AS table_name, COUNT(*) AS row_count FROM fact_transaction
UNION ALL
SELECT 'dim_customer', COUNT(*) FROM dim_customer;

-- Q0.2 Are there duplicate transaction IDs or customer IDs?
SELECT 'duplicate transaction_id' AS check_name, COUNT(*) - COUNT(DISTINCT transaction_id) AS issue_count
FROM fact_transaction
UNION ALL
SELECT 'duplicate customer_id', COUNT(*) - COUNT(DISTINCT customer_id)
FROM dim_customer;

-- Q0.3 Are there transactions whose customer is missing in dim_customer (orphans)?
SELECT COUNT(*) AS orphan_transactions
FROM fact_transaction f
LEFT JOIN dim_customer c ON c.customer_id = f.customer_id
WHERE c.customer_id IS NULL;

-- Q0.4 Are there NULL values in the key measure columns?
SELECT
    SUM(amount     IS NULL) AS null_amount,
    SUM(fee_amount IS NULL) AS null_fee,
    SUM(tax_amount IS NULL) AS null_tax,
    SUM(transaction_status IS NULL) AS null_status
FROM fact_transaction;

-- Q0.5 What is the date coverage per year? (2026 is a partial year -> matters for YoY)
SELECT year,
       MIN(transaction_date) AS first_date,
       MAX(transaction_date) AS last_date,
       COUNT(DISTINCT month_num) AS months_available
FROM fact_transaction
GROUP BY year
ORDER BY year;


/* =====================================================================
   SECTION 1 : MAIN KPIs
   ===================================================================== */

-- Q1.1 What are the 5 headline KPIs (Total Amount, Transactions, Avg Value, Fees, Tax)
--      for the current slicer selection?
SELECT
    ROUND(SUM(f.amount), 2)          AS total_amount,
    COUNT(f.transaction_id)          AS total_transactions,
    ROUND(AVG(f.amount), 2)          AS avg_transaction_value,
    ROUND(SUM(f.fee_amount), 2)      AS total_fees,
    ROUND(SUM(f.tax_amount), 2)      AS total_tax
FROM fact_transaction f
JOIN dim_customer c ON c.customer_id = f.customer_id
WHERE (@p_year       IS NULL OR f.year              = @p_year)
  AND (@p_occupation IS NULL OR c.occupation        = @p_occupation)
  AND (@p_category   IS NULL OR f.merchant_category  = @p_category);

-- Q1.2 What is the Year-over-Year growth in Total Amount, Transactions, Avg Value, Fees and Tax?
--      (Full-year comparison; 2026 only has Jan-Apr so see Q1.3 for like-for-like)
WITH yearly AS (
    SELECT
        f.year,
        SUM(f.amount)       AS total_amount,
        COUNT(*)            AS total_transactions,
        AVG(f.amount)       AS avg_transaction_value,
        SUM(f.fee_amount)   AS total_fees,
        SUM(f.tax_amount)   AS total_tax
    FROM fact_transaction f
    JOIN dim_customer c ON c.customer_id = f.customer_id
    WHERE (@p_occupation IS NULL OR c.occupation       = @p_occupation)
      AND (@p_category   IS NULL OR f.merchant_category = @p_category)
    GROUP BY f.year
)
SELECT
    year,
    ROUND(total_amount, 2)                                                         AS total_amount,
    ROUND(100 * (total_amount - LAG(total_amount) OVER (ORDER BY year))
              / NULLIF(LAG(total_amount) OVER (ORDER BY year), 0), 2)              AS amount_yoy_pct,
    total_transactions,
    ROUND(100 * (total_transactions - LAG(total_transactions) OVER (ORDER BY year))
              / NULLIF(LAG(total_transactions) OVER (ORDER BY year), 0), 2)        AS txn_yoy_pct,
    ROUND(avg_transaction_value, 2)                                                AS avg_transaction_value,
    ROUND(100 * (avg_transaction_value - LAG(avg_transaction_value) OVER (ORDER BY year))
              / NULLIF(LAG(avg_transaction_value) OVER (ORDER BY year), 0), 2)     AS avg_value_yoy_pct,
    ROUND(total_fees, 2)                                                           AS total_fees,
    ROUND(100 * (total_fees - LAG(total_fees) OVER (ORDER BY year))
              / NULLIF(LAG(total_fees) OVER (ORDER BY year), 0), 2)                AS fees_yoy_pct,
    ROUND(total_tax, 2)                                                            AS total_tax,
    ROUND(100 * (total_tax - LAG(total_tax) OVER (ORDER BY year))
              / NULLIF(LAG(total_tax) OVER (ORDER BY year), 0), 2)                 AS tax_yoy_pct
FROM yearly
ORDER BY year;

-- Q1.3 Like-for-like YoY: how does each year compare to the previous year for the SAME months
--      (Jan to the latest month available in the data)?
WITH last_month AS (
    SELECT MAX(month_num) AS m FROM fact_transaction WHERE year = (SELECT MAX(year) FROM fact_transaction)
),
ytd AS (
    SELECT f.year,
           SUM(f.amount) AS total_amount,
           COUNT(*)      AS total_transactions
    FROM fact_transaction f
    JOIN dim_customer c ON c.customer_id = f.customer_id
    WHERE f.month_num <= (SELECT m FROM last_month)
      AND (@p_occupation IS NULL OR c.occupation       = @p_occupation)
      AND (@p_category   IS NULL OR f.merchant_category = @p_category)
    GROUP BY f.year
)
SELECT
    year,
    ROUND(total_amount, 2) AS ytd_amount,
    ROUND(100 * (total_amount - LAG(total_amount) OVER (ORDER BY year))
              / NULLIF(LAG(total_amount) OVER (ORDER BY year), 0), 2) AS ytd_amount_yoy_pct,
    total_transactions     AS ytd_transactions,
    ROUND(100 * (total_transactions - LAG(total_transactions) OVER (ORDER BY year))
              / NULLIF(LAG(total_transactions) OVER (ORDER BY year), 0), 2) AS ytd_txn_yoy_pct
FROM ytd
ORDER BY year;

-- Q1.4 What is the dynamic measure selected in the slicer, by year?
--      (Drives the "Dynamic Measure" switch: Amount / Transactions / Fees / Tax / Avg Value)
SELECT
    f.year,
    ROUND(CASE @p_measure
        WHEN 'Amount'       THEN SUM(f.amount)
        WHEN 'Transactions' THEN COUNT(f.transaction_id)
        WHEN 'Fees'         THEN SUM(f.fee_amount)
        WHEN 'Tax'          THEN SUM(f.tax_amount)
        WHEN 'Avg Value'    THEN AVG(f.amount)
    END, 2) AS selected_measure_value
FROM fact_transaction f
JOIN dim_customer c ON c.customer_id = f.customer_id
WHERE (@p_occupation IS NULL OR c.occupation       = @p_occupation)
  AND (@p_category   IS NULL OR f.merchant_category = @p_category)
GROUP BY f.year
ORDER BY f.year;


/* =====================================================================
   SECTION 2 : CHART QUERIES
   ===================================================================== */

-- Q2.1 CHART 1 - Total Amount by Month (Line/Area): What are the monthly trends and seasonal spikes/drops?
SELECT
    f.year,
    f.month_num,
    f.month_name,
    f.`year_month`,
    ROUND(SUM(f.amount), 2) AS total_amount,
    COUNT(*)                AS total_transactions
FROM fact_transaction f
JOIN dim_customer c ON c.customer_id = f.customer_id
WHERE (@p_year       IS NULL OR f.year              = @p_year)
  AND (@p_occupation IS NULL OR c.occupation        = @p_occupation)
  AND (@p_category   IS NULL OR f.merchant_category  = @p_category)
GROUP BY f.year, f.month_num, f.month_name, f.`year_month`
ORDER BY f.year, f.month_num;

-- Q2.2 Which calendar month is strongest/weakest on average across all years? (seasonality)
SELECT
    f.month_num,
    f.month_name,
    ROUND(SUM(f.amount), 2)                          AS total_amount,
    ROUND(SUM(f.amount) / COUNT(DISTINCT f.year), 2) AS avg_amount_per_year
FROM fact_transaction f
JOIN dim_customer c ON c.customer_id = f.customer_id
WHERE (@p_occupation IS NULL OR c.occupation       = @p_occupation)
  AND (@p_category   IS NULL OR f.merchant_category = @p_category)
GROUP BY f.month_num, f.month_name
ORDER BY f.month_num;

-- Q2.3 What is the Month-over-Month amount change within the selection?
WITH monthly AS (
    SELECT f.`year_month`, SUM(f.amount) AS total_amount
    FROM fact_transaction f
    JOIN dim_customer c ON c.customer_id = f.customer_id
    WHERE (@p_year       IS NULL OR f.year              = @p_year)
      AND (@p_occupation IS NULL OR c.occupation        = @p_occupation)
      AND (@p_category   IS NULL OR f.merchant_category  = @p_category)
    GROUP BY f.`year_month`
)
SELECT
    `year_month`,
    ROUND(total_amount, 2) AS total_amount,
    ROUND(100 * (total_amount - LAG(total_amount) OVER (ORDER BY `year_month`))
              / NULLIF(LAG(total_amount) OVER (ORDER BY `year_month`), 0), 2) AS mom_growth_pct
FROM monthly
ORDER BY `year_month`;

-- Q2.4 CHART 2 - Total Amount by Transaction Status (Donut): Success vs Failed vs Pending
SELECT
    f.transaction_status,
    ROUND(SUM(f.amount), 2) AS total_amount,
    COUNT(*)                AS total_transactions,
    ROUND(100 * SUM(f.amount) / SUM(SUM(f.amount)) OVER (), 2) AS amount_share_pct
FROM fact_transaction f
JOIN dim_customer c ON c.customer_id = f.customer_id
WHERE (@p_year       IS NULL OR f.year              = @p_year)
  AND (@p_occupation IS NULL OR c.occupation        = @p_occupation)
  AND (@p_category   IS NULL OR f.merchant_category  = @p_category)
GROUP BY f.transaction_status
ORDER BY total_amount DESC;

-- Q2.5 What is the transaction success rate (by count and by amount), per year?
SELECT
    f.year,
    ROUND(100 * SUM(f.transaction_status = 'Success') / COUNT(*), 2)                            AS success_rate_count_pct,
    ROUND(100 * SUM(CASE WHEN f.transaction_status = 'Success' THEN f.amount ELSE 0 END)
              / SUM(f.amount), 2)                                                               AS success_rate_amount_pct,
    ROUND(100 * SUM(f.transaction_status = 'Failed')  / COUNT(*), 2)                            AS failure_rate_count_pct,
    ROUND(100 * SUM(f.transaction_status = 'Pending') / COUNT(*), 2)                            AS pending_rate_count_pct
FROM fact_transaction f
JOIN dim_customer c ON c.customer_id = f.customer_id
WHERE (@p_occupation IS NULL OR c.occupation       = @p_occupation)
  AND (@p_category   IS NULL OR f.merchant_category = @p_category)
GROUP BY f.year
ORDER BY f.year;

-- Q2.6 CHART 3 - Total Amount by Customer Segment (Horizontal Bar): Which segment contributes the most?
SELECT
    c.customer_segment,
    ROUND(SUM(f.amount), 2)  AS total_amount,
    COUNT(*)                 AS total_transactions,
    COUNT(DISTINCT c.customer_id) AS active_customers,
    ROUND(100 * SUM(f.amount) / SUM(SUM(f.amount)) OVER (), 2) AS amount_share_pct
FROM fact_transaction f
JOIN dim_customer c ON c.customer_id = f.customer_id
WHERE (@p_year       IS NULL OR f.year              = @p_year)
  AND (@p_occupation IS NULL OR c.occupation        = @p_occupation)
  AND (@p_category   IS NULL OR f.merchant_category  = @p_category)
GROUP BY c.customer_segment
ORDER BY total_amount DESC;

-- Q2.7 How much does an average customer spend in each segment? (value per customer)
SELECT
    c.customer_segment,
    COUNT(DISTINCT c.customer_id)                                  AS active_customers,
    ROUND(SUM(f.amount) / COUNT(DISTINCT c.customer_id), 2)        AS amount_per_customer
FROM fact_transaction f
JOIN dim_customer c ON c.customer_id = f.customer_id
WHERE (@p_year       IS NULL OR f.year              = @p_year)
  AND (@p_occupation IS NULL OR c.occupation        = @p_occupation)
  AND (@p_category   IS NULL OR f.merchant_category  = @p_category)
GROUP BY c.customer_segment
ORDER BY amount_per_customer DESC;

-- Q2.8 CHART 4 - Total Amount by State (Horizontal Bar): Which regions perform best?
SELECT
    c.state,
    ROUND(SUM(f.amount), 2) AS total_amount,
    COUNT(*)                AS total_transactions,
    RANK() OVER (ORDER BY SUM(f.amount) DESC) AS amount_rank
FROM fact_transaction f
JOIN dim_customer c ON c.customer_id = f.customer_id
WHERE (@p_year       IS NULL OR f.year              = @p_year)
  AND (@p_occupation IS NULL OR c.occupation        = @p_occupation)
  AND (@p_category   IS NULL OR f.merchant_category  = @p_category)
GROUP BY c.state
ORDER BY total_amount DESC;

-- Q2.9 Which are the Top 5 states and what share of total amount do they contribute?
WITH state_amt AS (
    SELECT c.state, SUM(f.amount) AS total_amount
    FROM fact_transaction f
    JOIN dim_customer c ON c.customer_id = f.customer_id
    WHERE (@p_year       IS NULL OR f.year              = @p_year)
      AND (@p_occupation IS NULL OR c.occupation        = @p_occupation)
      AND (@p_category   IS NULL OR f.merchant_category  = @p_category)
    GROUP BY c.state
)
SELECT
    state,
    ROUND(total_amount, 2) AS total_amount,
    ROUND(100 * total_amount / SUM(total_amount) OVER (), 2) AS share_pct
FROM state_amt
ORDER BY total_amount DESC
LIMIT 5;

-- Q2.10 CHART 5 - Transaction Type Analysis (Matrix/Heatmap): Amount, Fees, Tax and Count per type
SELECT
    f.transaction_type,
    ROUND(SUM(f.amount), 2)      AS total_amount,
    ROUND(SUM(f.fee_amount), 2)  AS total_fees,
    ROUND(SUM(f.tax_amount), 2)  AS total_tax,
    COUNT(*)                     AS transaction_count
FROM fact_transaction f
JOIN dim_customer c ON c.customer_id = f.customer_id
WHERE (@p_year       IS NULL OR f.year              = @p_year)
  AND (@p_occupation IS NULL OR c.occupation        = @p_occupation)
  AND (@p_category   IS NULL OR f.merchant_category  = @p_category)
GROUP BY f.transaction_type
ORDER BY total_amount DESC;

-- Q2.11 Which transaction types are most profitable? (fee + tax earned as % of amount)
SELECT
    f.transaction_type,
    ROUND(SUM(f.fee_amount + f.tax_amount), 2)                        AS fee_plus_tax,
    ROUND(100 * SUM(f.fee_amount) / NULLIF(SUM(f.amount), 0), 3)      AS fee_pct_of_amount,
    ROUND(100 * SUM(f.tax_amount) / NULLIF(SUM(f.amount), 0), 3)      AS tax_pct_of_amount,
    ROUND(SUM(f.fee_amount) / COUNT(*), 2)                            AS avg_fee_per_txn
FROM fact_transaction f
JOIN dim_customer c ON c.customer_id = f.customer_id
WHERE (@p_year       IS NULL OR f.year              = @p_year)
  AND (@p_occupation IS NULL OR c.occupation        = @p_occupation)
  AND (@p_category   IS NULL OR f.merchant_category  = @p_category)
GROUP BY f.transaction_type
ORDER BY fee_plus_tax DESC;

-- Q2.12 CHART 6 - Total Amount by Gender (Donut): Male vs Female contribution
SELECT
    c.gender,
    ROUND(SUM(f.amount), 2) AS total_amount,
    COUNT(*)                AS total_transactions,
    ROUND(100 * SUM(f.amount) / SUM(SUM(f.amount)) OVER (), 2) AS amount_share_pct
FROM fact_transaction f
JOIN dim_customer c ON c.customer_id = f.customer_id
WHERE (@p_year       IS NULL OR f.year              = @p_year)
  AND (@p_occupation IS NULL OR c.occupation        = @p_occupation)
  AND (@p_category   IS NULL OR f.merchant_category  = @p_category)
GROUP BY c.gender
ORDER BY total_amount DESC;

-- Q2.13 Gender-based analysis: how does each gender split across customer segments?
SELECT
    c.customer_segment,
    ROUND(SUM(CASE WHEN c.gender = 'Male'   THEN f.amount ELSE 0 END), 2) AS male_amount,
    ROUND(SUM(CASE WHEN c.gender = 'Female' THEN f.amount ELSE 0 END), 2) AS female_amount
FROM fact_transaction f
JOIN dim_customer c ON c.customer_id = f.customer_id
WHERE (@p_year       IS NULL OR f.year              = @p_year)
  AND (@p_occupation IS NULL OR c.occupation        = @p_occupation)
  AND (@p_category   IS NULL OR f.merchant_category  = @p_category)
GROUP BY c.customer_segment
ORDER BY c.customer_segment;

-- Q2.14 Amount by Occupation (supports the Occupation slicer): who contributes most?
SELECT
    c.occupation,
    ROUND(SUM(f.amount), 2) AS total_amount,
    COUNT(*)                AS total_transactions,
    ROUND(100 * SUM(f.amount) / SUM(SUM(f.amount)) OVER (), 2) AS amount_share_pct
FROM fact_transaction f
JOIN dim_customer c ON c.customer_id = f.customer_id
WHERE (@p_year     IS NULL OR f.year              = @p_year)
  AND (@p_category IS NULL OR f.merchant_category = @p_category)
GROUP BY c.occupation
ORDER BY total_amount DESC;

-- Q2.15 Amount by Category / merchant category (supports the Category slicer)
SELECT
    f.merchant_category,
    ROUND(SUM(f.amount), 2) AS total_amount,
    COUNT(*)                AS total_transactions,
    ROUND(100 * SUM(f.amount) / SUM(SUM(f.amount)) OVER (), 2) AS amount_share_pct
FROM fact_transaction f
JOIN dim_customer c ON c.customer_id = f.customer_id
WHERE (@p_year       IS NULL OR f.year       = @p_year)
  AND (@p_occupation IS NULL OR c.occupation = @p_occupation)
GROUP BY f.merchant_category
ORDER BY total_amount DESC;


/* =====================================================================
   SECTION 3 : CROSS-DIMENSION INSIGHTS
   ===================================================================== */

-- Q3.1 Which state + segment combinations generate the highest amount? (Top 10)
SELECT
    c.state,
    c.customer_segment,
    ROUND(SUM(f.amount), 2) AS total_amount
FROM fact_transaction f
JOIN dim_customer c ON c.customer_id = f.customer_id
WHERE (@p_year       IS NULL OR f.year              = @p_year)
  AND (@p_occupation IS NULL OR c.occupation        = @p_occupation)
  AND (@p_category   IS NULL OR f.merchant_category  = @p_category)
GROUP BY c.state, c.customer_segment
ORDER BY total_amount DESC
LIMIT 10;

-- Q3.2 Which channel is used most, and what is its success rate?
SELECT
    f.channel,
    COUNT(*)                                                   AS total_transactions,
    ROUND(SUM(f.amount), 2)                                    AS total_amount,
    ROUND(100 * SUM(f.transaction_status = 'Success') / COUNT(*), 2) AS success_rate_pct
FROM fact_transaction f
JOIN dim_customer c ON c.customer_id = f.customer_id
WHERE (@p_year       IS NULL OR f.year              = @p_year)
  AND (@p_occupation IS NULL OR c.occupation        = @p_occupation)
  AND (@p_category   IS NULL OR f.merchant_category  = @p_category)
GROUP BY f.channel
ORDER BY total_transactions DESC;

-- Q3.3 How much amount is at risk from failed and pending transactions, by transaction type?
SELECT
    f.transaction_type,
    ROUND(SUM(CASE WHEN f.transaction_status = 'Failed'  THEN f.amount ELSE 0 END), 2) AS failed_amount,
    ROUND(SUM(CASE WHEN f.transaction_status = 'Pending' THEN f.amount ELSE 0 END), 2) AS pending_amount,
    ROUND(100 * SUM(CASE WHEN f.transaction_status <> 'Success' THEN f.amount ELSE 0 END)
              / NULLIF(SUM(f.amount), 0), 2)                                            AS non_success_amount_pct
FROM fact_transaction f
JOIN dim_customer c ON c.customer_id = f.customer_id
WHERE (@p_year       IS NULL OR f.year              = @p_year)
  AND (@p_occupation IS NULL OR c.occupation        = @p_occupation)
  AND (@p_category   IS NULL OR f.merchant_category  = @p_category)
GROUP BY f.transaction_type
ORDER BY failed_amount DESC;

-- Q3.4 Who are the Top 10 customers by total transaction amount?
SELECT
    c.customer_id,
    c.full_name,
    c.state,
    c.customer_segment,
    ROUND(SUM(f.amount), 2) AS total_amount,
    COUNT(*)                AS total_transactions
FROM fact_transaction f
JOIN dim_customer c ON c.customer_id = f.customer_id
WHERE (@p_year       IS NULL OR f.year              = @p_year)
  AND (@p_occupation IS NULL OR c.occupation        = @p_occupation)
  AND (@p_category   IS NULL OR f.merchant_category  = @p_category)
GROUP BY c.customer_id, c.full_name, c.state, c.customer_segment
ORDER BY total_amount DESC
LIMIT 10;

-- Q3.5 Fraud overview: how many flagged transactions and how much amount, by year?
SELECT
    f.year,
    SUM(f.is_fraud = 'Yes')                                      AS fraud_transactions,
    ROUND(SUM(CASE WHEN f.is_fraud = 'Yes' THEN f.amount ELSE 0 END), 2) AS fraud_amount,
    ROUND(100 * SUM(f.is_fraud = 'Yes') / COUNT(*), 2)           AS fraud_rate_pct
FROM fact_transaction f
JOIN dim_customer c ON c.customer_id = f.customer_id
WHERE (@p_occupation IS NULL OR c.occupation       = @p_occupation)
  AND (@p_category   IS NULL OR f.merchant_category = @p_category)
GROUP BY f.year
ORDER BY f.year;


/* =====================================================================
   SECTION 4 : DASHBOARD 2 - DETAILED GRID VIEW & DRILL-DOWN
   ===================================================================== */

-- Q4.1 GRID VIEW: Show every underlying transaction record with customer details
--      (respects all slicers; newest first)
SELECT
    f.transaction_id,
    f.transaction_date,
    f.year,
    f.month_name,
    f.account_id,
    f.customer_id,
    c.full_name,
    c.gender,
    c.occupation,
    c.customer_segment,
    c.city,
    c.state,
    f.transaction_type,
    f.merchant_category,
    f.channel,
    f.transaction_status,
    f.amount,
    f.fee_amount,
    f.tax_amount,
    f.total_cost,
    f.net_amount,
    f.is_fraud,
    f.risk_score,
    f.reference_no
FROM fact_transaction f
JOIN dim_customer c ON c.customer_id = f.customer_id
WHERE (@p_year       IS NULL OR f.year              = @p_year)
  AND (@p_occupation IS NULL OR c.occupation        = @p_occupation)
  AND (@p_category   IS NULL OR f.merchant_category  = @p_category)
ORDER BY f.transaction_date DESC, f.transaction_id DESC;

-- Q4.2 DRILL LEVEL 1 - Year > Month: what is the amount for each month inside each year?
SELECT
    f.year,
    f.month_num,
    f.month_name,
    ROUND(SUM(f.amount), 2) AS total_amount,
    COUNT(*)                AS total_transactions
FROM fact_transaction f
JOIN dim_customer c ON c.customer_id = f.customer_id
WHERE (@p_occupation IS NULL OR c.occupation       = @p_occupation)
  AND (@p_category   IS NULL OR f.merchant_category = @p_category)
GROUP BY f.year, f.month_num, f.month_name
ORDER BY f.year, f.month_num;

-- Q4.3 DRILL LEVEL 2 - State > City: what are the city-wise numbers within each state?
SELECT
    c.state,
    c.city,
    ROUND(SUM(f.amount), 2) AS total_amount,
    COUNT(*)                AS total_transactions,
    COUNT(DISTINCT c.customer_id) AS customers
FROM fact_transaction f
JOIN dim_customer c ON c.customer_id = f.customer_id
WHERE (@p_year       IS NULL OR f.year              = @p_year)
  AND (@p_occupation IS NULL OR c.occupation        = @p_occupation)
  AND (@p_category   IS NULL OR f.merchant_category  = @p_category)
GROUP BY c.state, c.city
ORDER BY c.state, total_amount DESC;

-- Q4.4 DRILL LEVEL 3 - Transaction Type > Status: how does each type split by status?
SELECT
    f.transaction_type,
    f.transaction_status,
    ROUND(SUM(f.amount), 2) AS total_amount,
    COUNT(*)                AS total_transactions
FROM fact_transaction f
JOIN dim_customer c ON c.customer_id = f.customer_id
WHERE (@p_year       IS NULL OR f.year              = @p_year)
  AND (@p_occupation IS NULL OR c.occupation        = @p_occupation)
  AND (@p_category   IS NULL OR f.merchant_category  = @p_category)
GROUP BY f.transaction_type, f.transaction_status
ORDER BY f.transaction_type, f.transaction_status;

-- Q4.5 DRILL LEVEL 4 - Customer > Transactions: show all records for ONE customer
--      (change the customer id below)
SET @p_customer_id = 'C00001';

SELECT
    f.transaction_id,
    f.transaction_date,
    f.transaction_type,
    f.merchant_category,
    f.channel,
    f.transaction_status,
    f.amount,
    f.fee_amount,
    f.tax_amount,
    f.net_amount
FROM fact_transaction f
WHERE f.customer_id = @p_customer_id
ORDER BY f.transaction_date DESC;

-- Q4.6 DRILL-THROUGH - Show all failed transactions with customer info for follow-up
SELECT
    f.transaction_id,
    f.transaction_date,
    c.full_name,
    c.state,
    f.transaction_type,
    f.channel,
    f.amount
FROM fact_transaction f
JOIN dim_customer c ON c.customer_id = f.customer_id
WHERE f.transaction_status = 'Failed'
  AND (@p_year       IS NULL OR f.year              = @p_year)
  AND (@p_occupation IS NULL OR c.occupation        = @p_occupation)
  AND (@p_category   IS NULL OR f.merchant_category  = @p_category)
ORDER BY f.amount DESC;

/* ============================ END OF SCRIPT ============================ */