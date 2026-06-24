# 04: Physical Model

## Purpose

This document defines the physical data model for the banking capstone project.

The physical model converts the logical model into an implementation-ready database design.

It includes:

```text
SQL data types
Primary keys
Foreign keys
Unique constraints
Check constraints
Indexes
Audit columns
Naming conventions
````

The SQL examples use PostgreSQL-style syntax.

## Physical modelling goal

The physical model should support:

```text
Data integrity
Reliable joins
Historical tracking
Efficient querying
Clear naming
Data quality enforcement
Future analytics modelling
```

## Naming conventions

This model uses:

```text
lowercase snake_case
singular table names
_id suffix for primary and foreign keys
_code suffix for business codes
_date suffix for date values
_datetime suffix for timestamp values
_amount suffix for money values
```

Examples:

```text
customer_id
customer_number
account_id
account_number
transaction_datetime
posted_date
closing_balance
```

## Core tables

The physical model contains:

```text
customer
customer_segment
customer_segment_history

branch
product

account
account_status
account_status_history
account_holder

channel
transaction_type
account_transaction

daily_account_balance
```

## Data type decisions

Common physical data type choices:

| Data type       | Used for                       |
| --------------- | ------------------------------ |
| `BIGINT`        | Surrogate keys                 |
| `VARCHAR`       | Text, names, codes, references |
| `DATE`          | Dates without time             |
| `TIMESTAMP`     | Date and time                  |
| `NUMERIC(18,2)` | Money values                   |
| `NUMERIC(5,2)`  | Percentages                    |
| `BOOLEAN`       | True or false flags            |
| `CHAR(3)`       | Currency codes                 |

## Customer

```sql
CREATE TABLE customer (
    customer_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    customer_number VARCHAR(50) NOT NULL UNIQUE,
    national_id VARCHAR(50) UNIQUE,
    passport_number VARCHAR(50),
    first_name VARCHAR(100) NOT NULL,
    last_name VARCHAR(100) NOT NULL,
    date_of_birth DATE NOT NULL,
    customer_type VARCHAR(30) NOT NULL CHECK (
        customer_type IN ('INDIVIDUAL', 'BUSINESS')
    ),
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP
);
```

## Customer Segment

```sql
CREATE TABLE customer_segment (
    customer_segment_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    customer_segment_code VARCHAR(50) NOT NULL UNIQUE,
    customer_segment_name VARCHAR(100) NOT NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP
);
```

## Customer Segment History

```sql
CREATE TABLE customer_segment_history (
    customer_segment_history_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    customer_id BIGINT NOT NULL REFERENCES customer(customer_id),
    customer_segment_id BIGINT NOT NULL REFERENCES customer_segment(customer_segment_id),
    effective_from_date DATE NOT NULL,
    effective_to_date DATE,
    is_current BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP,
    CHECK (
        effective_to_date IS NULL
        OR effective_to_date >= effective_from_date
    )
);
```

## Branch

```sql
CREATE TABLE branch (
    branch_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    branch_code VARCHAR(50) NOT NULL UNIQUE,
    branch_name VARCHAR(150) NOT NULL,
    province VARCHAR(100),
    city VARCHAR(100),
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP
);
```

## Product

```sql
CREATE TABLE product (
    product_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    product_code VARCHAR(50) NOT NULL UNIQUE,
    product_name VARCHAR(150) NOT NULL,
    product_category VARCHAR(100) NOT NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP
);
```

## Account

```sql
CREATE TABLE account (
    account_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    account_number VARCHAR(50) NOT NULL UNIQUE,
    product_id BIGINT NOT NULL REFERENCES product(product_id),
    branch_id BIGINT NOT NULL REFERENCES branch(branch_id),
    open_date DATE NOT NULL,
    close_date DATE,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP,
    CHECK (
        close_date IS NULL
        OR close_date >= open_date
    )
);
```

## Account Status

```sql
CREATE TABLE account_status (
    account_status_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    account_status_code VARCHAR(50) NOT NULL UNIQUE,
    account_status_name VARCHAR(100) NOT NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP
);
```

## Account Status History

```sql
CREATE TABLE account_status_history (
    account_status_history_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    account_id BIGINT NOT NULL REFERENCES account(account_id),
    account_status_id BIGINT NOT NULL REFERENCES account_status(account_status_id),
    effective_from_date DATE NOT NULL,
    effective_to_date DATE,
    is_current BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP,
    CHECK (
        effective_to_date IS NULL
        OR effective_to_date >= effective_from_date
    )
);
```

## Account Holder

```sql
CREATE TABLE account_holder (
    account_holder_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    customer_id BIGINT NOT NULL REFERENCES customer(customer_id),
    account_id BIGINT NOT NULL REFERENCES account(account_id),
    holder_role VARCHAR(50) NOT NULL CHECK (
        holder_role IN ('PRIMARY', 'JOINT', 'SIGNATORY', 'AUTHORIZED_USER')
    ),
    ownership_percentage NUMERIC(5,2),
    start_date DATE NOT NULL,
    end_date DATE,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP,
    CHECK (
        end_date IS NULL
        OR end_date >= start_date
    ),
    CHECK (
        ownership_percentage IS NULL
        OR ownership_percentage BETWEEN 0 AND 100
    ),
    UNIQUE (customer_id, account_id, start_date)
);
```

## Channel

```sql
CREATE TABLE channel (
    channel_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    channel_code VARCHAR(50) NOT NULL UNIQUE,
    channel_name VARCHAR(100) NOT NULL,
    channel_group VARCHAR(100) NOT NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP
);
```

## Transaction Type

```sql
CREATE TABLE transaction_type (
    transaction_type_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    transaction_type_code VARCHAR(50) NOT NULL UNIQUE,
    transaction_type_name VARCHAR(100) NOT NULL,
    transaction_category VARCHAR(100) NOT NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP
);
```

## Account Transaction

```sql
CREATE TABLE account_transaction (
    transaction_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    transaction_reference VARCHAR(100) NOT NULL UNIQUE,
    account_id BIGINT NOT NULL REFERENCES account(account_id),
    transaction_type_id BIGINT NOT NULL REFERENCES transaction_type(transaction_type_id),
    channel_id BIGINT NOT NULL REFERENCES channel(channel_id),
    transaction_datetime TIMESTAMP NOT NULL,
    posted_date DATE NOT NULL,
    amount NUMERIC(18,2) NOT NULL CHECK (amount <> 0),
    currency_code CHAR(3) NOT NULL,
    description VARCHAR(255),
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);
```

## Daily Account Balance

```sql
CREATE TABLE daily_account_balance (
    daily_account_balance_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    account_id BIGINT NOT NULL REFERENCES account(account_id),
    balance_date DATE NOT NULL,
    opening_balance NUMERIC(18,2) NOT NULL,
    closing_balance NUMERIC(18,2) NOT NULL,
    available_balance NUMERIC(18,2) NOT NULL,
    currency_code CHAR(3) NOT NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    UNIQUE (account_id, balance_date)
);
```

## Indexes

Indexes should support common joins and filters.

```sql
CREATE INDEX idx_customer_segment_history_customer_id
ON customer_segment_history(customer_id);

