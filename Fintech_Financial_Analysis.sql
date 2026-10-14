/* ============================================================
   FINANCE ANALYSIS PROJECT
   Database       : MySQL
   Tables         : customer, transactions
   ============================================================ */


/* ============================================================
   1. MAIN KPI SUMMARY
   Requirements:
   - Total Amount
   - Total Transactions
   - Average Transaction Value
   - Total Fees
   - Total Tax
   ============================================================ */

use fintech_db;
SELECT
    ROUND(SUM(t.amount), 2) AS total_amount,
    COUNT(t.transaction_id) AS total_transactions,
    ROUND(AVG(t.amount), 2) AS average_transaction_value,
    ROUND(SUM(t.fee_amount_clean), 2) AS total_fees,
    ROUND(SUM(t.tax_amount), 2) AS total_tax
FROM transactions t;


/* ============================================================
   2. TOTAL AMOUNT BY YEAR + YOY GROWTH
   ============================================================ */

WITH yearly_amount AS
(
    SELECT
        t.transaction_year AS year,
        SUM(t.amount) AS total_amount
    FROM transactions t
    GROUP BY t.transaction_year
)
SELECT
    year,
    ROUND(total_amount, 2) AS total_amount,
    ROUND(
        LAG(total_amount) OVER (ORDER BY year),
        2
    ) AS previous_year_amount,
    ROUND(
        (
            total_amount -
            LAG(total_amount) OVER (ORDER BY year)
        )
        / NULLIF(
            LAG(total_amount) OVER (ORDER BY year),
            0
        ) * 100,
        2
    ) AS yoy_growth_percent
FROM yearly_amount
ORDER BY year;


/* ============================================================
   3. TOTAL TRANSACTIONS BY YEAR + YOY GROWTH
   ============================================================ */

WITH yearly_transactions AS
(
    SELECT
        t.transaction_year AS year,
        COUNT(t.transaction_id) AS total_transactions
    FROM transactions t
    GROUP BY t.transaction_year
)
SELECT
    year,
    total_transactions,
    LAG(total_transactions) OVER (
        ORDER BY year
    ) AS previous_year_transactions,
    ROUND(
        (
            total_transactions -
            LAG(total_transactions) OVER (
                ORDER BY year
            )
        )
        / NULLIF(
            LAG(total_transactions) OVER (
                ORDER BY year
            ),
            0
        ) * 100,
        2
    ) AS yoy_growth_percent
FROM yearly_transactions
ORDER BY year;


/* ============================================================
   4. TOTAL AMOUNT BY MONTH
   Line / Area Chart
   ============================================================ */

SELECT
    t.transaction_year AS year,
    t.transaction_month_num AS month_number,
    t.transaction_month AS month,
    ROUND(SUM(t.amount), 2) AS total_amount
FROM transactions t
GROUP BY
    t.transaction_year,
    t.transaction_month_num,
    t.transaction_month
ORDER BY
    t.transaction_year,
    t.transaction_month_num;


/* ============================================================
   5. TOTAL AMOUNT BY TRANSACTION STATUS
   Donut Chart
   Required:
   - Success
   - Failed
   - Pending
   ============================================================ */

SELECT
    t.transaction_status,
    ROUND(SUM(t.amount), 2) AS total_amount
FROM transactions t
WHERE t.transaction_status IN
(
    'Success',
    'Failed',
    'Pending'
)
GROUP BY t.transaction_status
ORDER BY total_amount DESC;


/* ============================================================
   6. TOTAL AMOUNT BY CUSTOMER SEGMENT
   Horizontal Bar Chart
   Required:
   - Retail
   - Premium
   - SME
   - Corporate
   - Wealth
   ============================================================ */

SELECT
    c.customer_segment,
    ROUND(SUM(t.amount), 2) AS total_amount
FROM transactions t
INNER JOIN customers c
    ON t.customer_id = c.customer_id
WHERE c.customer_segment IN
(
    'Retail',
    'Premium',
    'SME',
    'Corporate',
    'Wealth'
)
GROUP BY c.customer_segment
ORDER BY total_amount DESC;


/* ============================================================
   7. TOTAL AMOUNT BY STATE
   Horizontal Bar Chart
   ============================================================ */

SELECT
    c.state,
    ROUND(SUM(t.amount), 2) AS total_amount
FROM transactions t
INNER JOIN customers c
    ON t.customer_id = c.customer_id
GROUP BY c.state
ORDER BY total_amount DESC;


/* ============================================================
   8. TRANSACTION TYPE ANALYSIS
   Matrix / Heatmap
   Metrics:
   - Amount
   - Fees
   - Tax
   - Transactions Count
   ============================================================ */

