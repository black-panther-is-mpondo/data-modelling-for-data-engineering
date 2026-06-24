# Module 10: Dimensional Modelling

## Goal

The goal of this module is to understand how to design data models for analytics, reporting, dashboards, and business intelligence.

Dimensional modelling is built around two main table types:

```text
Fact tables
Dimension tables
````

Simple version:

```text
Fact table = what happened / what was measured
Dimension table = who, what, where, when, how
```

## What is dimensional modelling?

Dimensional modelling is a way of organising data for analysis.

It makes data easier to query, aggregate, and understand for business users.

Example banking event:

```text
A transaction happened.
Amount: R500
Date: 2026-06-24
Account: ACC123
Channel: Mobile App
Transaction type: Card Payment
Branch: Pretoria
```

The measurable event is the transaction.

So we model:

```text
fact_transaction
```

The descriptive context goes into dimensions:

```text
dim_date
dim_account
dim_channel
dim_branch
dim_transaction_type
```

## Why dimensional modelling exists

Normalised models are good for data integrity, but they are not always easy for reporting.

A normalised banking model may have:

```text
customer
account
account_holder
product
branch
account_transaction
transaction_type
channel
```

This is clean, but reporting users may need many joins.

Dimensional modelling gives users a simpler structure:

```text
fact_transaction
dim_customer
dim_account
dim_product
dim_branch
dim_channel
dim_date
```

This is easier for dashboards and analytics.

## Fact tables

A fact table stores measurements, metrics, or business events.

Examples:

```text
fact_transaction
fact_sales
fact_payment
fact_daily_account_balance
fact_loan_repayment
fact_order
```

A fact table usually contains:

```text
Foreign keys to dimensions
Measures
Business event identifiers
Audit fields sometimes
```

Banking example:

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

The most important question for a fact table is:

> What does one row represent?

This is the grain.

## Grain

Grain is the most important idea in dimensional modelling.

Examples:

```text
One row per transaction.
One row per account per day.
One row per customer per month.
One row per loan repayment.
One row per loan application.
```

Bad grain causes bad reporting.

Clear grain:

```text
fact_transaction:
One row per posted account transaction.
```

Clear grain:

```text
fact_daily_account_balance:
One row per account per day.
```

Unclear grain:

```text
fact_account_activity:
One row per account activity.
```

The word `activity` is too vague. It could mean transaction, login, fee, balance update, or account status change.

## Dimension tables

A dimension table stores descriptive information used to filter, group, and label facts.

Examples:

```text
dim_customer
dim_account
dim_product
dim_branch
dim_channel
dim_date
dim_transaction_type
```

Dimensions answer questions like:

```text
Who?
What?
Where?
When?
How?
Which type?
Which category?
```

Example:

```text
dim_customer
- customer_key
- customer_number
- age_band
- province
- customer_segment
```

Example:

```text
dim_product
- product_key
- product_code
- product_name
- product_category
```

Example:

```text
dim_channel
- channel_key
- channel_code
- channel_name
- channel_group
```

Dimensions let us slice facts.

Example questions:

```text
Transaction amount by channel
Transaction count by branch
Active customers by province
Loan balance by product
```

## Star schema

A star schema has a fact table in the middle and dimensions around it.

Example:

```text
                 dim_date
                    |
dim_product -- fact_transaction -- dim_channel
                    |
                dim_account
                    |
                dim_branch
                    |
          dim_transaction_type
```

It is called a star schema because the diagram looks like a star.

## Banking transaction star schema

Fact table:

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

This supports questions like:

```text
Total transaction amount by month
Transaction count by channel
Transaction amount by branch
Transaction volume by product
```

## Measures

A measure is a numeric value that we analyse.

Examples:

```text
transaction_amount
transaction_fee_amount
balance_amount
repayment_amount
loan_principal_amount
interest_amount
arrears_amount
transaction_count
account_count
```

Measures usually live in fact tables.

Example:

```text
fact_transaction
- transaction_amount
- transaction_fee_amount
- transaction_count
```

Dimensions describe the measures.

Example question:

```text
Total transaction amount by month and channel.
```

Here:

```text
transaction_amount = measure
month = dimension attribute
channel = dimension attribute
```

## Types of measures

Measures behave differently when aggregated.

The main types are:

```text
Additive
Semi-additive
Non-additive
```

## Additive measures

Additive measures can be summed across all dimensions.

Examples:

```text
transaction_amount
transaction_count
fee_amount
repayment_amount
```

You can sum transaction amount by:

```text
date
branch
channel
product
account
```

## Semi-additive measures

Semi-additive measures can be summed across some dimensions, but not all.

Examples:

```text
account_balance
loan_outstanding_balance
closing_balance
available_balance
```

You can sum balances across accounts for a specific day.

But you should not blindly sum balances across many days.

Example:

```text
Monday closing balance: R1,000
Tuesday closing balance: R1,200
Wednesday closing balance: R900
```

Summing those gives R3,100, which is not a meaningful account balance.

For balances over time, use:

```text
Average daily balance
End-of-month balance
Latest balance in period
```

## Non-additive measures

Non-additive measures cannot be meaningfully summed.

Examples:

```text
rate
percentage
ratio
score
margin percentage
default rate
```

For these, store numerator and denominator where possible.

Example:

```text
default_rate = defaulted_loans / total_loans
```

Better fact design:

```text
defaulted_loan_count
total_loan_count
```

Then calculate the percentage in reporting.

## Dimension attributes

Dimension attributes are descriptive fields used for filtering and grouping.

Example:

```text
dim_customer
- customer_key
- customer_number
- age_band
- province
- customer_segment
```

Attributes answer questions like:

```text
Which province?
Which age band?
Which customer segment?
Which product category?
```

## Surrogate keys in dimensions

Dimensional models often use surrogate keys.

Example:

```text
dim_customer
- customer_key
- customer_number
- age_band
- customer_segment
- effective_from_date
- effective_to_date
- is_current
```

`customer_key` is the warehouse surrogate key.

`customer_number` is the business key from the source.

Surrogate keys are important when tracking history.

Example:

```text
customer_key | customer_number | segment | effective_from | effective_to | is_current
-------------|-----------------|---------|----------------|--------------|-----------
101          | C001            | Student | 2025-01-01     | 2025-12-31   | false
205          | C001            | Premium | 2026-01-01     | null         | true
```

Same customer number, but different dimension rows.

Facts can point to the correct historical version using `customer_key`.

## Degenerate dimensions

A degenerate dimension is a business identifier stored directly in the fact table instead of a separate dimension.

Examples:

```text
transaction_reference
order_number
invoice_number
claim_number
application_reference
```

Example:

```text
fact_transaction
- transaction_key
- transaction_reference
- date_key
- account_key
- transaction_amount
```

`transaction_reference` can stay in the fact table because it is useful for tracing, but it may not need its own dimension.

## Conformed dimensions

A conformed dimension is reused across multiple fact tables.

Example:

```text
dim_date
```

can be used by:

```text
fact_transaction
fact_daily_account_balance
fact_loan_repayment
fact_loan_arrears_snapshot
```

Other common conformed dimensions:

```text
dim_customer
dim_product
dim_branch
dim_channel
```

Conformed dimensions keep reporting consistent.

For example, if `dim_branch` is shared, then transaction reports and balance reports group branches the same way.

## Banking dimensional model example

Suppose the business wants reports on:

```text
Transaction value by month
Transaction volume by channel
Transaction fees by product
Customer activity by province
Branch performance
```

A first dimensional model:

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
- transaction_fee_amount
- transaction_count
```

