# Module 17: Data Model Documentation

## Goal

The goal of this module is to understand how to document a data model properly so that other people can understand, use, maintain, and trust it.

A data model is not complete if only the person who built it understands it.

Good documentation answers:

```text
What does this model do?
What business problem does it solve?
What tables exist?
What does one row represent?
How are tables connected?
What rules protect the data?
What assumptions were made?
How should the model be used?
````

## Why documentation matters

Data models are used by many people:

```text
Data engineers
Analytics engineers
BI developers
Data analysts
Data scientists
Business users
Database administrators
Future maintainers
```

If the model is not documented, people may:

```text
Join tables incorrectly
Misunderstand the grain
Double-count facts
Use the wrong date field
Misinterpret business definitions
Break pipelines during changes
Create duplicate models
Lose trust in the data
```

Documentation reduces confusion and protects the model.

## What should be documented?

A strong data model document should include:

```text
Business purpose
Scope
Entities or tables
Grain
Columns
Keys
Relationships
Business rules
Data quality rules
Security considerations
Lineage
Usage examples
Known limitations
```

## 1. Business purpose

Explain why the model exists.

Example:

```text
This banking model supports analysis of customers, accounts, products, branches, transactions, and daily account balances.
```

Better:

```text
This model helps answer business questions such as:

- How many active accounts exist by product?
- What is total transaction value by channel?
- What are daily balances by branch?
- Which customers hold joint accounts?
```

The purpose should connect the model to business value.

## 2. Scope

Scope explains what is included and excluded.

Example in scope:

```text
Customers
Accounts
Account holders
Products
Branches
Transactions
Transaction types
Channels
Daily account balances
```

Example out of scope:

```text
Loans
Credit cards
Fraud alerts
Employee relationship managers
Customer complaints
Marketing campaigns
```

Scope prevents people from assuming the model does everything.

## 3. Table descriptions

Every table should have a short description.

Example:

```text
customer:
Stores one row per customer known to the bank.

account:
Stores one row per bank account.

account_holder:
Stores one row per relationship between a customer and an account.

account_transaction:
Stores one row per posted account transaction.

daily_account_balance:
Stores one row per account per balance date.
```

The description should clearly say what the table represents.

## 4. Grain

Grain is one of the most important things to document.

Example:

```text
customer:
One row per customer.

account:
One row per account.

account_holder:
One row per customer-account relationship.

account_transaction:
One row per posted account transaction.

daily_account_balance:
One row per account per day.
```

If the grain is not documented, users may join and aggregate incorrectly.

## 5. Column descriptions

Important columns should have descriptions.

Example:

```text
account_transaction.transaction_reference:
Unique business reference for the transaction from the source system.

account_transaction.amount:
Transaction amount. Positive and negative values should follow the source system posting convention.

daily_account_balance.closing_balance:
Balance at the end of the balance_date.

account_holder.holder_role:
Role of the customer on the account, such as PRIMARY, JOINT, SIGNATORY, or AUTHORIZED_USER.
```

Column descriptions are especially important when names are not enough.

## 6. Keys

Document primary keys, foreign keys, business keys, and unique rules.

Example:

```text
customer
- Primary key: customer_id
- Business key: customer_number
- Unique rules: customer_number must be unique

account
- Primary key: account_id
- Business key: account_number
- Foreign keys:
  - product_id references product.product_id
  - branch_id references branch.branch_id
- Unique rules: account_number must be unique
```

This helps people understand how to join safely.

## 7. Relationships

Document how tables connect.

Example:

```text
branch 1 --- many account
product 1 --- many account
customer 1 --- many account_holder
account 1 --- many account_holder
account 1 --- many account_transaction
transaction_type 1 --- many account_transaction
channel 1 --- many account_transaction
account 1 --- many daily_account_balance
```

Also document many-to-many relationships.

Example:

```text
Customer and Account have a many-to-many relationship.

This is resolved through account_holder.
```

## 8. Business rules

Business rules explain what must be true.

Examples:

```text
Each account must belong to one product.
Each account must belong to one branch.
Each account must have at least one account holder.
Each transaction must belong to one account.
A transaction amount must not be zero.
An account close_date cannot be before open_date.
A daily balance must be unique by account and date.
```

Business rules help both technical and business people understand the model.

## 9. Data quality rules

Document the quality checks that protect the model.

Examples:

```text
customer.customer_number must not be null.
customer.customer_number must be unique.
account.account_number must not be null.
account.account_number must be unique.
account_transaction.transaction_reference must be unique.
account_transaction.account_id must exist in account.
daily_account_balance must be unique by account_id and balance_date.
daily_account_balance.balance_date must not be in the future.
```

Good documentation should not only describe the happy path. It should explain how the model is protected.

## 10. Lineage

Lineage explains where the data comes from and how it moves.

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

Lineage helps with debugging and impact analysis.

It answers:

```text
Where did this field come from?
Which pipeline loads this table?
Which reports depend on it?
What breaks if this source changes?
```

## 11. Security and privacy

Document sensitive fields and access rules.

Sensitive examples:

```text
national_id
passport_number
date_of_birth
phone_number
email
physical_address
risk_score
```

Example note:

```text
national_id and passport_number are sensitive fields and should not be exposed in general reporting models unless there is an approved business reason.
```

For gold reporting models, consider exposing derived or grouped fields instead:

```text
age_band
province
customer_segment
```

instead of direct personal identifiers.

## 12. Usage examples

Documentation should include example queries.

Example:

```sql
SELECT
    b.branch_name,
    COUNT(DISTINCT a.account_id) AS account_count
