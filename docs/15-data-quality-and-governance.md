# Module 15: Data Quality and Governance

## Goal

The goal of this module is to understand how data quality and governance support trustworthy data models.

A data model is not only about tables and relationships.

A good model should also answer:

```text
Can users trust this data?
Who owns this data?
What rules protect this data?
How do we know when something is wrong?
````

## What is data quality?

Data quality means the data is fit for its intended use.

Good data should be:

* accurate
* complete
* consistent
* valid
* unique where required
* timely
* traceable

Bad data leads to bad decisions.

In data engineering, quality checks should not be an afterthought. They should be designed into the model and pipeline.

## What is data governance?

Data governance is the set of rules, responsibilities, and processes used to manage data properly.

It includes:

* data ownership
* data definitions
* access control
* privacy
* lineage
* documentation
* quality rules
* compliance
* retention rules

Data governance helps people use data safely and consistently.

## Why quality and governance matter

Imagine a banking report shows:

```text
Total active customers: 1,200,000
```

But nobody knows:

```text
What counts as active?
Which source system was used?
Were duplicate customers removed?
Are closed accounts excluded?
Is the report using current or historical customer segment?
When was the data last loaded?
```

The number may be technically correct according to the query, but not trustworthy.

Good governance makes definitions clear.

Good data quality checks make errors visible.

## Data quality dimensions

Common data quality dimensions include:

```text
Completeness
Validity
Uniqueness
Consistency
Accuracy
Timeliness
Referential integrity
```

## Completeness

Completeness checks whether required data is present.

Example:

```text
Every transaction must have an account_id.
Every transaction must have an amount.
Every account must have an account_number.
Every customer must have a customer_number.
```

Example SQL check:

```sql
SELECT COUNT(*) AS missing_account_id_count
FROM account_transaction
WHERE account_id IS NULL;
```

If this returns more than zero, something is wrong.

## Validity

Validity checks whether values follow allowed formats or rules.

Examples:

```text
transaction_amount must not be zero.
currency_code must be 3 characters.
customer_type must be INDIVIDUAL or BUSINESS.
account_status must be ACTIVE, CLOSED, or SUSPENDED.
```

Example SQL check:

```sql
SELECT account_status, COUNT(*) AS row_count
FROM account
GROUP BY account_status;
```

This helps detect unexpected status values.

## Uniqueness

Uniqueness checks whether values that should be unique are actually unique.

Examples:

```text
customer_number must be unique.
account_number must be unique.
transaction_reference must be unique.
branch_code must be unique.
product_code must be unique.
```

Example SQL check:

```sql
SELECT
    account_number,
    COUNT(*) AS row_count
FROM account
GROUP BY account_number
HAVING COUNT(*) > 1;
```

If this returns rows, duplicate account numbers exist.

## Consistency

Consistency checks whether related values agree with each other.

Examples:

```text
close_date should not be before open_date.
effective_to_date should not be before effective_from_date.
A closed account should have a close_date.
An active account should not have a close_date.
```

Example SQL check:

```sql
SELECT *
FROM account
WHERE close_date IS NOT NULL
  AND close_date < open_date;
```

## Accuracy

Accuracy checks whether values reflect the real-world truth.

This is harder than other checks because the database may not know the real-world truth by itself.

Examples:

```text
Customer ID number matches official validation rules.
Branch code matches the official branch reference list.
Transaction amount matches source system totals.
```

Accuracy often requires comparison to trusted sources or reconciliation reports.

## Timeliness

Timeliness checks whether data arrives and updates when expected.

Examples:

```text
Daily transactions should be loaded by 07:00.
Month-end balance data should arrive by the first business day of the next month.
Customer updates should be available within one day.
```

Example check:

```sql
SELECT MAX(loaded_at) AS latest_loaded_at
FROM account_transaction;
```

If the latest load is too old, the pipeline may have failed.

## Referential integrity

Referential integrity checks whether relationships are valid.

Examples:

```text
Every transaction account_id must exist in account.
Every account product_id must exist in product.
Every account branch_id must exist in branch.
Every account_holder customer_id must exist in customer.
```

Example SQL check:

```sql
SELECT t.*
FROM account_transaction t
LEFT JOIN account a
    ON t.account_id = a.account_id
WHERE a.account_id IS NULL;
```

If this returns rows, there are orphan transactions.

## Banking data quality rules

Useful quality rules for a banking model:

```text
customer.customer_number must not be null.
customer.customer_number must be unique.
account.account_number must not be null.
account.account_number must be unique.
account.product_id must exist in product.
account.branch_id must exist in branch.
account_holder.customer_id must exist in customer.
account_holder.account_id must exist in account.
account_holder.start_date must not be after end_date.
account_transaction.account_id must exist in account.
account_transaction.transaction_reference must be unique.
account_transaction.amount must not be zero.
daily_account_balance must be unique by account_id and balance_date.
daily_account_balance.balance_date must not be in the future.
```

## Governance: data ownership

Every important data domain should have an owner.

Examples:

```text
Customer data owner
Account data owner
Transaction data owner
Product data owner
Branch data owner
Risk data owner
Finance data owner
```

A data owner helps answer:

```text
What does this field mean?
Which values are allowed?
Who may access this data?
Which source is trusted?
What should happen when data is wrong?
```

Without ownership, data problems get passed around without resolution.

## Governance: data definitions

Important fields need clear definitions.

Example:

```text
active_customer
```

Possible meanings:

```text
Customer with at least one active account.
Customer with at least one transaction in the last 90 days.
Customer with a current customer profile.
Customer not marked as deceased or closed.
```

Those are different definitions.

A governed model must define the meaning.

Better:

```text
Active customer:
A customer with at least one account where account_status = 'ACTIVE' as at the reporting date.
```

## Governance: business glossary

A business glossary defines important business terms.

Examples:

```text
Customer
Account
Active account
Dormant account
Transaction
Posted transaction
Available balance
Closing balance
Customer segment
Product category
```

For each term, document:

```text
Definition
Owner
Source system
Calculation rule
Allowed values
Refresh frequency
Related tables
```

## Governance: lineage

Lineage shows where data came from and how it changed.

Example:

```text
core_banking.transactions
    ↓
