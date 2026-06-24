# Banking Capstone Project

## Purpose

This capstone applies the data modelling concepts from the course to a practical retail banking scenario.

The goal is to move from business requirements to a complete data model that supports both operational understanding and analytical reporting.

## Scenario

We are modelling a simplified retail banking environment.

The bank needs to understand:

- customers
- accounts
- account ownership
- products
- branches
- transactions
- transaction types
- channels
- daily balances
- customer segment history
- account status history

The model should support both:

```text
Operational modelling
Analytics modelling
````

## Main business questions

This capstone is designed to support questions such as:

```text
How many customers does the bank have?
How many accounts are active?
Which customers hold which accounts?
Which accounts are jointly held?
What products are most used?
Which branches manage the most accounts?
What is the total transaction value by channel?
What is the transaction volume by product?
What are daily balances by account?
How do account statuses change over time?
How do customer segments change over time?
```

## Capstone structure

| File                                                       | Purpose                                                    |
| ---------------------------------------------------------- | ---------------------------------------------------------- |
| [01-business-requirements.md](01-business-requirements.md) | Defines the business requirements and modelling scope      |
| [02-conceptual-model.md](02-conceptual-model.md)           | Defines the high-level business entities and relationships |
| [03-logical-model.md](03-logical-model.md)                 | Defines tables, keys, relationships, and grains            |
| [04-physical-model.md](04-physical-model.md)               | Defines physical implementation choices                    |
| [05-analytics-star-schema.md](05-analytics-star-schema.md) | Defines the dimensional model for reporting                |
| [06-data-quality-rules.md](06-data-quality-rules.md)       | Defines quality checks and governance rules                |
| [07-documentation.md](07-documentation.md)                 | Documents the completed model                              |
| [sql/banking_model_ddl.sql](sql/banking_model_ddl.sql)     | PostgreSQL-style DDL for the physical model                |

## Modelling flow

The capstone follows this modelling flow:

```text
Business requirements
        ↓
Conceptual model
        ↓
Logical model
        ↓
Physical model
        ↓
Analytics star schema
        ↓
Data quality rules
        ↓
Documentation
```

## Main entities

The core entities are:

```text
Customer
Account
Account Holder
Product
Branch
Transaction
Transaction Type
Channel
Daily Account Balance
Customer Segment
Customer Segment History
Account Status
Account Status History
```

## Core relationship

The most important relationship in the model is:

```text
Customer many-to-many Account
```

This exists because:

```text
One customer can hold many accounts.
One account can be held by many customers.
```

This is resolved using:

```text
Account Holder
```

The `account_holder` table is essential because it supports joint accounts.

## Key modelling decisions

### Customers and accounts are separate

A customer is not the same thing as an account.

A customer can exist before opening an account.

An account must have at least one account holder.

### Joint accounts are supported

Because accounts can have multiple customers, the model uses an `account_holder` table.

This avoids forcing a weak design such as:

```text
account.customer_id
```

That design would fail for joint accounts.

### Transactions belong to accounts

Transactions are modelled at account level.

Customer-level transaction reporting must be handled carefully because joint accounts can cause double-counting.

### Balances are separate from transactions

Transactions are events.

Balances are snapshots.

Therefore, the model separates:

```text
account_transaction
daily_account_balance
```

### History is modelled separately

The capstone tracks history for:

```text
Customer segment
Account status
```

This avoids overwriting important historical changes.

## Operational model

The operational-style model focuses on clean entities and relationships.

Examples:

```text
customer
account
account_holder
product
branch
account_transaction
daily_account_balance
```

This structure is closer to a normalised model.

## Analytics model

The analytics model uses a star schema.

Example fact tables:

```text
fact_transaction
fact_daily_account_balance
```

Example dimension tables:

```text
dim_customer
dim_account
dim_product
dim_branch
dim_channel
dim_date
dim_transaction_type
```

This structure is easier for reporting and dashboards.

## Important caution

Customer-level transaction reporting for joint accounts requires a clear business rule.

Example:

```text
Account ACC100 has two holders.
A transaction of R1,000 happens on ACC100.
```

If the transaction is joined to both customers, the value may double-count.

Possible business rules include:

```text
Report transactions at account level only.
Assign the transaction to the primary holder.
Allocate the amount by ownership percentage.
Use a bridge table with allocation rules.
```

This capstone documents this risk instead of hiding it.

## Technologies assumed

The physical model uses PostgreSQL-style SQL.

The ideas can be adapted to other platforms such as:

```text
MySQL
SQL Server
Snowflake
BigQuery
Redshift
Databricks
```

Some syntax may need to change depending on the platform.

## Outcome

By the end of the capstone, the repository contains:

```text
A business requirements document
A conceptual model
A logical model
A physical model
A PostgreSQL-style DDL script
An analytics star schema
Data quality rules
A model documentation file
```

This shows the full data modelling journey from business thinking to implementation-ready design.
