# Module 08: Physical Data Modelling

## Goal

The goal of this module is to understand how to turn a logical data model into real database tables.

Physical data modelling answers:

> How exactly should this model be implemented in a real database?

This is where we care about:

- SQL data types
- constraints
- indexes
- partitions
- audit columns
- naming conventions
- performance choices
- database-specific implementation

## Logical vs physical model

### Logical model

Database-independent:

```text
customer
- customer_id
- customer_number
- first_name
- last_name
- date_of_birth
````

### Physical model

Database-specific:

```sql
CREATE TABLE customer (
    customer_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    customer_number VARCHAR(50) NOT NULL UNIQUE,
    first_name VARCHAR(100) NOT NULL,
    last_name VARCHAR(100) NOT NULL,
    date_of_birth DATE NOT NULL
);
```

The logical model focuses on meaning.

The physical model focuses on implementation.

## Main physical design decisions

When moving from logical to physical, decide:

```text
What data type should each column use?
Which columns must be required?
Which columns must be unique?
Which columns should be indexed?
Should large tables be partitioned?
Should audit columns be added?
Should foreign keys be enforced physically?
Should soft deletes or hard deletes be used?
How should tables and columns be named?
```

## Choosing data types

Data types matter because bad data types can cause storage, performance, and data quality problems.

Common choices:

```text
Text values        VARCHAR / TEXT
Whole numbers      INTEGER / BIGINT
Money values       NUMERIC / DECIMAL
Dates              DATE
Date and time      TIMESTAMP
True/false values  BOOLEAN
Codes              VARCHAR
```

## Banking examples

### Customer name

```sql
first_name VARCHAR(100) NOT NULL
```

### Date of birth

Bad:

```sql
date_of_birth VARCHAR(20)
```

Better:

```sql
date_of_birth DATE
```

Dates should be stored as dates, not text.

### Transaction amount

Bad:

```sql
amount FLOAT
```

Better:

```sql
amount NUMERIC(18, 2)
```

For money, avoid floating-point types unless there is a very specific reason.

Money needs exact decimal handling.

### Transaction datetime

```sql
transaction_datetime TIMESTAMP NOT NULL
```

This supports filtering, sorting, and time-based analysis.

## Constraints

Constraints protect your data.

They are rules enforced by the database.

## Primary key constraint

```sql
customer_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY
```

This ensures every customer row has a unique identifier.

## Foreign key constraint

```sql
account_id BIGINT NOT NULL REFERENCES account(account_id)
```

This ensures a transaction points to a valid account.

## Not null constraint

```sql
account_number VARCHAR(50) NOT NULL
```

This ensures important values are not missing.

## Unique constraint

```sql
account_number VARCHAR(50) NOT NULL UNIQUE
```

This ensures no two accounts use the same account number.

## Check constraint

```sql
amount NUMERIC(18, 2) NOT NULL CHECK (amount <> 0)
```

This ensures transaction amount is not zero.

Another example:

```sql
account_status VARCHAR(30) NOT NULL
CHECK (account_status IN ('ACTIVE', 'CLOSED', 'SUSPENDED'))
```

This prevents invalid statuses.

## Physical banking example

The following examples use PostgreSQL-style SQL.

### Customer

```sql
CREATE TABLE customer (
    customer_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    customer_number VARCHAR(50) NOT NULL UNIQUE,
    national_id VARCHAR(50) UNIQUE,
    passport_number VARCHAR(50),
    first_name VARCHAR(100) NOT NULL,
    last_name VARCHAR(100) NOT NULL,
    date_of_birth DATE NOT NULL,
    customer_type VARCHAR(30) NOT NULL CHECK (customer_type IN ('INDIVIDUAL', 'BUSINESS')),
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP
);
```

### Branch

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

### Product

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

### Account

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
    CHECK (close_date IS NULL OR close_date >= open_date)
);
```

### Account holder

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
    CHECK (end_date IS NULL OR end_date >= start_date),
    CHECK (ownership_percentage IS NULL OR ownership_percentage BETWEEN 0 AND 100),
    UNIQUE (customer_id, account_id, start_date)
);
```

### Transaction type

```sql
CREATE TABLE transaction_type (
    transaction_type_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    transaction_type_code VARCHAR(50) NOT NULL UNIQUE,
    transaction_type_name VARCHAR(100) NOT NULL,
    transaction_category VARCHAR(50) NOT NULL
);
```

### Channel

```sql
CREATE TABLE channel (
    channel_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    channel_code VARCHAR(50) NOT NULL UNIQUE,
    channel_name VARCHAR(100) NOT NULL,
    channel_group VARCHAR(100) NOT NULL
);
```

### Account transaction

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

`account_transaction` is used instead of `transaction` because `transaction` can be awkward or reserved in some SQL systems.

### Daily account balance

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

Indexes help the database find rows faster.

Example:

```sql
CREATE INDEX idx_account_transaction_account_id
ON account_transaction(account_id);
```

This helps queries like:

```sql
SELECT *
FROM account_transaction
WHERE account_id = 123;
```

Common banking indexes:

```sql
CREATE INDEX idx_account_branch_id
ON account(branch_id);

