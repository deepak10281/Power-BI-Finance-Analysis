use financial_analytics;
select*from customers;
select*from finance_transactions;

# 1. KPI Cards (All KPIs)
SELECT
    SUM(amount) AS Total_Amount,
    COUNT(transaction_id) AS Total_Transactions,
    AVG(amount) AS Avg_Transaction_Value,
    SUM(fee_amount) AS Total_Fees,
    SUM(tax_amount) AS Total_Tax
FROM finance_transactions;

# YoY Growth Analysis
WITH yearly_data AS
(
    SELECT
        YEAR(transaction_date) AS Year,
        SUM(amount) AS Total_Amount,
        COUNT(transaction_id) AS Total_Transactions
    FROM finance_transactions
    GROUP BY YEAR(transaction_date)
)
SELECT
    curr.Year,
    curr.Total_Amount,
    prev.Total_Amount AS Prev_Year_Amount,
    ROUND(
        ((curr.Total_Amount - prev.Total_Amount) * 100.0)
        / NULLIF(prev.Total_Amount,0),2
    ) AS YoY_Growth_Percentage
FROM yearly_data curr
LEFT JOIN yearly_data prev
ON curr.Year = prev.Year + 1
ORDER BY curr.Year;


-- Total Amount by Month
-- Total Amount by Month
SELECT
    YEAR(transaction_date) AS Year,
    MONTH(transaction_date) AS Month,
    MONTHNAME(transaction_date) AS Month_Name,
    SUM(amount) AS Total_Amount
FROM finance_transactions
GROUP BY
    YEAR(transaction_date),
    MONTH(transaction_date),
    MONTHNAME(transaction_date)
ORDER BY Year, Month;

# Amount by Transaction Status
SELECT
    transaction_status,
    SUM(amount) AS Total_Amount
FROM finance_transactions
GROUP BY transaction_status
ORDER BY Total_Amount DESC;

# Amount by Customer Segment
SELECT
    c.customer_segment,
    SUM(f.amount) AS Total_Amount
FROM finance_transactions f
JOIN customers c
ON f.customer_id = c.customer_id
GROUP BY c.customer_segment
ORDER BY Total_Amount DESC;

# Amount by State
SELECT
    c.state,
    SUM(f.amount) AS Total_Amount
FROM finance_transactions f
JOIN customers c
ON f.customer_id = c.customer_id
GROUP BY c.state
ORDER BY Total_Amount DESC;

# Transaction Type Analysis (Matrix)
SELECT
    transaction_type,
    SUM(amount) AS Total_Amount,
    SUM(fee_amount) AS Total_Fees,
    SUM(tax_amount) AS Total_Tax,
    COUNT(transaction_id) AS Total_Transactions
FROM finance_transactions
GROUP BY transaction_type
ORDER BY Total_Amount DESC;

# Amount by Gender
SELECT
    c.gender,
    SUM(f.amount) AS Total_Amount
FROM finance_transactions f
JOIN customers c
ON f.customer_id = c.customer_id
GROUP BY c.gender;

# Slicers to be used in Dashboard
SELECT DISTINCT
    YEAR(transaction_date) AS Year
FROM finance_transactions
ORDER BY Year;

SELECT DISTINCT occupation
FROM customers
ORDER BY occupation;

SELECT DISTINCT merchant_category
FROM finance_transactions
ORDER BY merchant_category;

# Drill Through Table in dashboard
SELECT
    f.transaction_id,
    f.transaction_date,
    c.customer_name,
    c.gender,
    c.state,
    c.occupation,
    c.customer_segment,
    f.transaction_type,
    f.channel,
    f.merchant_category,
    f.amount,
    f.fee_amount,
    f.tax_amount,
    f.transaction_status
FROM finance_transactions f
JOIN customers c
ON f.customer_id = c.customer_id
ORDER BY f.transaction_date DESC;





























