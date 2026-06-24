# Module 09: OLTP vs OLAP Modelling

## Goal

The goal of this module is to understand why operational systems and analytical systems are modelled differently.

A model that is good for running the business is not always good for analysing the business.

## Core difference

There are two major ways data systems are used:

```text
OLTP = Online Transaction Processing
OLAP = Online Analytical Processing
````

Simple version:

```text
OLTP runs the business.
OLAP analyses the business.
```

## Banking examples

OLTP examples:

```text
Open an account
Capture a transaction
Update customer details
Process a loan repayment
Change account status
```

OLAP examples:

```text
Total deposits by month
Active customers by province
Loan arrears by risk band
Revenue by product
Transaction trends by channel
Average balances by branch
```

## OLTP modelling

OLTP systems are operational systems.

They support day-to-day business actions.

Examples:

```text
Banking app
Core banking system
Loan origination system
Payment processing system
CRM system
E-commerce checkout system
School registration system
```

OLTP systems care about:

```text
Fast inserts
Fast updates
Data integrity
Preventing duplicates
Accurate current state
Transaction safety
```

For example, when a customer transfers money, the system must safely record:

```text
Money leaves account A.
Money enters account B.
Balances update correctly.
The transaction either fully succeeds or fully fails.
```

That is OLTP thinking.

## OLTP model characteristics

OLTP models are usually:

```text
Highly normalised
Write-optimised
Current-state focused
Strict with constraints
Designed around business processes
Good for many small operations
```

Example OLTP-style banking model:

```text
customer
account
account_holder
product
branch
account_transaction
transaction_type
channel
daily_account_balance
```

This model avoids unnecessary duplication.

Customer name is stored in:

```text
customer
```

not repeated in every transaction row.

Branch name is stored in:

```text
branch
```

not repeated in every account or transaction row.

This protects integrity.

## Example OLTP query

Question:

> Show the latest details of account ACC123.

```sql
SELECT
    a.account_number,
    a.open_date,
    a.close_date,
    p.product_name,
    b.branch_name
FROM account a
JOIN product p
    ON a.product_id = p.product_id
JOIN branch b
    ON a.branch_id = b.branch_id
WHERE a.account_number = 'ACC123';
```

This is a small targeted lookup.

That is OLTP-friendly.

## OLAP modelling

OLAP systems are analytical systems.

They support reporting, dashboards, business intelligence, data science, and decision-making.

Examples:

```text
Data warehouse
Data mart
Lakehouse gold layer
Power BI semantic model
Tableau reporting layer
Executive dashboard dataset
Risk analytics warehouse
```

OLAP systems care about:

```text
Fast reads
Historical analysis
Aggregations
Trends
Slicing and dicing
Business metrics
Large scans
```

## OLAP model characteristics

OLAP models are usually:

```text
Read-optimised
Historical
Often denormalised
Designed around business questions
Designed for aggregations
Often dimensional
```

Instead of many highly normalised tables, OLAP often uses:

```text
Fact tables
Dimension tables
```

Example:

```text
fact_transaction
fact_daily_account_balance

dim_customer
dim_account
dim_product
dim_branch
dim_channel
dim_date
dim_transaction_type
```

## OLTP vs OLAP banking example

Suppose we want to model account transactions.

### OLTP model

```text
account_transaction
- transaction_id
- account_id
- transaction_type_id
- channel_id
- transaction_datetime
- posted_date
- amount

account
- account_id
- account_number
- product_id
- branch_id

product
- product_id
- product_name

branch
- branch_id
- branch_name

transaction_type
- transaction_type_id
- transaction_type_name
```

This is clean and normalised.

It is good for operational correctness.

### OLAP model

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

Dimensions:

```text
dim_date
dim_account
dim_product
dim_branch
dim_channel
dim_transaction_type
```

This is easier for reporting.

A BI user can ask:

```text
Total transaction amount by branch and month
```

without needing to understand the full operational schema.

## Main modelling difference

In OLTP, we ask:

```text
How do we store and update the business process correctly?
```

In OLAP, we ask:

```text
How do we make business analysis easy, fast, and trustworthy?
```

OLTP is process-first.

OLAP is question-first.

## Normalisation vs denormalisation

### OLTP usually normalises

Example:

```text
customer
account
branch
transaction_type
account_transaction
```

Why?

Because we want:

```text
No duplicated customer details
No duplicated branch details
Safe updates
Clear relationships
Data integrity
```

### OLAP often denormalises

Example:

```text
dim_customer
- customer_key
- customer_number
- age_band
- province
- segment
```

The dimension may contain fields from multiple operational tables because reporting users need a convenient view.

This is not automatically bad duplication.

Senior distinction:

> Duplication in OLTP is usually a design smell. Duplication in OLAP can be intentional if it improves reporting and is controlled by pipelines.

## Grain in OLTP vs OLAP

Grain matters in both worlds.

### OLTP grain examples

```text
customer:
One row per customer.

