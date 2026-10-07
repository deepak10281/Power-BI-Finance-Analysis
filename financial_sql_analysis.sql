USE financial_db;

-- 1. Data validation
SELECT COUNT(*) AS total_records,
       COUNT(DISTINCT transaction_id) AS unique_transactions,
       COUNT(DISTINCT customer_id) AS total_customers,
       MIN(transaction_year) AS first_year,
       MAX(transaction_year) AS last_year
FROM financial_transactions;

-- 2. Missing values
SELECT SUM(transaction_id IS NULL) AS missing_transaction_id,
       SUM(customer_id IS NULL) AS missing_customer_id,
       SUM(transaction_date IS NULL) AS missing_date,
       SUM(amount IS NULL) AS missing_amount,
       SUM(fee_amount IS NULL) AS missing_fee,
       SUM(tax_amount IS NULL) AS missing_tax,
       SUM(transaction_status IS NULL) AS missing_status,
       SUM(channel IS NULL) AS missing_channel,
       SUM(risk_score IS NULL) AS missing_risk_score
FROM financial_transactions;

-- 3. Duplicate transaction IDs
SELECT transaction_id, COUNT(*) AS duplicate_count
FROM financial_transactions
GROUP BY transaction_id
HAVING COUNT(*) > 1;

-- 4. Negative amounts and invalid risk scores
SELECT SUM(amount < 0) AS negative_amount_records,
       SUM(risk_score < 0 OR risk_score > 100) AS invalid_risk_scores
FROM financial_transactions;

-- 5. Future-dated records
SELECT COUNT(*) AS future_records,
       ROUND(SUM(amount), 2) AS future_value
FROM financial_transactions
WHERE transaction_date > CURDATE();

-- 6. KPI cards (Total Amount, Transactions, Avg Value, Fees, Tax)
SELECT ROUND(SUM(amount), 2) AS total_amount,
       COUNT(*) AS total_transactions,
       ROUND(AVG(amount), 2) AS average_transaction_value,
       ROUND(SUM(COALESCE(fee_amount, 0)), 2) AS total_fees,
       ROUND(SUM(COALESCE(tax_amount, 0)), 2) AS total_tax
FROM financial_transactions;

-- 7. KPI cards by year with YoY growth
WITH yearly AS (
    SELECT transaction_year AS year,
           SUM(amount) AS total_amount,
           COUNT(*) AS total_transactions,
           AVG(amount) AS avg_transaction_value,
           SUM(COALESCE(fee_amount, 0)) AS total_fees,
           SUM(COALESCE(tax_amount, 0)) AS total_tax
    FROM financial_transactions
    GROUP BY transaction_year
)
SELECT year,
       ROUND(total_amount, 2) AS total_amount,
       ROUND((total_amount - LAG(total_amount) OVER (ORDER BY year))
             / NULLIF(LAG(total_amount) OVER (ORDER BY year), 0) * 100, 2) AS amount_yoy_pct,
       total_transactions,
       ROUND((total_transactions - LAG(total_transactions) OVER (ORDER BY year))
             / NULLIF(LAG(total_transactions) OVER (ORDER BY year), 0) * 100, 2) AS transactions_yoy_pct,
       ROUND(avg_transaction_value, 2) AS avg_transaction_value,
       ROUND((avg_transaction_value - LAG(avg_transaction_value) OVER (ORDER BY year))
             / NULLIF(LAG(avg_transaction_value) OVER (ORDER BY year), 0) * 100, 2) AS avg_value_yoy_pct,
       ROUND(total_fees, 2) AS total_fees,
       ROUND((total_fees - LAG(total_fees) OVER (ORDER BY year))
             / NULLIF(LAG(total_fees) OVER (ORDER BY year), 0) * 100, 2) AS fees_yoy_pct,
       ROUND(total_tax, 2) AS total_tax,
       ROUND((total_tax - LAG(total_tax) OVER (ORDER BY year))
             / NULLIF(LAG(total_tax) OVER (ORDER BY year), 0) * 100, 2) AS tax_yoy_pct
