# 05: Analytics Star Schema

## Purpose

This document defines the analytics model for the banking capstone project.

The goal is to convert the operational-style banking model into a reporting-friendly dimensional model.

This model is designed for:

```text
Dashboards
Business intelligence
Aggregations
Trend analysis
Customer and account reporting
````

## Why a star schema?

The logical and physical models are good for data integrity.

But reporting users usually need something easier to query.

A star schema makes analytics simpler by organising data into:

```text
Fact tables
Dimension tables
```

Simple rule:

```text
Fact tables store events or measurements.
Dimension tables store descriptive context.
```

## Main analytics questions

The star schema should support questions such as:

```text
What is total transaction value by month?
What is transaction volume by channel?
Which products have the highest transaction value?
Which branches manage the highest balances?
What are daily balances by product?
How many accounts are active by status?
How do customer segments perform over time?
```

## Fact tables

The analytics model contains two main fact tables:

```text
fact_transaction
fact_daily_account_balance
```

## Dimension tables

The analytics model contains these dimensions:

```text
dim_date
dim_customer
dim_account
dim_product
dim_branch
dim_channel
dim_transaction_type
dim_account_status
dim_customer_segment
```

For joint account reporting, the model may also use:

```text
bridge_account_customer
```

## Fact table 1: fact_transaction

### Purpose

Stores posted account transactions for reporting.

### Grain

```text
One row per posted account transaction.
```

### Columns

```text
fact_transaction
- transaction_key
- transaction_reference
- date_key
- account_key
- product_key
- branch_key
- channel_key
- transaction_type_key
- transaction_amount
- transaction_count
```

### Measures

```text
transaction_amount
transaction_count
```

`transaction_amount` is additive.

`transaction_count` is additive.

### Notes

Transactions are kept at account level.

Customer-level reporting must be handled carefully because joint accounts can cause double-counting.

## Fact table 2: fact_daily_account_balance

### Purpose

Stores daily balance snapshots for accounts.

### Grain

```text
One row per account per day.
```

### Columns

```text
fact_daily_account_balance
- date_key
- account_key
- product_key
- branch_key
- account_status_key
- opening_balance
- closing_balance
- available_balance
- account_count
```

### Measures

```text
opening_balance
closing_balance
available_balance
account_count
```

Balances are semi-additive.

They can be summed across accounts for a specific date, but they should not be blindly summed across many dates.

For time-based reporting, use:

```text
Average daily balance
End-of-month balance
Latest balance in selected period
```

## Dimension: dim_date

### Purpose

Stores calendar attributes used for time-based reporting.

### Grain

```text
One row per calendar date.
```

### Columns

```text
dim_date
- date_key
- full_date
- day_of_month
- day_name
- week_number
- month_number
- month_name
- quarter_number
- year
- is_weekend
```

### Example questions

```text
Transaction value by month
Balances by quarter
Account activity by year
```

## Dimension: dim_customer

### Purpose

Stores customer reporting attributes.

### Grain

```text
One row per customer version.
```

This dimension may use Slowly Changing Dimension Type 2 if customer segment or risk attributes need history.

### Columns

```text
dim_customer
- customer_key
- customer_number
- customer_type
- age_band
- province
- customer_segment
- effective_from_date
- effective_to_date
- is_current
```

### Notes

Sensitive fields such as national ID and passport number should usually not be exposed in a general reporting dimension.

Instead, reporting should use safer attributes such as:

```text
age_band
province
customer_segment
customer_type
```

## Dimension: dim_account

### Purpose

Stores account reporting attributes.

### Grain

```text
One row per account version.
```

This dimension may use Slowly Changing Dimension Type 2 if account status or important account attributes need history.

### Columns

```text
dim_account
- account_key
- account_number_masked
- open_date
- close_date
- account_status
- effective_from_date
- effective_to_date
- is_current
```

### Notes

Account numbers may be masked for reporting depending on privacy and access requirements.

## Dimension: dim_product

### Purpose

Stores product attributes.

### Grain

```text
One row per product.
```

### Columns

```text
dim_product
- product_key
- product_code
- product_name
- product_category
```

### Example questions

```text
Transaction value by product
Balance by product category
Account count by product
```

## Dimension: dim_branch

### Purpose

Stores branch attributes.

### Grain

```text
One row per branch.
```

### Columns

```text
dim_branch
- branch_key
- branch_code
- branch_name
- province
- city
```

### Example questions

```text
Account count by branch
Balances by province
Transaction value by branch
```

## Dimension: dim_channel

### Purpose

Stores transaction channel attributes.

### Grain

```text
One row per channel.
```

### Columns

```text
dim_channel
- channel_key
- channel_code
- channel_name
- channel_group
```

### Example values

```text
ATM
Branch
Mobile App
Internet Banking
Card
USSD
Call Centre
```

## Dimension: dim_transaction_type

### Purpose

Stores transaction type attributes.

### Grain

```text
One row per transaction type.
```

### Columns

```text
dim_transaction_type
- transaction_type_key
- transaction_type_code
- transaction_type_name
- transaction_category
```

### Example values

```text
Deposit
Withdrawal
Transfer
Card Payment
Debit Order
Fee
Interest
```

## Dimension: dim_account_status

### Purpose

Stores account status values for reporting.

### Grain

```text
One row per account status.
```

### Columns

```text
dim_account_status
- account_status_key
- account_status_code
- account_status_name
```

## Dimension: dim_customer_segment

### Purpose

Stores customer segment values for reporting.

### Grain

```text
One row per customer segment.
```

### Columns

```text
dim_customer_segment
- customer_segment_key
- customer_segment_code
- customer_segment_name
```

## Bridge: bridge_account_customer

### Purpose

Supports customer-level reporting for accounts that may have multiple holders.

### Grain

```text
One row per account-customer relationship for a period of time.
```

### Columns

```text
bridge_account_customer
- account_key
- customer_key
- holder_role
- allocation_percentage
- effective_from_date
- effective_to_date
- is_current
```

## Why the bridge matters

Transactions belong to accounts.

But customers and accounts have a many-to-many relationship.

Example:

```text
Account ACC100 has two holders.
Transaction T001 has amount R1,000.
```

If the transaction is joined to both holders, the amount can be double-counted.

The bridge table should be used with a clear allocation rule.

Possible rules:

```text
Assign transaction to the primary holder only.
Allocate equally across holders.
Allocate by ownership percentage.
Report only at account level.
```

This model does not hide the issue. It makes the business rule explicit.

## Star schema diagram

```text
                         dim_date
                            |
