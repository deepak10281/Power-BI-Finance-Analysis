# Finance Analysis — Business Requirements

## Purpose

This analysis is built directly from the supplied raw customer and finance transaction CSV files and follows the supplied Finance Analysis Business Requirements.

The business requirements call for analysis of transaction growth, monthly transaction trends, transaction status, customer segments, states, transaction types, gender, fees, taxes and YoY performance. The dashboard is also designed around filters for Year, Dynamic Measure, Occupation and Category. The Python analysis mirrors those requirements and keeps the raw data visible before cleaning.

## Source files

- `customers(1).csv` — customer master data.
- `finance_transactions(1).csv` — transaction-level data.
- Dashboard screenshots supplied by the user are used only for reconciliation/context.

## Analysis methodology

### Important data-cleaning decisions

1. Customer column-name typo `fisrt_name` is standardized to `first_name`; `second_name` becomes `last_name`.
2. Text fields are trimmed.
3. Dates are converted to datetime.
4. Amount, fee, tax and risk score are converted to numeric.
5. `M@bile App` is standardized to `Mobile App`.
6. Missing `fee_amount` values are preserved in the original column and a separate `fee_amount_clean` field treats missing fees as zero for fee aggregation.
7. Duplicate `transaction_id` values are reduced to one row per transaction ID for the analysis-ready dataset.
8. Negative transaction amounts are **not silently removed**. They are retained and flagged so their business meaning can be investigated.
9. Every transaction customer ID is checked against the customer master.
10. The 2026 data is treated as a partial year; the main YoY comparison is therefore 2025 vs 2024.

## Raw-data profile

- Customer rows: **5,000**
- Raw transaction rows: **50,069**
- Customer duplicate rows: **0**
- Exact duplicate transaction rows: **68**
- Duplicate transaction IDs: **69**
- Missing transaction fees: **24**
- Negative amount rows: **9**

After one-row-per-transaction-ID cleaning:

- Analysis-ready transaction rows: **50,000**
- Duplicate transaction IDs remaining: **0**
- Transactions with customer IDs missing from customer master: **0**

---

# 1. KPI Analysis

## Business question

How much transaction value was processed, how many transactions occurred, what was the average transaction value, and how much fee and tax were generated?

The business requirements explicitly specify five main KPIs: Total Amount, Total Transactions, Average Transaction Value, Total Fees and Total Tax, with YoY comparison for the first two and overall performance tracking.

## Python logic

The analysis year is set to **2025**. We filter the analysis-ready transaction table to that year and calculate:

- Total Amount = sum of transaction amount
- Total Transactions = transaction count
- Average Transaction Value = average transaction amount
- Total Fees = sum of cleaned fee amount
- Total Tax = sum of tax amount

## 2025 results

| KPI | 2025 |
|---|---:|
| Total Amount | ₹137,485,828.74 |
| Total Transactions | 14,944 |
| Average Transaction Value | ₹9,200.07 |
| Total Fees | ₹216,870.56 |
| Total Tax | ₹39,041.10 |

### Interpretation

Transaction value increased while transaction count decreased slightly versus 2024. This means the average value per transaction increased, which is important when interpreting growth: higher total value was not driven by higher transaction volume alone.

---

# 2. Year-over-Year Performance

## Business question

How did financial performance change compared with the previous year?

The analysis compares 2025 with 2024 because 2026 is only a partial year in the supplied data.

| Metric | 2024 | 2025 | YoY |
|---|---:|---:|---:|
| Total Amount | ₹135,552,822.46 | ₹137,485,828.74 | 1.43% |
| Transactions | 15,029 | 14,944 | -0.57% |
| Average Transaction Value | ₹9,019.42 | ₹9,200.07 | 2.00% |
| Total Fees | ₹217,156.78 | ₹216,870.56 | -0.13% |
| Total Tax | ₹39,142.77 | ₹39,041.10 | -0.26% |

### Interpretation

- Total amount grew by **1.43%**.
- Transaction count decreased by **-0.57%**.
- Average transaction value grew by **2.00%**.
- Fees changed by **-0.13%**.
- Tax changed by **-0.26%**.

This is a more useful growth story than looking only at total amount because it separates value growth from transaction-volume growth.

![YoY total amount](visuals/07_yoy_total_amount.png)

---

# 3. Monthly Transaction Amount Trend

## Business question

Which months show higher or lower transaction activity?

The requirement specifies a line/area chart to identify seasonal spikes or drops.

### Result

The highest 2025 monthly transaction amount was **July**, at **₹12,508,617.19**.

![Monthly amount](visuals/01_total_amount_by_month.png)

### Interpretation