CREATE INDEX idx_customer_segment_history_segment_id
ON customer_segment_history(customer_segment_id);

CREATE INDEX idx_account_product_id
ON account(product_id);

CREATE INDEX idx_account_branch_id
ON account(branch_id);

CREATE INDEX idx_account_status_history_account_id
ON account_status_history(account_id);

CREATE INDEX idx_account_status_history_status_id
ON account_status_history(account_status_id);

CREATE INDEX idx_account_holder_customer_id
ON account_holder(customer_id);

CREATE INDEX idx_account_holder_account_id
ON account_holder(account_id);

CREATE INDEX idx_account_transaction_account_id
ON account_transaction(account_id);

CREATE INDEX idx_account_transaction_type_id
ON account_transaction(transaction_type_id);

CREATE INDEX idx_account_transaction_channel_id
ON account_transaction(channel_id);

CREATE INDEX idx_account_transaction_posted_date
ON account_transaction(posted_date);

CREATE INDEX idx_daily_account_balance_account_id
ON daily_account_balance(account_id);

CREATE INDEX idx_daily_account_balance_balance_date
ON daily_account_balance(balance_date);
```

## Important constraints

The model enforces these rules physically:

```text
customer.customer_number is unique.
account.account_number is unique.
transaction_reference is unique.
account_holder prevents duplicate customer-account relationships by start date.
daily_account_balance allows only one balance per account per date.
transaction amount cannot be zero.
close_date cannot be before open_date.
history end dates cannot be before start dates.
ownership percentage must be between 0 and 100.
```

## Audit columns

Most tables include:

```text
created_at
updated_at
```

These help track when rows were created or updated.

For real data engineering pipelines, additional audit fields may be useful:

```text
source_system
source_file
ingestion_batch_id
loaded_at
```

Those are especially useful in bronze and silver layers.

## Partitioning considerations

The largest tables are likely to be:

```text
account_transaction
daily_account_balance
```

Possible partitioning strategy:

```text
account_transaction partitioned by posted_date
daily_account_balance partitioned by balance_date
```

This is useful because banking queries often filter by date.

Example:

```sql
SELECT
    SUM(amount) AS total_amount
FROM account_transaction
WHERE posted_date >= DATE '2026-01-01'
  AND posted_date < DATE '2026-02-01';
```

For small learning projects, partitioning is not required.

For production-scale banking data, it should be considered.

## Physical model cautions

## Caution 1: History overlap

The database checks that end dates are not before start dates.

But it does not fully prevent overlapping history periods.

Example problem:

```text
Customer C001:
Student from 2025-01-01 to 2025-12-31
Premium from 2025-06-01 to null
```

This overlap should be handled with pipeline logic or more advanced database constraints.

## Caution 2: At least one account holder

The model says an account must have at least one account holder.

A simple foreign key cannot fully enforce this because the account is created before the account holder row.

This rule should be enforced through:

```text
Application logic
Pipeline validation
Database trigger if required
Data quality checks
```

## Caution 3: Joint account double-counting

The physical model stores transactions at account level.

If reporting joins transactions to customers through `account_holder`, joint accounts may duplicate transaction rows.

This is a reporting design issue, not a database constraint issue.

## Physical model checklist

Before implementing, check:

```text
Are primary keys defined?
Are business keys unique?
Are foreign keys defined?
Are required fields NOT NULL?
Are valid values protected?
Are money values stored as NUMERIC, not FLOAT?
Are dates stored as DATE or TIMESTAMP, not text?
Are indexes aligned to joins and filters?
Are large tables considered for partitioning?
Are audit columns included?
Are history tables protected from invalid date ranges?
```

## Key takeaway

The physical model turns the logical model into a real database design.

The most important implementation choices are:

```text
Use proper data types.
Protect business keys with unique constraints.
Use foreign keys for relationships.
Use check constraints for basic business rules.
Index common join and filter columns.
Separate transactions from balances.
Track history with effective dates.
```