FROM yearly
ORDER BY year;

-- 8. Chart 1: Total amount by month (all years)
SELECT transaction_year AS year,
       transaction_month AS month_no,
       transaction_month_name AS month_name,
       ROUND(SUM(amount), 2) AS total_amount,
       COUNT(*) AS transactions
FROM financial_transactions
GROUP BY transaction_year, transaction_month, transaction_month_name
ORDER BY transaction_year, transaction_month;

-- 9. Chart 1: Seasonality, same month compared across years
SELECT transaction_month AS month_no,
       transaction_month_name AS month_name,
       ROUND(SUM(CASE WHEN transaction_year = 2023 THEN amount ELSE 0 END), 2) AS amount_2023,
       ROUND(SUM(CASE WHEN transaction_year = 2024 THEN amount ELSE 0 END), 2) AS amount_2024,
       ROUND(SUM(CASE WHEN transaction_year = 2025 THEN amount ELSE 0 END), 2) AS amount_2025,
       ROUND(SUM(CASE WHEN transaction_year = 2026 THEN amount ELSE 0 END), 2) AS amount_2026
FROM financial_transactions
GROUP BY transaction_month, transaction_month_name
ORDER BY transaction_month;

-- 10. Month-over-month growth
WITH monthly AS (
    SELECT transaction_year AS year,
           transaction_month AS month_no,
           SUM(amount) AS total_amount
    FROM financial_transactions
    GROUP BY transaction_year, transaction_month
)
SELECT year,
       month_no,
       ROUND(total_amount, 2) AS total_amount,
       ROUND(LAG(total_amount) OVER (ORDER BY year, month_no), 2) AS previous_month_amount,
       ROUND((total_amount - LAG(total_amount) OVER (ORDER BY year, month_no))
             / NULLIF(LAG(total_amount) OVER (ORDER BY year, month_no), 0) * 100, 2) AS mom_growth_pct
FROM monthly
ORDER BY year, month_no;

-- 11. Chart 2: Total amount by transaction status (donut)
SELECT transaction_status,
       COUNT(*) AS transactions,
       ROUND(SUM(amount), 2) AS total_amount,
       ROUND(SUM(amount) / SUM(SUM(amount)) OVER () * 100, 2) AS amount_share_pct,
       ROUND(COUNT(*) / SUM(COUNT(*)) OVER () * 100, 2) AS transaction_share_pct
FROM financial_transactions
GROUP BY transaction_status
ORDER BY total_amount DESC;

-- 12. Transaction success rate
SELECT COUNT(*) AS total_transactions,
       SUM(transaction_status = 'Success') AS successful,
       SUM(transaction_status = 'Failed') AS failed,
       SUM(transaction_status = 'Pending') AS pending,
       ROUND(SUM(transaction_status = 'Success') / COUNT(*) * 100, 2) AS success_rate_pct
FROM financial_transactions;

-- 13. Chart 3: Total amount by customer segment
SELECT customer_segment,
       COUNT(DISTINCT customer_id) AS customers,
       COUNT(*) AS transactions,
       ROUND(SUM(amount), 2) AS total_amount,
       ROUND(AVG(amount), 2) AS avg_transaction_value,
       ROUND(SUM(amount) / SUM(SUM(amount)) OVER () * 100, 2) AS contribution_pct
FROM financial_transactions
GROUP BY customer_segment
ORDER BY total_amount DESC;

-- 14. Chart 4: Total amount by state
SELECT state,
       COUNT(DISTINCT customer_id) AS customers,
       COUNT(*) AS transactions,
       ROUND(SUM(amount), 2) AS total_amount,
       ROUND(AVG(amount), 2) AS avg_transaction_value,
       ROUND(SUM(amount) / SUM(SUM(amount)) OVER () * 100, 2) AS contribution_pct,
       RANK() OVER (ORDER BY SUM(amount) DESC) AS state_rank