FROM account a
JOIN branch b
    ON a.branch_id = b.branch_id
GROUP BY
    b.branch_name;
```

Example:

```sql
SELECT
    t.posted_date,
    c.channel_name,
    SUM(t.amount) AS total_transaction_amount
FROM account_transaction t
JOIN channel c
    ON t.channel_id = c.channel_id
GROUP BY
    t.posted_date,
    c.channel_name;
```

Usage examples make the model easier to adopt.

## 13. Known limitations

Every model has limits.

Document them clearly.

Examples:

```text
This model does not currently include loan accounts.
Customer-level transaction reporting for joint accounts requires an allocation rule.
Only posted transactions are included.
Pending card authorisations are excluded.
Daily balances are captured at account level, not customer level.
```

Limitations protect users from using the model incorrectly.

## Data dictionary example

A data dictionary documents tables and columns.

Example:

| Table               | Column                | Description                     | Key/Rule           |
| ------------------- | --------------------- | ------------------------------- | ------------------ |
| customer            | customer_id           | Internal customer identifier    | Primary key        |
| customer            | customer_number       | Business customer number        | Unique, not null   |
| account             | account_id            | Internal account identifier     | Primary key        |
| account             | account_number        | Business account number         | Unique, not null   |
| account             | product_id            | Product linked to the account   | Foreign key        |
| account_transaction | transaction_id        | Internal transaction identifier | Primary key        |
| account_transaction | transaction_reference | Source transaction reference    | Unique, not null   |
| account_transaction | amount                | Transaction amount              | Not null, not zero |

## Model README structure

A good model README can follow this structure:

```text
# Model Name

## Purpose

## Scope

## Business Questions Supported

## Tables

## Grain

## Relationships

## Keys

## Business Rules

## Data Quality Rules

## Security and Privacy

## Lineage

## Usage Examples

## Known Limitations
```

This structure is useful for project documentation, GitHub repositories, and internal data platform docs.

## Documentation for dimensional models

For dimensional models, document:

```text
Fact table grain
Measures
Measure types
Dimensions
Conformed dimensions
SCD handling
Bridge tables
Aggregation rules
Double-counting risks
```

Example:

```text
fact_transaction:
Grain: one row per posted account transaction.
Measures: transaction_amount, transaction_count.
Dimensions: dim_date, dim_account, dim_product, dim_branch, dim_channel, dim_transaction_type.
Warning: customer-level reporting for joint accounts requires bridge_account_customer and an allocation rule.
```

## Documentation for SCDs

For Slowly Changing Dimensions, document:

```text
Business key
Surrogate key
SCD type
Tracked attributes
Effective date logic
Current row indicator
Late-arriving data handling
```

Example:

```text
dim_customer:
Business key: customer_number.
Surrogate key: customer_key.
SCD type: Type 2 for customer_segment and risk_rating.
Current row: is_current = true.
Effective dates: effective_from_date and effective_to_date.
```

## Documentation for data quality

For each quality rule, document:

```text
Rule name
Table
Column
Rule type
Description
Severity
Owner
Failure action
```

Example:

| Rule name                    | Table               | Rule type    | Severity | Description                           |
| ---------------------------- | ------------------- | ------------ | -------- | ------------------------------------- |
| account_number_not_null      | account             | Completeness | High     | account_number must not be null       |
| transaction_reference_unique | account_transaction | Uniqueness   | High     | transaction_reference must be unique  |
| valid_account_dates          | account             | Consistency  | Medium   | close_date cannot be before open_date |

## Common mistakes

### Mistake 1: Documenting only column names

Column names are not enough.

Bad:

```text
account_id
account_number
open_date
```

Better:

```text
account_id:
Internal surrogate key for the account table.

account_number:
Business account number from the source banking system.

open_date:
Date on which the account was opened.
```

### Mistake 2: Not documenting grain

If users do not know the grain, they can easily double-count.

### Mistake 3: No relationship documentation

Users may guess joins and produce wrong results.

### Mistake 4: No business definitions

Terms like active customer, dormant account, posted transaction, and available balance need definitions.

### Mistake 5: No limitations

If limitations are not documented, users assume the model covers more than it does.

## Documentation checklist

Before calling a data model complete, ask:

```text
Is the business purpose clear?
Is the scope documented?
Are all tables described?
Is the grain of every important table documented?
Are key columns explained?
Are relationships documented?
Are business rules listed?
Are data quality rules listed?
Are sensitive fields identified?
Is lineage explained?
Are example queries included?
Are limitations stated?
Can someone else maintain this model without asking the original builder?
```

## Key takeaways

* A data model is not complete without documentation.
* Documentation protects business meaning.
* Grain must always be documented.
* Relationships and keys must be clear.
* Business rules and data quality rules should be visible.
* Security and privacy considerations must be documented.
* Good documentation makes the model reusable, maintainable, and trustworthy.
