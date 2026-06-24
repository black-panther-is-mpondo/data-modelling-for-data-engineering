# 06: Data Quality Rules

## Purpose

This document defines data quality rules for the banking capstone model.

The goal is to make sure the model is not only structurally correct, but also trustworthy.

Good data quality rules help detect:

```text
Missing values
Duplicate records
Invalid codes
Broken relationships
Incorrect date ranges
Wrong grain
Historical overlaps
Double-counting risks
````

## Why data quality matters

A data model can have good tables and still produce bad reporting if the data inside the tables is poor.

Examples of problems:

```text
Duplicate account numbers
Transactions without accounts
Balances without balance dates
Account close dates before open dates
Overlapping account status history
Overlapping customer segment history
Invalid transaction amounts
Invalid holder roles
```

The rules below protect the model from these problems.

## Quality rule categories

The rules are grouped into:

```text
Completeness
Uniqueness
Validity
Referential integrity
Consistency
Historical integrity
Grain checks
Reconciliation
Privacy and governance
```

## 1. Completeness rules

Completeness checks whether required fields are present.

## Customer completeness

```text
customer.customer_number must not be null.
customer.first_name must not be null.
customer.last_name must not be null.
customer.customer_type must not be null.
customer.date_of_birth must not be null for individual customers.
```

Example SQL:

```sql
SELECT COUNT(*) AS missing_customer_number_count
FROM customer
WHERE customer_number IS NULL;
```

## Account completeness

```text
account.account_number must not be null.
account.product_id must not be null.
account.branch_id must not be null.
account.open_date must not be null.
```

Example SQL:

```sql
SELECT COUNT(*) AS missing_account_number_count
FROM account
WHERE account_number IS NULL;
```

## Transaction completeness

```text
account_transaction.transaction_reference must not be null.
account_transaction.account_id must not be null.
account_transaction.transaction_type_id must not be null.
account_transaction.channel_id must not be null.
account_transaction.transaction_datetime must not be null.
account_transaction.posted_date must not be null.
account_transaction.amount must not be null.
account_transaction.currency_code must not be null.
```

Example SQL:

```sql
SELECT COUNT(*) AS incomplete_transaction_count
FROM account_transaction
WHERE transaction_reference IS NULL
   OR account_id IS NULL
   OR transaction_type_id IS NULL
   OR channel_id IS NULL
   OR transaction_datetime IS NULL
   OR posted_date IS NULL
   OR amount IS NULL
   OR currency_code IS NULL;
```

## Daily balance completeness

```text
daily_account_balance.account_id must not be null.
daily_account_balance.balance_date must not be null.
daily_account_balance.opening_balance must not be null.
daily_account_balance.closing_balance must not be null.
daily_account_balance.available_balance must not be null.
daily_account_balance.currency_code must not be null.
```

Example SQL:

```sql
SELECT COUNT(*) AS incomplete_daily_balance_count
FROM daily_account_balance
WHERE account_id IS NULL
   OR balance_date IS NULL
   OR opening_balance IS NULL
   OR closing_balance IS NULL
   OR available_balance IS NULL
   OR currency_code IS NULL;
```

## 2. Uniqueness rules

Uniqueness checks whether business identifiers are duplicated.

## Customer uniqueness

```text
customer.customer_number must be unique.
customer.national_id should be unique when present.
```

Example SQL:

```sql
SELECT
    customer_number,
    COUNT(*) AS row_count
FROM customer
GROUP BY customer_number
HAVING COUNT(*) > 1;
```

## Account uniqueness

```text
account.account_number must be unique.
```

Example SQL:

```sql
SELECT
    account_number,
    COUNT(*) AS row_count
FROM account
GROUP BY account_number
HAVING COUNT(*) > 1;
```

## Transaction uniqueness

```text
account_transaction.transaction_reference must be unique.
```

Example SQL:

```sql
SELECT
    transaction_reference,
    COUNT(*) AS row_count
FROM account_transaction
GROUP BY transaction_reference
HAVING COUNT(*) > 1;
```

## Daily balance uniqueness

There must be only one balance row per account per date.

```text
daily_account_balance must be unique by account_id and balance_date.
```

Example SQL:

```sql
SELECT
    account_id,
    balance_date,
    COUNT(*) AS row_count
FROM daily_account_balance
GROUP BY
    account_id,
    balance_date
HAVING COUNT(*) > 1;
```

## Account holder uniqueness

The same customer-account relationship should not be duplicated for the same start date.

```text
account_holder must be unique by customer_id, account_id, and start_date.
```

Example SQL:

```sql
SELECT
    customer_id,
    account_id,
    start_date,
    COUNT(*) AS row_count
FROM account_holder
GROUP BY
    customer_id,
    account_id,
    start_date