FROM financial_transactions
GROUP BY state
ORDER BY total_amount DESC;

-- 15. Chart 5: Transaction type matrix (amount, fees, tax, count)
SELECT transaction_type,
       ROUND(SUM(amount), 2) AS total_amount,
       ROUND(SUM(COALESCE(fee_amount, 0)), 2) AS total_fees,
       ROUND(SUM(COALESCE(tax_amount, 0)), 2) AS total_tax,
       COUNT(*) AS transactions,
       ROUND(SUM(COALESCE(fee_amount, 0)) / NULLIF(SUM(amount), 0) * 100, 2) AS fee_pct_of_amount
FROM financial_transactions
GROUP BY transaction_type
ORDER BY total_amount DESC;

-- 16. Chart 5: Transaction type by year
SELECT transaction_type,
       transaction_year AS year,
       ROUND(SUM(amount), 2) AS total_amount,
       ROUND(SUM(COALESCE(fee_amount, 0)), 2) AS total_fees,
       ROUND(SUM(COALESCE(tax_amount, 0)), 2) AS total_tax,
       COUNT(*) AS transactions
FROM financial_transactions
GROUP BY transaction_type, transaction_year
ORDER BY transaction_type, transaction_year;

-- 17. Chart 6: Total amount by gender (donut)
SELECT gender,
       COUNT(DISTINCT customer_id) AS customers,
       COUNT(*) AS transactions,
       ROUND(SUM(amount), 2) AS total_amount,
       ROUND(SUM(amount) / SUM(SUM(amount)) OVER () * 100, 2) AS contribution_pct
FROM financial_transactions
GROUP BY gender
ORDER BY total_amount DESC;

-- 18. Slicer: Occupation analysis
SELECT occupation,
       COUNT(DISTINCT customer_id) AS customers,
       COUNT(*) AS transactions,
       ROUND(SUM(amount), 2) AS total_amount,
       ROUND(AVG(amount), 2) AS avg_transaction_value,
       ROUND(SUM(COALESCE(fee_amount, 0)), 2) AS total_fees,
       ROUND(SUM(COALESCE(tax_amount, 0)), 2) AS total_tax
FROM financial_transactions
GROUP BY occupation
ORDER BY total_amount DESC;

-- 19. Slicer: Category (merchant category) analysis
SELECT merchant_category,
       COUNT(*) AS transactions,
       COUNT(DISTINCT customer_id) AS customers,
       ROUND(SUM(amount), 2) AS total_amount,
       ROUND(AVG(amount), 2) AS avg_transaction_value,
       ROUND(SUM(COALESCE(fee_amount, 0)), 2) AS total_fees,
       ROUND(SUM(COALESCE(tax_amount, 0)), 2) AS total_tax
FROM financial_transactions
GROUP BY merchant_category
ORDER BY total_amount DESC;

-- 20. Combined filter view: year x occupation x merchant category
SELECT transaction_year AS year,
       occupation,
       merchant_category,
       COUNT(*) AS transactions,
       ROUND(SUM(amount), 2) AS total_amount,
       ROUND(AVG(amount), 2) AS avg_transaction_value,
       ROUND(SUM(COALESCE(fee_amount, 0)), 2) AS total_fees,
       ROUND(SUM(COALESCE(tax_amount, 0)), 2) AS total_tax
FROM financial_transactions
GROUP BY transaction_year, occupation, merchant_category
ORDER BY transaction_year, total_amount DESC;

-- 21. Dynamic measure: amount, count, fees and tax by year and segment
SELECT transaction_year AS year,
       customer_segment,
       ROUND(SUM(amount), 2) AS total_amount,
       COUNT(*) AS transaction_count,
       ROUND(AVG(amount), 2) AS avg_transaction_value,
       ROUND(SUM(COALESCE(fee_amount, 0)), 2) AS total_fees,
       ROUND(SUM(COALESCE(tax_amount, 0)), 2) AS total_tax