account:
One row per account.

account_transaction:
One row per transaction.
```

### OLAP grain examples

```text
fact_transaction:
One row per transaction.

fact_daily_account_balance:
One row per account per day.

fact_monthly_customer_summary:
One row per customer per month.

fact_loan_arrears_snapshot:
One row per loan account per snapshot date.
```

In OLAP, grain is especially important because wrong grain causes wrong reporting totals.

## Banking example: transaction vs balance

A transaction is an event.

Examples:

```text
A deposit happened.
A withdrawal happened.
A card payment happened.
A transfer happened.
```

So transaction fact grain could be:

```text
One row per transaction.
```

A balance is a state at a point in time.

Examples:

```text
Account balance at end of day.
Account balance at end of month.
```

So balance fact grain could be:

```text
One row per account per day.
```

Do not mix these into one unclear table.

Bad table:

```text
account_transaction_balance
- account_id
- transaction_id
- transaction_amount
- daily_closing_balance
```

This mixes transaction grain and daily balance grain.

Better:

```text
fact_transaction
fact_daily_account_balance
```

## Example OLAP query

Question:

> What is total transaction value by month and channel?

```sql
SELECT
    d.year,
    d.month_name,
    c.channel_name,
    SUM(f.transaction_amount) AS total_transaction_amount
FROM fact_transaction f
JOIN dim_date d
    ON f.date_key = d.date_key
JOIN dim_channel c
    ON f.channel_key = c.channel_key
GROUP BY
    d.year,
    d.month_name,
    c.channel_name;
```

Question:

> What is average daily closing balance by product?

```sql
SELECT
    d.month_name,
    p.product_name,
    AVG(f.closing_balance) AS avg_closing_balance
FROM fact_daily_account_balance f
JOIN dim_date d
    ON f.date_key = d.date_key
JOIN dim_product p
    ON f.product_key = p.product_key
GROUP BY
    d.month_name,
    p.product_name;
```

These queries are business-friendly. That is the point of OLAP modelling.

## OLTP to OLAP flow

In data engineering, data often moves like this:

```text
Source OLTP systems
        ↓
Raw / Bronze layer
        ↓
Cleaned / Silver layer
        ↓
Curated / Gold OLAP model
        ↓
Dashboards / reports / ML
```

Banking example:

```text
Core banking account_transaction
        ↓
bronze_core_banking_transaction
        ↓
silver_account_transaction
        ↓
fact_transaction
        ↓
Power BI dashboard
```

## Common mistakes

### Mistake 1: Using OLTP models directly for reporting

This can create messy BI.

Users need to join too many tables and may join incorrectly.

Result:

```text
Wrong totals
Slow dashboards
Confusing relationships
Duplicated metrics
```

### Mistake 2: Using one giant flat table for everything

This may look easy at first, but it becomes painful when the business grows.

Especially if it mixes:

```text
Customer fields
Account fields
Transaction fields
Balance fields
Loan fields
Branch fields
```

### Mistake 3: Mixing event and snapshot data

Bad:

```text
transaction_amount
closing_balance
monthly_average_balance
```

all in one unclear fact table.

These belong to different grains.

### Mistake 4: Thinking denormalisation is always bad

Denormalisation is bad when accidental.

It can be good when intentional, documented, and pipeline-controlled.

## How to decide: OLTP or OLAP?

Use OLTP-style modelling when the goal is:

```text
Capturing transactions
Updating records
Running operations
Maintaining current state
Preventing duplicates
Protecting data integrity
```

Use OLAP-style modelling when the goal is:

```text
Reporting
Dashboards
Trend analysis
Aggregations
Historical analysis
Business metrics
Data science features
```

## Key takeaways

* OLTP runs the business.
* OLAP analyses the business.
* OLTP models are usually normalised, write-optimised, and process-focused.
* OLAP models are usually read-optimised, historical, and analytics-focused.
* A good OLTP model can be bad for reporting.
* A good OLAP model can be bad for transaction processing.
* The purpose of the model decides the modelling style.