Dimensions:

```text
dim_date
- date_key
- full_date
- day_of_month
- month_number
- month_name
- quarter
- year

dim_account
- account_key
- account_number_masked
- open_date
- close_date

dim_product
- product_key
- product_code
- product_name
- product_category

dim_branch
- branch_key
- branch_code
- branch_name
- province

dim_channel
- channel_key
- channel_code
- channel_name
- channel_group

dim_transaction_type
- transaction_type_key
- transaction_type_code
- transaction_type_name
- transaction_category
```

## Important banking caution: joint accounts

Banking has a tricky problem.

If a transaction belongs to an account, and the account has multiple holders, which customer gets the transaction?

Example:

```text
Account ACC100 has two holders:
- Customer A
- Customer B

Transaction:
- R1,000 deposit
```

If you join transaction to both customers, you may double-count the amount.

Possible approaches:

```text
Keep fact_transaction at account grain only.
Use a bridge table between account and customer.
Allocate transaction amounts by ownership percentage.
Report only under the primary holder.
Keep account-level reporting separate from customer-level reporting.
```

Safe first design:

```text
fact_transaction
- account_key
- product_key
- branch_key
- channel_key
- transaction_amount
```

Then use a bridge:

```text
bridge_account_customer
- account_key
- customer_key
- holder_role
- allocation_percentage
- effective_from_date
- effective_to_date
```

Customer-level reporting must use a documented business rule.

## Star schema vs snowflake schema

## Star schema

Dimensions are mostly denormalised.

Example:

```text
dim_product
- product_key
- product_name
- product_category
- product_group
```

## Snowflake schema

Dimensions are normalised into subdimensions.

Example:

```text
dim_product
- product_key
- product_name
- product_category_key

dim_product_category
- product_category_key
- product_category_name
```

For BI, a star schema is usually easier.

A snowflake schema can be useful for large, shared, or hierarchical dimensions, but it adds joins.

Default recommendation:

> Start with a star schema for analytics unless there is a strong reason to snowflake.

## Common mistakes

### Mistake 1: Not defining grain first

Bad:

```text
fact_activity
```

What is one row? A transaction? Login? Balance snapshot? Fee?

Unclear grain means unreliable reporting.

### Mistake 2: Mixing facts with different grains

Bad:

```text
fact_transaction
- transaction_amount
- daily_closing_balance
```

Transaction amount is transaction-level.

Daily closing balance is account-day-level.

Better:

```text
fact_transaction
fact_daily_account_balance
```

### Mistake 3: Storing percentages only

Bad:

```text
default_rate
```

Better:

```text
defaulted_loan_count
total_loan_count
```

Then calculate the rate in reporting.

### Mistake 4: Ignoring history in dimensions

If customer segment changes, old transactions may need to report under the old segment.

That requires Slowly Changing Dimensions.

### Mistake 5: Double-counting through bridge tables

Joint accounts, households, policies, and shared products can cause duplicate facts if relationships are not handled carefully.

## Dimensional modelling checklist

Before accepting a dimensional model, ask:

```text
What business process does the fact table represent?
What is the grain of the fact table?
What are the measures?
Are the measures additive, semi-additive, or non-additive?
Which dimensions describe the fact?
Are dimensions conformed where needed?
Are historical changes handled properly?
Are there many-to-many relationships that need bridge tables?
Could any joins cause double-counting?
Can the model answer the required business questions?
```

## Key takeaways

* Facts store measurements and events.
* Dimensions store descriptive context.
* Grain controls meaning.
* Star schemas are usually best for BI.
* Measures can be additive, semi-additive, or non-additive.
* Conformed dimensions keep reporting consistent.
* Joint accounts require careful customer-level reporting rules.
* Dimensional models are designed for business analysis, not transaction processing.