FROM financial_transactions
GROUP BY transaction_year, customer_segment
ORDER BY transaction_year, total_amount DESC;

-- 22. Channel analysis
SELECT channel,
       COUNT(*) AS transactions,
       COUNT(DISTINCT customer_id) AS customers,
       ROUND(SUM(amount), 2) AS total_amount,
       ROUND(AVG(amount), 2) AS avg_transaction_value,
       ROUND(SUM(transaction_status = 'Success') / COUNT(*) * 100, 2) AS success_rate_pct
FROM financial_transactions
GROUP BY channel
ORDER BY total_amount DESC;

-- 23. Quarterly performance
SELECT transaction_year AS year,
       transaction_quarter AS quarter,
       COUNT(*) AS transactions,
       ROUND(SUM(amount), 2) AS total_amount,
       ROUND(AVG(amount), 2) AS avg_transaction_value
FROM financial_transactions
GROUP BY transaction_year, transaction_quarter
ORDER BY transaction_year, transaction_quarter;

-- 24. Yearly performance
SELECT transaction_year AS year,
       COUNT(*) AS transactions,
       COUNT(DISTINCT customer_id) AS customers,
       ROUND(SUM(amount), 2) AS total_amount,
       ROUND(AVG(amount), 2) AS avg_transaction_value,
       ROUND(SUM(transaction_status = 'Success') / COUNT(*) * 100, 2) AS success_rate_pct
FROM financial_transactions
GROUP BY transaction_year
ORDER BY transaction_year;

-- 25. Running (cumulative) monthly amount
WITH monthly AS (
    SELECT transaction_year AS year,
           transaction_month AS month_no,
           SUM(amount) AS total_amount
    FROM financial_transactions
    GROUP BY transaction_year, transaction_month
)
SELECT year,
       month_no,
       ROUND(total_amount, 2) AS monthly_amount,
       ROUND(SUM(total_amount) OVER (ORDER BY year, month_no), 2) AS cumulative_amount
FROM monthly
ORDER BY year, month_no;

-- 26. Segment by status
SELECT customer_segment,
       transaction_status,
       COUNT(*) AS transactions,
       ROUND(SUM(amount), 2) AS total_amount
FROM financial_transactions
GROUP BY customer_segment, transaction_status
ORDER BY customer_segment, total_amount DESC;

-- 27. Top 5 states per year
WITH state_year AS (
    SELECT transaction_year AS year,
           state,
           SUM(amount) AS total_amount
    FROM financial_transactions
    GROUP BY transaction_year, state
),
ranked AS (
    SELECT year, state, total_amount,
           ROW_NUMBER() OVER (PARTITION BY year ORDER BY total_amount DESC) AS rn
    FROM state_year
)
SELECT year, state, ROUND(total_amount, 2) AS total_amount, rn AS state_rank
FROM ranked
WHERE rn <= 5
ORDER BY year, rn;

-- 28. Top transaction type per segment
WITH seg_type AS (
    SELECT customer_segment,
           transaction_type,
           SUM(amount) AS total_amount
    FROM financial_transactions
    GROUP BY customer_segment, transaction_type
),
ranked AS (
    SELECT customer_segment, transaction_type, total_amount,
           ROW_NUMBER() OVER (PARTITION BY customer_segment ORDER BY total_amount DESC) AS rn
    FROM seg_type
)
SELECT customer_segment, transaction_type, ROUND(total_amount, 2) AS total_amount
FROM ranked
WHERE rn = 1
ORDER BY customer_segment;

-- 29. Gender by customer segment
SELECT customer_segment,
       gender,
       COUNT(*) AS transactions,
       ROUND(SUM(amount), 2) AS total_amount
FROM financial_transactions
GROUP BY customer_segment, gender
ORDER BY customer_segment, gender;

-- 30. Gender by year
SELECT transaction_year AS year,
       gender,
       ROUND(SUM(amount), 2) AS total_amount,
       COUNT(*) AS transactions