CREATE INDEX idx_account_product_id
ON account(product_id);

CREATE INDEX idx_account_holder_customer_id
ON account_holder(customer_id);

CREATE INDEX idx_account_holder_account_id
ON account_holder(account_id);

CREATE INDEX idx_account_transaction_account_id
ON account_transaction(account_id);

CREATE INDEX idx_account_transaction_posted_date
ON account_transaction(posted_date);

CREATE INDEX idx_daily_account_balance_account_id
ON daily_account_balance(account_id);

CREATE INDEX idx_daily_account_balance_balance_date
ON daily_account_balance(balance_date);
```

Do not index every column blindly.

Indexes improve reads, but they can slow down inserts and updates.

Index based on real query patterns.

## Partitioning

Partitioning splits a large table into smaller physical pieces.

In banking, transaction tables can become very large.

A common partitioning strategy is:

```text
Partition account_transaction by posted_date.
Partition daily_account_balance by balance_date.
```

This helps when queries filter by date.

Example:

```sql
WHERE posted_date >= DATE '2026-01-01'
  AND posted_date < DATE '2026-02-01'
```

The database can scan only the relevant partition.

Partitioning is useful when:

```text
The table is very large.
Queries commonly filter by the partition column.
Old data can be archived separately.
Loads happen incrementally.
```

Do not partition small tables. It adds complexity.

## Audit columns

Audit columns help trace when data was created, updated, loaded, or sourced.

Common audit columns:

```text
created_at
updated_at
created_by
updated_by
source_system
source_file
ingestion_batch_id
loaded_at
```

For data engineering pipelines, these are especially useful:

```text
source_system
source_file
ingestion_batch_id
loaded_at
```

They help answer:

```text
Where did this row come from?
When was it loaded?
Which pipeline run created it?
Can we trace bad data back to the source?
```

## Soft deletes vs hard deletes

### Hard delete

The row is physically removed:

```sql
DELETE FROM customer
WHERE customer_id = 10;
```

### Soft delete

The row remains but is marked as deleted or inactive:

```text
is_deleted = true
deleted_at = timestamp
```

In banking, hard deletes can be dangerous because historical and regulatory records matter.

Often, instead of deleting accounts, we close them:

```text
account_status = 'CLOSED'
close_date = '2026-06-24'
```

This preserves history.

## Naming conventions

Good naming makes models easier to understand.

Weak names:

```text
tblCust
accNo
trans_amt
data1
final_final_table
```

Better names:

```text
customer
account
account_holder
account_transaction
transaction_type
```

Recommended convention:

```text
lowercase snake_case
singular table names
clear suffixes like _id, _code, _name, _date, _datetime, _amount
```

Examples:

```text
customer_id
account_id
transaction_datetime
transaction_reference
closing_balance
```

## Database-specific differences

The same logical model may be implemented differently depending on the platform.

Examples:

```text
PostgreSQL: strong relational constraints and indexing
MySQL: common for application systems, syntax differs slightly
BigQuery: no traditional indexes, uses partitioning and clustering
Snowflake: cloud warehouse with micro-partitions
SQL Server: enterprise relational database with strong indexing features
```

Physical modelling is platform-aware.

## Common mistakes

### Mistake 1: Storing dates as text

Bad:

```sql
transaction_date VARCHAR(20)
```

Better:

```sql
transaction_date DATE
```

### Mistake 2: Using FLOAT for money

Bad:

```sql
amount FLOAT
```

Better:

```sql
amount NUMERIC(18, 2)
```

### Mistake 3: No constraints

Bad:

```sql
account_number VARCHAR(50)
```

Better:

```sql
account_number VARCHAR(50) NOT NULL UNIQUE
```

### Mistake 4: Indexing everything

Too many indexes slow down inserts and updates.

Index based on query patterns.

### Mistake 5: No audit fields

In data engineering, audit fields help with debugging and lineage.

### Mistake 6: Using reserved words as table names

Avoid names like:

```text
transaction
order
user
group
```

Use safer names:

```text
account_transaction
sales_order
app_user
user_group
```

## Physical modelling checklist

Before accepting a physical model, ask:

```text
Are data types appropriate?
Are primary keys defined?
Are foreign keys needed and defined?
Are required fields marked NOT NULL?
Are business keys protected with UNIQUE constraints?
Are valid values protected with CHECK constraints or lookup tables?
Are large tables indexed properly?
Are large date-based tables partitioned where needed?
Are audit columns included?
Are table and column names consistent?
Are reserved words avoided?
Does the physical design match expected query patterns?
```

## Key takeaways

* Logical modelling defines what tables and relationships should exist.
* Physical modelling defines how those tables are implemented in a real database.
* Data types matter.
* Constraints protect correctness.
* Indexes improve reads but must be used carefully.
* Partitioning helps large date-based tables.
* Audit columns support lineage and debugging.
* Naming conventions improve maintainability.
* Physical design depends on the database platform.