dim_product ---- fact_transaction ---- dim_channel
      |                     |
      |                     |
      |                 dim_account
      |                     |
      |                 dim_branch
      |
dim_transaction_type


dim_date
   |
fact_daily_account_balance
   |
dim_account
   |
dim_product
   |
dim_branch
   |
dim_account_status
```

For customer-level reporting:

```text
fact_transaction
      |
  dim_account
      |
bridge_account_customer
      |
 dim_customer
```

## Example query: transaction value by month and channel

```sql
SELECT
    d.year,
    d.month_number,
    d.month_name,
    c.channel_name,
    SUM(f.transaction_amount) AS total_transaction_amount,
    SUM(f.transaction_count) AS transaction_count
FROM fact_transaction f
JOIN dim_date d
    ON f.date_key = d.date_key
JOIN dim_channel c
    ON f.channel_key = c.channel_key
GROUP BY
    d.year,
    d.month_number,
    d.month_name,
    c.channel_name
ORDER BY
    d.year,
    d.month_number,
    c.channel_name;
```

## Example query: daily closing balance by product

```sql
SELECT
    d.full_date,
    p.product_name,
    SUM(f.closing_balance) AS total_closing_balance
FROM fact_daily_account_balance f
JOIN dim_date d
    ON f.date_key = d.date_key