HAVING COUNT(*) > 1;
```

## 3. Validity rules

Validity checks whether values are allowed and sensible.

## Customer type validity

Allowed values:

```text
INDIVIDUAL
BUSINESS
```

Example SQL:

```sql
SELECT customer_type, COUNT(*) AS row_count
FROM customer
GROUP BY customer_type;
```

Invalid values:

```sql
SELECT *
FROM customer
WHERE customer_type NOT IN ('INDIVIDUAL', 'BUSINESS');
```

## Holder role validity

Allowed values:

```text
PRIMARY
JOINT
SIGNATORY
AUTHORIZED_USER
```

Example SQL:

```sql
SELECT *
FROM account_holder
WHERE holder_role NOT IN (
    'PRIMARY',
    'JOINT',
    'SIGNATORY',
    'AUTHORIZED_USER'
);
```

## Ownership percentage validity

```text
ownership_percentage must be between 0 and 100 when present.
```

Example SQL:

```sql
SELECT *
FROM account_holder
WHERE ownership_percentage IS NOT NULL
  AND (
      ownership_percentage < 0
      OR ownership_percentage > 100
  );
```

## Transaction amount validity

```text
Transaction amount must not be zero.
```

Example SQL:

```sql
SELECT *
FROM account_transaction
WHERE amount = 0;
```

## Currency code validity

```text
currency_code must be 3 characters.
```

Example SQL:

```sql
SELECT *
FROM account_transaction
WHERE LENGTH(currency_code) <> 3;
```

## 4. Referential integrity rules

Referential integrity checks whether relationships are valid.

## Account to product

Every account must reference a valid product.

```sql
SELECT a.*
FROM account a
LEFT JOIN product p
    ON a.product_id = p.product_id
WHERE p.product_id IS NULL;
```

## Account to branch

Every account must reference a valid branch.

```sql
SELECT a.*
FROM account a
LEFT JOIN branch b
    ON a.branch_id = b.branch_id
WHERE b.branch_id IS NULL;
```

## Account holder to customer

Every account holder must reference a valid customer.

```sql
SELECT ah.*
FROM account_holder ah
LEFT JOIN customer c
    ON ah.customer_id = c.customer_id
WHERE c.customer_id IS NULL;
```

## Account holder to account

Every account holder must reference a valid account.

```sql
SELECT ah.*
FROM account_holder ah
LEFT JOIN account a
    ON ah.account_id = a.account_id
WHERE a.account_id IS NULL;
```

## Transaction to account

Every transaction must reference a valid account.

```sql
SELECT t.*
FROM account_transaction t
LEFT JOIN account a
    ON t.account_id = a.account_id
WHERE a.account_id IS NULL;
```

## Transaction to transaction type

Every transaction must reference a valid transaction type.

```sql
SELECT t.*
FROM account_transaction t
LEFT JOIN transaction_type tt
    ON t.transaction_type_id = tt.transaction_type_id
WHERE tt.transaction_type_id IS NULL;
```

## Transaction to channel

Every transaction must reference a valid channel.

```sql
SELECT t.*
FROM account_transaction t
LEFT JOIN channel c
    ON t.channel_id = c.channel_id
WHERE c.channel_id IS NULL;
```

## Daily balance to account

Every daily balance must reference a valid account.

```sql
SELECT b.*
FROM daily_account_balance b
LEFT JOIN account a
    ON b.account_id = a.account_id
WHERE a.account_id IS NULL;
```

## 5. Consistency rules

Consistency checks whether related values make sense together.

## Account date consistency

```text
account.close_date cannot be before account.open_date.
```

Example SQL:

```sql
SELECT *
FROM account
WHERE close_date IS NOT NULL
  AND close_date < open_date;
```

## Account holder date consistency

```text
account_holder.end_date cannot be before account_holder.start_date.
```

Example SQL:

```sql
SELECT *
FROM account_holder
WHERE end_date IS NOT NULL
  AND end_date < start_date;
```

## Customer segment history date consistency

```text
effective_to_date cannot be before effective_from_date.
```

Example SQL:

```sql
SELECT *
FROM customer_segment_history
WHERE effective_to_date IS NOT NULL
  AND effective_to_date < effective_from_date;
```

## Account status history date consistency

```text
effective_to_date cannot be before effective_from_date.
```

Example SQL:

```sql
SELECT *
FROM account_status_history
WHERE effective_to_date IS NOT NULL
  AND effective_to_date < effective_from_date;
```

## Balance date consistency

```text
daily_account_balance.balance_date should not be in the future.
```

Example SQL:

```sql
SELECT *
FROM daily_account_balance
WHERE balance_date > CURRENT_DATE;
```

## 6. Historical integrity rules

Historical tables must not contain overlapping date ranges for the same business entity.

## Customer segment overlap

A customer should not have two active segment records for the same date range.

Example SQL:

```sql
SELECT
    a.customer_id,
    a.customer_segment_history_id AS record_1,
    b.customer_segment_history_id AS record_2
FROM customer_segment_history a
JOIN customer_segment_history b
    ON a.customer_id = b.customer_id
   AND a.customer_segment_history_id < b.customer_segment_history_id
   AND a.effective_from_date <= COALESCE(b.effective_to_date, DATE '9999-12-31')
   AND b.effective_from_date <= COALESCE(a.effective_to_date, DATE '9999-12-31');