FROM financial_transactions
GROUP BY transaction_year, gender
ORDER BY transaction_year, gender;

-- 31. Age group analysis
SELECT COALESCE(age_group, 'Unknown') AS age_band,
       COUNT(DISTINCT customer_id) AS customers,
       COUNT(*) AS transactions,
       ROUND(SUM(amount), 2) AS total_amount,
       ROUND(AVG(amount), 2) AS avg_transaction_value
FROM financial_transactions
GROUP BY age_band
ORDER BY FIELD(age_band, '<=18', '19-25', '26-35', '36-45', '46-55', '56-65', '66+', 'Unknown');

-- 32. Income segment analysis
SELECT income_segment,
       COUNT(DISTINCT customer_id) AS customers,
       COUNT(*) AS transactions,
       ROUND(SUM(amount), 2) AS total_amount,
       ROUND(AVG(amount), 2) AS avg_transaction_value
FROM financial_transactions
GROUP BY income_segment
ORDER BY total_amount DESC;

-- 33. Top 10 customers by amount
SELECT customer_id,
       CONCAT(MAX(first_name), ' ', MAX(second_name)) AS customer_name,
       MAX(customer_segment) AS customer_segment,
       COUNT(*) AS transactions,
       ROUND(SUM(amount), 2) AS total_amount,
       ROUND(AVG(amount), 2) AS avg_transaction_value
FROM financial_transactions
GROUP BY customer_id
ORDER BY total_amount DESC
LIMIT 10;

-- 34. Risk category analysis
SELECT risk_category,
       COUNT(*) AS transactions,
       ROUND(SUM(amount), 2) AS total_amount,
       ROUND(AVG(risk_score), 2) AS avg_risk_score,
       SUM(is_fraud = 'Yes') AS fraud_transactions
FROM financial_transactions
GROUP BY risk_category
ORDER BY FIELD(risk_category, 'Very High', 'High', 'Medium', 'Low');

-- 35. Fraud summary
SELECT COUNT(*) AS total_transactions,
       SUM(is_fraud = 'Yes') AS fraud_transactions,
       ROUND(SUM(is_fraud = 'Yes') / COUNT(*) * 100, 2) AS fraud_rate_pct,
       ROUND(SUM(CASE WHEN is_fraud = 'Yes' THEN amount ELSE 0 END), 2) AS fraud_amount
FROM financial_transactions;

-- 36. Fraud by channel
SELECT channel,
       COUNT(*) AS transactions,
       SUM(is_fraud = 'Yes') AS fraud_transactions,
       ROUND(SUM(is_fraud = 'Yes') / COUNT(*) * 100, 2) AS fraud_rate_pct,
       ROUND(SUM(CASE WHEN is_fraud = 'Yes' THEN amount ELSE 0 END), 2) AS fraud_amount
FROM financial_transactions
GROUP BY channel
ORDER BY fraud_rate_pct DESC;

-- 37. Fees and tax by year
SELECT transaction_year AS year,
       ROUND(SUM(COALESCE(fee_amount, 0)), 2) AS total_fees,
       ROUND(AVG(COALESCE(fee_amount, 0)), 2) AS avg_fee,
       ROUND(SUM(COALESCE(tax_amount, 0)), 2) AS total_tax,
       ROUND(AVG(COALESCE(tax_amount, 0)), 2) AS avg_tax,
       ROUND(SUM(COALESCE(fee_amount, 0) + COALESCE(tax_amount, 0)), 2) AS total_charges
FROM financial_transactions
GROUP BY transaction_year
ORDER BY transaction_year;

-- 38. Fees and tax by month
SELECT transaction_year AS year,
       transaction_month AS month_no,
       transaction_month_name AS month_name,
       ROUND(SUM(COALESCE(fee_amount, 0)), 2) AS total_fees,
       ROUND(SUM(COALESCE(tax_amount, 0)), 2) AS total_tax