JOIN dim_product p
    ON f.product_key = p.product_key
GROUP BY
    d.full_date,
    p.product_name
ORDER BY
    d.full_date,
    p.product_name;
```

## Example query: average daily balance by branch

```sql
SELECT
    d.year,
    d.month_number,
    b.branch_name,
    AVG(f.closing_balance) AS average_daily_closing_balance
FROM fact_daily_account_balance f
JOIN dim_date d
    ON f.date_key = d.date_key
JOIN dim_branch b
    ON f.branch_key = b.branch_key
GROUP BY
    d.year,
    d.month_number,
    b.branch_name
ORDER BY
    d.year,
    d.month_number,
    b.branch_name;
```

## Example query: customer-level allocated transaction value

This example assumes `allocation_percentage` is stored as a percentage from 0 to 100.

```sql
SELECT
    c.customer_segment,
    SUM(f.transaction_amount * b.allocation_percentage / 100.0) AS allocated_transaction_amount
FROM fact_transaction f
JOIN bridge_account_customer b
    ON f.account_key = b.account_key
JOIN dim_customer c
    ON b.customer_key = c.customer_key
GROUP BY
    c.customer_segment;
```

This avoids simple double-counting only if the allocation rules are correctly maintained.

## Measure behaviour

| Measure            | Fact table                 | Type          | Notes                             |
| ------------------ | -------------------------- | ------------- | --------------------------------- |
| transaction_amount | fact_transaction           | Additive      | Can be summed across dimensions   |
| transaction_count  | fact_transaction           | Additive      | Usually set to 1 per transaction  |
| opening_balance    | fact_daily_account_balance | Semi-additive | Do not blindly sum across dates   |
| closing_balance    | fact_daily_account_balance | Semi-additive | Use latest, month-end, or average |
| available_balance  | fact_daily_account_balance | Semi-additive | Use carefully across time         |
| account_count      | fact_daily_account_balance | Semi-additive | Usually useful by date            |

## Design decisions

## Decision 1: Transactions stay at account grain

Transactions are stored by account, not directly by customer.

Reason:

```text
Joint accounts can have multiple customers.
Direct customer-level transaction facts can cause double-counting.
```

## Decision 2: Balances are separate from transactions

Transactions and balances have different grains.

```text
Transaction = one row per event.
Balance = one row per account per day.
```

So they use different fact tables.

## Decision 3: Date is a conformed dimension

`dim_date` is shared by both fact tables.

This keeps time-based reporting consistent.

## Decision 4: Product and branch are included in facts

Although product and branch can be reached through account, including their keys in facts can simplify reporting and improve performance.

This is acceptable in analytics models when managed consistently.

## Common mistakes avoided

### Mistake 1: Mixing transaction and balance facts

This model separates:

```text
fact_transaction
fact_daily_account_balance
```

### Mistake 2: Ignoring joint accounts

This model includes:

```text
bridge_account_customer
```

to support customer-level reporting safely.

### Mistake 3: Summing balances across time

This model documents that balances are semi-additive.

### Mistake 4: Exposing sensitive identifiers

This model recommends masking account numbers and excluding sensitive customer identifiers from general reporting dimensions.

## Star schema checklist

Before using the analytics model, check:

```text
Is the grain of each fact table clear?
Are facts separated by grain?
Are measures additive, semi-additive, or non-additive?
Are dimensions clear and reusable?
Is dim_date conformed?
Are joint account reporting rules documented?
Can bridge joins cause double-counting?
Are sensitive fields protected?
Can the model answer the main business questions?
```

## Key takeaway

The analytics model is designed for reporting, not transaction processing.

The most important choices are:

```text
Use fact_transaction for transaction events.
Use fact_daily_account_balance for balance snapshots.
Use dimensions for business context.
Use a bridge table for account-customer reporting.
Document semi-additive balances.
Avoid double-counting joint accounts.
```
