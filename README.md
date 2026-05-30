# Finance Analytics Dashboard

## Overview

Finance Analytics Dashboard is an interactive Power BI solution designed to monitor, analyze, and visualize financial transaction data. The dashboard provides real-time insights into transaction performance, customer behavior, fees, taxes, customer segments, and regional performance.

The project helps business stakeholders track key financial KPIs, identify trends, and make data-driven decisions.

---

## Business Problem

Financial organizations often struggle to:

- Track transaction growth and performance
- Monitor monthly financial trends
- Analyze transaction success rates
- Identify high-value customer segments
- Evaluate state-wise financial performance
- Measure transaction profitability
- Understand customer demographics

This dashboard centralizes financial insights into a single analytical platform.

---

## Dashboard Features

### Dashboard 1 – Executive Overview

#### KPI Cards

- Total Amount
- Total Transactions
- Average Transaction Value
- Total Fees
- Total Tax
- Year-over-Year (YoY) Growth Analysis

#### Visualizations

1. Total Amount by Month
   - Line/Area Chart
   - Monthly trend analysis

2. Total Amount by Transaction Status
   - Donut Chart
   - Success vs Failed vs Pending

3. Total Amount by Customer Segment
   - Horizontal Bar Chart
   - Retail, Premium, SME, Corporate, Wealth

4. Total Amount by State
   - Horizontal Bar Chart
   - Regional performance analysis

5. Transaction Type Analysis
   - Matrix / Heatmap
   - Amount, Fees, Tax, Transaction Count

6. Total Amount by Gender
   - Donut Chart
   - Male vs Female contribution

---

### Dashboard 2 – Transaction Details

Detailed transaction-level view including:

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

Supports drill-through and record-level analysis.

---

## Data Model

### Customers Table

Contains:

- Customer ID
- Customer Name
- Gender
- Occupation
- Customer Segment
- State

### Finance Transactions Table

Contains:

- Transaction ID
- Transaction Date
- Customer ID
- Transaction Type
- Transaction Status
- Amount
- Fee
- Tax

---

## Filters (Slicers)

The dashboard supports dynamic filtering by:

- Year
- Dynamic Measure
- Occupation
- Category

---

## Key Business Insights

- Monthly transaction trends
- Customer segment profitability
- Transaction success rate
- State-wise financial contribution
- Revenue from fees and taxes
- Gender-based participation
- YoY financial performance

---

## Technologies Used

- Power BI Desktop
- DAX
- Power Query
- SQL
- Data Modeling
- Data Visualization

---

## DAX Measures

Examples:

```DAX
Total Amount =
SUM(finance_transactions[amount])

Total Transactions =
COUNT(finance_transactions[transaction_id])

Average Transaction Value =
DIVIDE([Total Amount],[Total Transactions])

Total Fee =
SUM(finance_transactions[fee])

Total Tax =
SUM(finance_transactions[tax])
```

---

## Project Structure

```text
Finance-Analytics-Dashboard/
│
├── Dataset/
│   ├── customers.csv
│   └── finance_transactions.csv
│
├── PowerBI/
│   └── Finance_Analytics_Dashboard.pbix
│
├── Images/
│   ├── Dashboard_Overview.png
│   └── Dashboard_Transactions.png
│
├── SQL/
│   └── Finance_Analysis_Queries.sql
│
├── README.md
└── LICENSE
```

---

## Dashboard Preview

### Executive Dashboard

- KPI Monitoring
- Financial Trends
- Customer Insights
- Transaction Analysis

### Transaction Dashboard

- Detailed Records
- Drill Down Analysis
- Transaction-Level Reporting

---

## Future Enhancements

- Predictive Analytics
- Fraud Detection
- Customer Lifetime Value Analysis
- Automated Alerts
- Forecasting Models

---
## Author

### Deepak Malviya

Data Analyst | Power BI Developer | SQL Analyst

📧 Email: Deepakmalviya7604@gmail.com  
📱 Phone: +91-7989230916  
🔗 LinkedIn: https://www.linkedin.com/in/deepak102825/

Passionate about transforming raw data into meaningful business insights using Power BI, SQL, Python, and Data Analytics. Experienced in building interactive dashboards, KPI reporting systems, business intelligence solutions, and data-driven decision-making frameworks.

### Connect With Me

- LinkedIn: https://www.linkedin.com/in/deepak102825/
- Email: Deepakmalviya7604@gmail.com



<img width="1534" height="798" alt="D1" src="https://github.com/user-attachments/assets/e9d506c9-4b79-4d45-8b80-3fe731c52964" />
<img width="1537" height="795" alt="D2" src="https://github.com/user-attachments/assets/d013c146-4c0b-40bc-9a99-dcde61cbb879" />