FROM financial_transactions
GROUP BY transaction_year, transaction_month, transaction_month_name
ORDER BY transaction_year, transaction_month;

-- 39. Gross vs net value (recalculated, because fee_clean / tax_clean / total_charges are all 0 in the data)
SELECT ROUND(SUM(amount), 2) AS gross_value,
       ROUND(SUM(COALESCE(fee_amount, 0) + COALESCE(tax_amount, 0)), 2) AS total_charges,
       ROUND(SUM(amount - COALESCE(fee_amount, 0) - COALESCE(tax_amount, 0)), 2) AS net_value
FROM financial_transactions;

-- 40. Outlier transactions (amount above mean + 3 standard deviations)
SELECT transaction_id, customer_id, transaction_date, transaction_type, channel, amount, risk_category
FROM financial_transactions
WHERE amount > (SELECT AVG(amount) + 3 * STDDEV_POP(amount) FROM financial_transactions)
ORDER BY amount DESC;

-- 41. Top 20 highest-value transactions
SELECT transaction_id, customer_id, transaction_date, transaction_type, channel, amount, transaction_status
FROM financial_transactions
ORDER BY amount DESC
LIMIT 20;

-- 42. Dashboard 2: detailed grid view (all underlying records)
SELECT transaction_id,
       transaction_date,
       transaction_year,
       transaction_month_name,
       account_id,
       customer_id,
       CONCAT(first_name, ' ', second_name) AS customer_name,
       gender,
       age,
       occupation,
       customer_segment,
       city,
       state,
       transaction_type,
       merchant_category,
       channel,
       amount,
       COALESCE(fee_amount, 0) AS fee_amount,
       COALESCE(tax_amount, 0) AS tax_amount,
       transaction_status,
       is_fraud,
       risk_score,
       risk_category
FROM financial_transactions
ORDER BY transaction_date DESC, transaction_id;

-- 43. Dashboard 2: drill-down year > month > transaction type
SELECT transaction_year AS year,
       transaction_month AS month_no,
       transaction_month_name AS month_name,
       transaction_type,
       COUNT(*) AS transactions,
       ROUND(SUM(amount), 2) AS total_amount,
       ROUND(SUM(COALESCE(fee_amount, 0)), 2) AS total_fees,
       ROUND(SUM(COALESCE(tax_amount, 0)), 2) AS total_tax
FROM financial_transactions
GROUP BY transaction_year, transaction_month, transaction_month_name, transaction_type
ORDER BY transaction_year, transaction_month, total_amount DESC;

-- 44. Dashboard 2: drill-down state > city > customer segment
SELECT state,
       city,
       customer_segment,
       COUNT(DISTINCT customer_id) AS customers,
       COUNT(*) AS transactions,
       ROUND(SUM(amount), 2) AS total_amount
FROM financial_transactions
GROUP BY state, city, customer_segment
ORDER BY state, city, total_amount DESC;

-- 45. Dashboard 2: drill-down to one customer (change the ID as needed)
SELECT transaction_id, transaction_date, transaction_type, merchant_category, channel,
       amount, fee_amount, tax_amount, transaction_status, risk_category
FROM financial_transactions
WHERE customer_id = 'C00629'
ORDER BY transaction_date DESC;

-- 46. Final management summary
SELECT COUNT(*) AS total_transactions,
       COUNT(DISTINCT customer_id) AS total_customers,
       ROUND(SUM(amount), 2) AS total_amount,
       ROUND(AVG(amount), 2) AS avg_transaction_value,
       ROUND(SUM(COALESCE(fee_amount, 0)), 2) AS total_fees,
       ROUND(SUM(COALESCE(tax_amount, 0)), 2) AS total_tax,
       ROUND(SUM(transaction_status = 'Success') / COUNT(*) * 100, 2) AS success_rate_pct,
       SUM(is_fraud = 'Yes') AS fraud_transactions,
       ROUND(AVG(risk_score), 2) AS avg_risk_score
FROM financial_transactions;