```

## Account status overlap

An account should not have two active status records for the same date range.

Example SQL:

```sql
SELECT
    a.account_id,
    a.account_status_history_id AS record_1,
    b.account_status_history_id AS record_2
FROM account_status_history a
JOIN account_status_history b
    ON a.account_id = b.account_id
   AND a.account_status_history_id < b.account_status_history_id
   AND a.effective_from_date <= COALESCE(b.effective_to_date, DATE '9999-12-31')
   AND b.effective_from_date <= COALESCE(a.effective_to_date, DATE '9999-12-31');
```

## Current row integrity

For history tables, each customer or account should normally have only one current record.

Customer segment:

```sql
SELECT
    customer_id,
    COUNT(*) AS current_record_count
FROM customer_segment_history
WHERE is_current = TRUE
GROUP BY customer_id
HAVING COUNT(*) > 1;
```

Account status:

```sql
SELECT
    account_id,
    COUNT(*) AS current_record_count
FROM account_status_history
WHERE is_current = TRUE
GROUP BY account_id
HAVING COUNT(*) > 1;
```

## 7. Grain checks

Grain checks confirm that each table keeps one row per intended business object.

## Daily account balance grain

Expected grain:

```text
One row per account per balance date.
```

Check:

```sql
SELECT
    account_id,
    balance_date,
    COUNT(*) AS row_count
FROM daily_account_balance
GROUP BY
    account_id,
    balance_date
HAVING COUNT(*) > 1;
```

## Transaction grain

Expected grain:

```text
One row per posted account transaction.
```

Check:

```sql
SELECT
    transaction_reference,
    COUNT(*) AS row_count
FROM account_transaction
GROUP BY transaction_reference
HAVING COUNT(*) > 1;
```

## Account holder grain

Expected grain:

```text
One row per customer-account relationship per start date.
```

Check:

```sql
SELECT
    customer_id,
    account_id,
    start_date,
    COUNT(*) AS row_count
FROM account_holder
GROUP BY
    customer_id,
    account_id,
    start_date
HAVING COUNT(*) > 1;
```

## 8. Reconciliation rules

Reconciliation compares totals between layers or source systems.

## Transaction count reconciliation

Example:

```sql
SELECT COUNT(*) AS transaction_count
FROM account_transaction;
```

This should reconcile to the cleaned source transaction count for the same period.

## Transaction amount reconciliation

Example:

```sql
SELECT
    posted_date,
    SUM(amount) AS total_amount
FROM account_transaction
GROUP BY posted_date
ORDER BY posted_date;
```

This can be compared to source system daily totals.

## Balance reconciliation

Example:

```sql
SELECT
    balance_date,
    COUNT(*) AS balance_row_count,
    SUM(closing_balance) AS total_closing_balance
FROM daily_account_balance
GROUP BY balance_date
ORDER BY balance_date;
```

This can be compared to source balance control totals.

## 9. Privacy and governance rules

Sensitive fields must be handled carefully.

Sensitive fields include:

```text
customer.national_id
customer.passport_number
customer.date_of_birth
```

Governance rules:

```text
Do not expose national_id in general reporting models.
Do not expose passport_number in general reporting models.
Use age_band instead of date_of_birth where possible.
Mask account_number in reporting layers where required.
Limit access to customer personal identifiers.
```

## Quality results table idea

In a real pipeline, quality check results can be stored in a monitoring table.

Example:

```text
data_quality_check_result
- check_result_id
- check_name
- table_name
- rule_category
- check_status
- failed_row_count
- checked_at
- pipeline_run_id
```

This makes quality visible over time.

## Severity levels

Recommended severity levels:

| Severity | Meaning                                  | Example                            |
| -------- | ---------------------------------------- | ---------------------------------- |
| High     | Breaks trust or integrity                | Transaction references duplicated  |
| Medium   | Important but may not stop all reporting | Missing optional branch city       |
| Low      | Minor or informational                   | Unexpected but harmless formatting |

## High severity rules

These should usually fail the pipeline or block publishing:

```text
Duplicate customer_number
Duplicate account_number
Duplicate transaction_reference
Transactions without accounts
Accounts without products
Accounts without branches
Invalid transaction amount
Duplicate daily balance by account and date
Overlapping customer segment history
Overlapping account status history
```

## Medium severity rules

These should usually create warnings and require investigation:

```text
Missing optional customer identifiers
Missing branch city
Missing transaction description
Unusual currency codes
Large changes in daily transaction volume
Large changes in balance totals
```

## Data quality checklist

Before publishing the model, confirm:

```text
Required fields are complete.
Business keys are unique.
Allowed values are valid.
Foreign key relationships are valid.
Date ranges are consistent.
History records do not overlap.
Each table respects its grain.
Balances are unique by account and date.
Transactions are unique by transaction reference.
Sensitive fields are protected.
Reconciliation checks pass.
Quality failures are visible and logged.
```

## Key takeaway

Data quality rules protect the meaning of the model.

The most important checks in this capstone are:

```text
No duplicate business keys.
No orphan records.
No invalid date ranges.
No overlapping history.
No duplicate daily balances.
No zero transaction amounts.
No accidental exposure of sensitive customer data.
```