The monthly chart should be used to identify peaks and troughs rather than treating one month as representative of the whole year. The Python calculation preserves the chronological January–December order.

---

# 4. Transaction Status Analysis

## Business question

How is transaction value distributed between Success, Failed and Pending transactions?

The requirement specifies a donut chart.

| Status | Amount | Transactions |
|---|---:|---:|
| Success | ₹117,371,642.63 | 12,829 |
| Failed | ₹14,354,093.88 | 1,514 |
| Pending | ₹5,760,092.23 | 601 |

![Transaction status](visuals/02_total_amount_by_status.png)

### Interpretation

This view separates financial value by operational transaction status. It can be used to identify whether failed or pending transactions represent a material amount that deserves operational attention.

---

# 5. Customer Segment Contribution

## Business question

Which customer segments contribute the most transaction value?

The required categories are Retail, Premium, SME, Corporate and Wealth. The Python analysis joins transaction data to the customer master using `customer_id`.

| Customer Segment | Amount | Transactions |
|---|---:|---:|
| Retail | ₹75,681,024.33 | 8,133 |
| Premium | ₹25,638,295.37 | 2,776 |
| SME | ₹21,096,182.18 | 2,365 |
| Corporate | ₹9,055,849.88 | 1,028 |
| Wealth | ₹6,014,476.98 | 642 |

![Customer segment](visuals/03_total_amount_by_customer_segment.png)

### Interpretation

The segment ranking identifies the customer groups generating the highest financial contribution. This can support segment-level strategy and prioritization.

---

# 6. State-wise Financial Performance

## Business question

Which states generate the highest transaction amounts?

The transaction table is joined to the customer master to obtain the customer's state. The result is sorted so the largest regions are easy to identify.

| State | Amount | Transactions |
|---|---:|---:|
| Maharashtra | ₹21,806,561.30 | 2,271 |
| Karnataka | ₹15,926,476.15 | 1,757 |
| Gujarat | ₹15,376,884.51 | 1,696 |
| Tamil Nadu | ₹13,825,257.36 | 1,457 |
| Uttar Pradesh | ₹13,163,034.20 | 1,393 |
| Madhya Pradesh | ₹11,966,145.20 | 1,388 |
| Haryana | ₹7,622,756.21 | 751 |
| Kerala | ₹6,994,088.87 | 793 |
| Delhi | ₹6,812,555.66 | 797 |
| Rajasthan | ₹6,496,483.70 | 691 |
| West Bengal | ₹6,321,709.78 | 714 |
| Chandigarh | ₹5,616,731.39 | 608 |
| Telangana | ₹5,557,144.41 | 628 |

![State performance](visuals/04_total_amount_by_state.png)

### Interpretation

This analysis identifies top-performing regions and allows management to compare geographic contribution.

---

# 7. Transaction Type Analysis

## Business question

How do transaction categories perform in terms of amount, fees, tax and transaction count?

The business requirement explicitly requests a matrix/heatmap containing:

- Amount
- Fees
- Tax
- Transactions Count

The required transaction types are Bill Payment, Card Payment, Deposit, Fee Charge, Interest Credit, Investment, Loan EMI, Refund, Transfer and Withdrawal.

| Transaction Type | Amount | Fees | Tax | Transactions |
|---|---:|---:|---:|---:|
| Loan EMI | ₹39,989,086.45 | ₹64,028.92 | ₹11,525.18 | 2,771 |
| Transfer | ₹36,169,194.57 | ₹55,331.16 | ₹9,959.58 | 2,450 |
| Deposit | ₹20,293,697.30 | ₹34,465.02 | ₹6,203.67 | 1,483 |
| Investment | ₹15,054,522.23 | ₹22,901.97 | ₹4,122.27 | 1,080 |
| Card Payment | ₹8,170,484.95 | ₹13,013.47 | ₹2,342.26 | 1,603 |
| Withdrawal | ₹6,604,525.76 | ₹9,954.67 | ₹1,792.54 | 1,293 |
| Bill Payment | ₹6,446,604.92 | ₹9,726.28 | ₹1,754.19 | 1,258 |
| Interest Credit | ₹2,729,347.99 | ₹4,241.66 | ₹763.39 | 1,208 |
| Refund | ₹1,483,171.50 | ₹2,286.75 | ₹412.15 | 677 |
| Fee Charge | ₹545,193.07 | ₹920.66 | ₹165.87 | 1,121 |

![Transaction type heatmap](visuals/05_transaction_type_heatmap.png)

### Interpretation

The heatmap is normalized for visual intensity because Amount, Fees, Tax and Transaction Count have different units and scales. The values printed inside the cells remain the actual measures.