bronze_core_banking_transactions
    ↓
silver_account_transaction
    ↓
gold_fact_transaction
    ↓
Power BI transaction dashboard
```

Lineage helps answer:

```text
Where did this number come from?
Which pipeline created it?
Which source table was used?
Which transformation changed it?
What reports are affected if this field changes?
```

## Governance: access control

Not every user should see every field.

Sensitive fields include:

```text
national_id
passport_number
phone_number
email
physical_address
date_of_birth
salary
risk_score
```

Access control can happen at different levels:

```text
Database permissions
Schema permissions
Table permissions
Column masking
Row-level security
BI tool permissions
```

Example:

```text
A BI analyst may see customer segment and province.
A compliance officer may see national ID.
A general dashboard user should not see national ID.
```

## Governance: privacy

Privacy means personal information must be handled carefully.

For banking, customer data is sensitive.

Common privacy actions:

```text
Mask identifiers
Limit access to personal data
Remove unnecessary fields from gold models
Use aggregated data where possible
Keep audit logs of access
Define retention periods
```

Example:

Instead of exposing:

```text
national_id
```

to a dashboard, expose:

```text
age_band
province
customer_segment
```

where possible.

## Governance: retention

Retention defines how long data is kept.

Examples:

```text
Raw source files kept for 7 years.
Audit logs kept for 5 years.
Temporary staging tables deleted after 30 days.
Dashboard extracts refreshed monthly.
```

Retention rules depend on business, legal, and compliance requirements.

## Quality checks by layer

## Bronze layer checks

Bronze checks confirm that data arrived.

Examples:

```text
File exists.
File is not empty.
Schema is readable.
Row count is captured.
Source system is recorded.
Ingestion timestamp is recorded.
```

## Silver layer checks

Silver checks confirm that data is cleaned and usable.

Examples:

```text
Primary keys are present.
Business keys are unique where expected.
Data types are correct.
Required fields are not null.
Invalid codes are flagged.
Duplicate records are handled.
Foreign key relationships are valid.
```

## Gold layer checks

Gold checks confirm that business outputs are trustworthy.

Examples:

```text
Fact table grain is respected.
Aggregations reconcile to silver.
Dimensions have current records.
SCD effective dates do not overlap.
Measures are calculated correctly.
Business definitions are applied consistently.
```

## Reconciliation

Reconciliation compares data between systems or layers.

Example:

```text
Source transaction count = 1,000,000
Silver transaction count = 1,000,000
Gold transaction count = 1,000,000
```

If gold has fewer records, there must be a clear reason.

Example SQL:

```sql
SELECT
    COUNT(*) AS transaction_count,
    SUM(amount) AS total_amount
FROM silver_account_transaction;
```

Compare with:

```sql
SELECT
    COUNT(*) AS transaction_count,
    SUM(transaction_amount) AS total_amount
FROM gold_fact_transaction;
```

## Data quality table

A mature platform may store quality results.

Example:

```text
data_quality_check_result
- check_result_id
- check_name
- table_name
- check_type
- check_status
- expected_value
- actual_value
- failed_row_count
- checked_at
- pipeline_run_id
```

This allows monitoring over time.

## Common mistakes

### Mistake 1: Only checking if the pipeline ran

A pipeline can run successfully and still produce bad data.

You need data checks, not only job-status checks.

### Mistake 2: No business definitions

If nobody defines “active customer”, reports will disagree.

### Mistake 3: Exposing sensitive fields unnecessarily

Do not expose personal identifiers to users who do not need them.

### Mistake 4: No lineage

Without lineage, debugging becomes guesswork.

### Mistake 5: Quality checks only at the end

Quality should be checked at bronze, silver, and gold layers.

## Data quality checklist

Before trusting a model, ask:

```text
Are required fields complete?
Are business keys unique?
Are valid values enforced?
Are relationships valid?
Are dates consistent?
Are duplicate records handled?
Are totals reconciled to the source?
Are quality checks automated?
Are failures visible?
Is there an owner for each important data domain?
Are definitions documented?
Is sensitive data protected?
Is lineage clear?
```

## Key takeaways

* Data quality means data is fit for use.
* Governance defines how data is owned, defined, protected, and managed.
* Quality checks should exist across bronze, silver, and gold layers.
* Important business terms need clear definitions.
* Lineage helps explain where data came from.
* Access control and privacy are part of good modelling.
* A model is not trustworthy just because the SQL runs.