SELECT
    t.transaction_type,
    ROUND(SUM(t.amount), 2) AS total_amount,
    ROUND(SUM(t.fee_amount_clean), 2) AS total_fees,
    ROUND(SUM(t.tax_amount), 2) AS total_tax,
    COUNT(t.transaction_id) AS transaction_count
FROM transactions t
GROUP BY t.transaction_type
ORDER BY total_amount DESC;


/* ============================================================
   9. TOTAL AMOUNT BY GENDER
   Donut Chart
   Required:
   - Male
   - Female
   ============================================================ */

SELECT
    c.gender,
    ROUND(SUM(t.amount), 2) AS total_amount
FROM transactions t
INNER JOIN customers c
    ON t.customer_id = c.customer_id
WHERE c.gender IN
(
    'Male',
    'Female'
)
GROUP BY c.gender
ORDER BY total_amount DESC;


/* ============================================================
   10. DYNAMIC FILTER DATA
   Filters required by Business Requirements:
   - Year
   - Occupation
   - Category
   ============================================================ */

SELECT DISTINCT
    t.transaction_year AS year,
    c.occupation,
    t.merchant_category AS category
FROM transactions t
INNER JOIN customers c
    ON t.customer_id = c.customer_id
ORDER BY
    year,
    c.occupation,
    category;


/* ============================================================
   11. DYNAMIC MEASURE SUPPORT
   Returns the main measures that can be selected dynamically.
   ============================================================ */

SELECT
    'Total Amount' AS measure_name,
    ROUND(SUM(t.amount), 2) AS measure_value
FROM transactions t

UNION ALL

SELECT
    'Total Transactions' AS measure_name,
    COUNT(t.transaction_id) AS measure_value
FROM transactions t

UNION ALL

SELECT
    'Average Transaction Value' AS measure_name,
    ROUND(AVG(t.amount), 2) AS measure_value
FROM transactions t

UNION ALL

SELECT
    'Total Fees' AS measure_name,
    ROUND(SUM(t.fee_amount_clean), 2) AS measure_value
FROM transactions t

UNION ALL

SELECT
    'Total Tax' AS measure_name,
    ROUND(SUM(t.tax_amount), 2) AS measure_value
FROM transactions t;


/* ============================================================
   12. DASHBOARD 2
   DETAILED GRID / UNDERLYING RECORDS
   Includes customer + transaction information
   ============================================================ */

SELECT
    t.transaction_id,
    t.transaction_date,
    t.transaction_month,
    t.account_id,
    t.customer_id,
    c.first_name,
    c.last_name,
    c.gender,
    c.city,
    c.state,
    c.occupation,
    c.customer_segment,
    t.transaction_type,
    t.channel,
    t.merchant_category,
    ROUND(t.amount, 2) AS amount,
    ROUND(t.fee_amount_clean, 2) AS fee_amount,
    ROUND(t.tax_amount, 2) AS tax_amount,
    t.currency,
    t.transaction_status,
    t.is_fraud,
    t.risk_score,
    t.reference_no
FROM transactions t
JOIN customers c
    ON t.customer_id = c.customer_id
ORDER BY t.transaction_date DESC; 


   SELECT
    t.transaction_year AS year,
    t.transaction_month_num AS month_number,
    t.transaction_month AS month,
    t.transaction_type,
    ROUND(SUM(t.amount), 2) AS total_amount,
    ROUND(SUM(t.fee_amount_clean), 2) AS total_fees,
    ROUND(SUM(t.tax_amount), 2) AS total_tax,
    COUNT(t.transaction_id) AS transaction_count
FROM transactions t
GROUP BY
    t.transaction_year,
    t.transaction_month_num,
    t.transaction_month,
    t.transaction_type
ORDER BY
    t.transaction_year,
    t.transaction_month_num,
    t.transaction_type;

/* ============================================================
   14. DRILL-DOWN BY CUSTOMER SEGMENT AND STATE
   ============================================================ */

SELECT
    c.customer_segment,
    c.state,
    c.occupation,
    c.gender,
    ROUND(SUM(t.amount), 2) AS total_amount,
    ROUND(SUM(t.fee_amount_clean), 2) AS total_fees,
    ROUND(SUM(t.tax_amount), 2) AS total_tax,
    COUNT(t.transaction_id) AS transaction_count
FROM transactions t
JOIN customers c
    ON t.customer_id = c.customer_id
GROUP BY
    c.customer_segment,
    c.state,
    c.occupation,
    c.gender
ORDER BY total_amount DESC;


/* ============================================================
   END OF FINANCE ANALYSIS PROJECT
   ============================================================ */