This view helps compare the financial scale and operational characteristics of each transaction type.

---

# 8. Gender-based Transaction Analysis

## Business question

What share of transaction value is contributed by Male and Female customers?

The requirement specifies a donut chart.

| Gender | Amount | Transactions |
|---|---:|---:|
| Female | ₹72,574,193.12 | 7,770 |
| Male | ₹64,911,635.62 | 7,174 |

![Gender analysis](visuals/06_total_amount_by_gender.png)

### Interpretation

This analysis describes transaction-value participation by gender. It is a descriptive demographic view and should not be interpreted as a causal explanation for customer behavior.

---

# 9. Dashboard Filter Logic in Python

The dashboard provides filters for Year, Dynamic Measure, Occupation and Category.

The Python notebook demonstrates the same concept using parameters:

```python
selected_year = 2025
selected_occupation = "All"
selected_category = "All"
selected_measure = "amount"
```

Here, `Category` is mapped to the available `merchant_category` field in the raw transaction data.

A reusable filter function applies these selections before calculating KPIs or chart data. This allows the same analysis to be rerun for different business slices.

---

# 10. Detailed Transaction-Level View

The second dashboard is intended to provide a detailed grid and drill-down to underlying records.

The Python notebook therefore creates a joined transaction-level analytical table containing:

- Transaction ID
- Transaction Date
- Customer Name
- Transaction Type
- Gender
- Customer Segment
- State
- Amount
- Fee
- Tax
- Status
- Channel
- Merchant Category
- Risk Score
- Fraud Flag

Example:

```python
detail_view = (
    analysis_tx
    .merge(customers_clean, on="customer_id", how="left")
)
```

This table can be filtered by year, occupation, category, transaction type, state, segment and status.

---

# 11. Data Quality and Reconciliation

## Missing fees

There are **24** raw transactions with missing `fee_amount`.

The analysis does not overwrite the raw field. Instead:

```python
fee_amount_clean = fee_amount.fillna(0)
```

This assumption should be confirmed with the data/business owner. If a missing fee means "unknown" rather than "zero", the fee KPI should be revised.

## Duplicate transaction IDs

There are **69** duplicated transaction IDs in the raw file. The analysis-ready dataset keeps the first record for each `transaction_id` so that transaction count and amount are not double-counted.

## Negative amounts

There are **9** negative amount rows. They are retained and flagged instead of being deleted because the business requirements do not specify that negative transactions should be excluded. They may represent reversals/refunds or another business event.

## Dashboard reconciliation

The supplied dashboard screenshot shows a 2025 total amount of approximately **₹137.53M**, while the analysis-ready Python dataset gives **₹137,485,828.74**.

The difference is approximately **₹40,015.40**.

The dashboard total tax shown in the screenshot is **₹39,041.10**, which matches the analysis-ready Python calculation exactly. The difference in Total Amount therefore needs to be investigated before the Python and Power BI numbers are presented as fully reconciled.

Possible causes to investigate include the dashboard's duplicate-handling logic, filters, calculated columns/measures, or treatment of special/negative transactions. No assumption is made here about which system is correct.

---

# 12. Business Requirement Coverage

| Business Requirement | Python Analysis |
|---|---|
| Overall transaction growth | KPI + YoY |
| Monthly transaction trends | Monthly amount line/area chart |
| Successful vs failed transactions | Status donut |
| Customer segment contribution | Segment horizontal bar |
| State-wise performance | State horizontal bar |
| Transaction type profitability/performance | Transaction type matrix/heatmap |
| Gender-based customer analysis | Gender donut |
| YoY performance | 2024 vs 2025 KPI comparison + line chart |
| Year filter | Parameterized filter |
| Dynamic Measure | Parameterized metric selection |
| Occupation filter | Customer-master filter |
| Category filter | Merchant-category filter |
| Detailed records | Joined transaction-level detail view |

## Final business conclusions

Based on the analysis-ready 2025 dataset:

1. Transaction amount increased year over year while transaction count decreased slightly.
2. Average transaction value increased, indicating that value growth was supported by larger average transactions.
3. Monthly transaction amounts show clear variation across the year.
4. Customer segment contribution is concentrated in the leading segments rather than being evenly distributed.
5. State-level contribution varies materially, highlighting different regional performance.
6. Transaction types differ substantially in amount, fee, tax and transaction volume.
7. Gender analysis shows the transaction-value mix between male and female customers.
8. Data-quality issues such as duplicate transaction IDs, missing fees and negative amounts should be documented as part of the analytical process.
9. Python and Power BI should be reconciled using the same duplicate, missing-fee and transaction-inclusion rules before final reporting.
