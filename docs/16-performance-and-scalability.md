# Module 16: Performance and Scalability

## Goal

The goal of this module is to understand how modelling decisions affect query performance, pipeline performance, and long-term scalability.

A model can be logically correct but still perform badly if it ignores how data will be queried, loaded, and maintained.

Good modelling asks:

```text
Will this model still work when the data grows?
Will queries still be fast enough?
Will pipelines still load reliably?
Can the platform scale without becoming messy?
````

## What performance means

Performance is about how efficiently the system works.

Examples:

```text
A dashboard opens in seconds instead of minutes.
A daily pipeline finishes before business users arrive.
A report scans only the data it needs.
A query uses indexes or partitions properly.
A table design avoids unnecessary joins.
```

Performance is not only a database problem. It starts in the data model.

## What scalability means

Scalability means the model and platform can handle growth.

Growth can happen in many ways:

```text
More rows
More columns
More users
More reports
More source systems
More history
More refreshes
More business rules
```

A scalable model should not break every time the business grows.

## Performance starts with grain

Grain affects performance because it controls the number of rows.

Example:

```text
fact_transaction:
One row per transaction.
```

This can become very large.

Example:

```text
fact_daily_account_balance:
One row per account per day.
```

This also grows quickly.

Before building a table, estimate:

```text
How many rows per day?
How many rows per month?
How many rows per year?
How long will history be kept?
How often will the table be queried?
```

## Banking example

Suppose a bank has:

```text
2 million accounts
10 million transactions per day
1 daily balance row per account per day
```

That means:

```text
fact_transaction:
10 million rows per day

fact_daily_account_balance:
2 million rows per day
```

Over one year:

```text
fact_transaction:
3.65 billion rows

fact_daily_account_balance:
730 million rows
```

This affects:

```text
Storage
Indexes
Partitions
Pipeline design
Aggregation strategy
Dashboard design
```

## Indexing

Indexes help databases find rows faster.

Example:

```sql
CREATE INDEX idx_account_transaction_account_id
ON account_transaction(account_id);
```

This helps queries that filter by `account_id`.

Example:

```sql
SELECT *
FROM account_transaction
WHERE account_id = 123;
```

## When indexes help

Indexes help when queries often filter, join, or sort by a column.

Common examples:

```text
Foreign key columns
Date columns used in filters
Business keys used in lookups
Columns used in joins
Columns used in frequent search conditions
```

Banking examples:

```sql
CREATE INDEX idx_account_transaction_posted_date
ON account_transaction(posted_date);

CREATE INDEX idx_account_transaction_account_id
ON account_transaction(account_id);

CREATE INDEX idx_account_holder_customer_id
ON account_holder(customer_id);

CREATE INDEX idx_account_holder_account_id
ON account_holder(account_id);
```

## Indexing mistake

Do not index every column.

Indexes improve reads, but they add cost to writes.

Every insert, update, or delete may need to update indexes.

Bad approach:

```text
Index every column just in case.
```

Better approach:

```text
Index based on real query patterns.
```

## Partitioning

Partitioning splits a large table into smaller physical parts.

For large fact tables, partitioning is often more important than normal indexing.

Common partition columns:

```text
posted_date
balance_date
load_date
year
month
```

Banking example:

```text
fact_transaction partitioned by posted_date
fact_daily_account_balance partitioned by balance_date
```

This helps date-filtered queries.

Example:

```sql
SELECT
    SUM(transaction_amount) AS total_amount
FROM fact_transaction
WHERE posted_date >= DATE '2026-06-01'
  AND posted_date < DATE '2026-07-01';
```

If the table is partitioned by `posted_date`, the database or query engine can scan only the June 2026 data.

## Partitioning mistake

Bad partitioning can hurt performance.

Too broad:

```text
Partition by year only
```

This may still scan huge partitions.

Too granular:

```text
Partition by transaction_id
```

This creates too many tiny partitions.

Better:

```text
Partition by month or day depending on volume and query patterns.
```

## Clustering and ordering

Some platforms support clustering, sorting, or ordering data within partitions.

Examples:

```text
BigQuery clustering
Snowflake micro-partition pruning
Delta Lake Z-ordering
PostgreSQL clustered indexes
```

The idea is to physically organise data so related rows are easier to find.

Banking example:

```text
Partition fact_transaction by posted_date.
Cluster or sort by account_id, channel_key, or product_key.
```

Choose clustering columns based on common filters and joins.

## Denormalisation for analytics

Normalised models reduce duplication, but they can require many joins.

For analytics, controlled denormalisation can improve usability and performance.

Example:

Instead of forcing dashboard users to join:

```text
account
product
branch
transaction
```

a dimensional model may provide:

```text
fact_transaction
dim_product
dim_branch
dim_channel
dim_date
```

This is easier for reporting.

In some cases, frequently used dimension attributes may be included directly in a reporting table or aggregate table.

But denormalisation should be intentional and documented.

## Aggregation tables

Aggregation tables store pre-calculated summaries.

Example:

```text
agg_monthly_transaction_by_product
```

Grain:

```text
One row per product per month.
```

Columns:

```text
month_key
product_key
transaction_count
total_transaction_amount
total_fee_amount
```

This helps dashboards that do not need transaction-level detail.

## Banking aggregation example

Detailed fact:

```text
fact_transaction
- one row per transaction
```

Aggregate:

```text
agg_monthly_transaction_by_channel
- one row per month per channel
```

Example query becomes much faster because it scans fewer rows.

Instead of scanning billions of transactions, the dashboard scans a smaller monthly summary table.

## Materialised views

A materialised view stores the result of a query physically.

Example:

```sql
CREATE MATERIALIZED VIEW mv_monthly_transaction_by_channel AS
SELECT
    date_trunc('month', posted_date) AS transaction_month,
    channel_id,
    COUNT(*) AS transaction_count,
    SUM(amount) AS total_amount
FROM account_transaction
GROUP BY
    date_trunc('month', posted_date),
    channel_id;
```

This can improve reporting speed.

But materialised views must be refreshed, monitored, and documented.

## Incremental loading

Scalable pipelines avoid reprocessing all data every time.

Bad approach:

```text
Reload all transactions every day.
```

Better approach:

```text
Load only new or changed transactions.
```

Common incremental strategies:

```text
Load by created_at
Load by updated_at
Load by posted_date
Load by ingestion batch
Use change data capture
Use source system watermarks
```

Banking example:

```text
Every day, load transactions posted since the last successful load.
```

## Change Data Capture

Change Data Capture, or CDC, captures inserts, updates, and deletes from source systems.

CDC is useful when:

```text
Tables are large
Only small changes happen daily
Near-real-time processing is needed
History matters
```

Examples of CDC tools or patterns:

```text
Database logs
Debezium
AWS DMS
Timestamp-based extraction
Source audit tables
```

CDC helps reduce unnecessary full reloads.

## Slowly changing dimensions and performance

Type 2 dimensions can grow because every important change creates a new row.

Example:

```text
dim_customer
```

may have multiple rows per customer over time.

Performance considerations:

```text
Keep business keys indexed.
Keep current-row filters efficient.
Avoid overlapping effective dates.
Use surrogate keys in fact tables.
```

Good fact design:

```text
fact_transaction stores customer_key directly.
```

This avoids expensive date-range joins during reporting.

## Avoiding double-counting

Performance is useless if the numbers are wrong.

Many-to-many relationships can cause double-counting.

Banking example:

```text
One account has two customers.
One transaction belongs to the account.
```

If the transaction is joined to both customers, the amount may double.

To scale analytics correctly:

```text
Define bridge table rules.
Use allocation percentages where needed.
Separate account-level and customer-level reporting.
Document the reporting logic.
```

## Query patterns

A model should be designed around expected query patterns.

Ask:

```text
Will users mostly query by date?
By customer?
By account?
By branch?
By product?
By channel?
By month?
```

Banking examples:

```text
Transactions by month and channel
Balances by product and branch
Customer activity by segment
Account counts by status
```

These patterns influence:

```text
Partitions
Indexes
Aggregates
Star schema design
Clustering
Materialised views
```

## Wide tables vs narrow tables

A wide table has many columns.

A narrow table has fewer columns.

Wide tables can be useful for reporting because users need fewer joins.

But they can become difficult to maintain if they contain unrelated grains.

Bad wide table:

```text
customer_account_transaction_balance_summary
```

This likely mixes too many concepts.

Better:

```text
fact_transaction
fact_daily_account_balance
dim_customer
dim_account
```

Do not confuse convenience with good design.

## Archiving

Large systems need archiving strategies.

Example:

```text
Keep 7 years of transaction history.
Keep recent 2 years in hot storage.
Move older data to cheaper cold storage.
Keep summaries for long-term trend reporting.
```

Archiving affects:

```text
Cost
Performance
Compliance
Reprocessing
Historical reporting
```

## Performance monitoring

Performance should be measured.

Examples:

```text
Pipeline run duration
Query execution time
Dashboard load time
Rows processed per run
Data scanned per query
Failed or slow queries
Storage growth over time
```

Without monitoring, performance problems are found too late.

## Common mistakes

### Mistake 1: Designing only for today’s data volume

A model that works for 10,000 rows may fail at 1 billion rows.

Think ahead.

### Mistake 2: No clear grain

Unclear grain leads to poor queries, wrong totals, and bad aggregates.

### Mistake 3: Ignoring query patterns

Indexes, partitions, and aggregates should match how users query the data.

### Mistake 4: Full reloads forever

Full reloads become expensive as data grows.

Use incremental loads where possible.

### Mistake 5: Over-indexing

Too many indexes slow down writes and increase storage.

### Mistake 6: No aggregate layer

Dashboards should not always scan detailed transaction-level tables.

Create summary tables when needed.

## Performance and scalability checklist

Before accepting a model, ask:

```text
What is the grain of each large table?
How many rows will the table receive daily?
How many years of history are required?
What are the common query filters?
Should large tables be partitioned?
Which columns need indexes?
Are dashboards querying detail tables unnecessarily?
Do we need aggregate tables?
Can the pipeline load incrementally?
Do Type 2 dimensions have efficient keys?
Could any joins cause double-counting?
Is performance being monitored?
```

## Key takeaways

* Performance starts with modelling decisions.
* Grain controls table size and reporting meaning.
* Indexes help reads but can slow writes.
* Partitioning is critical for large date-based tables.
* Aggregates and materialised views can improve dashboards.
* Incremental loading is important for scalable pipelines.
* Query patterns should guide physical design.
* Scalability means the model can handle future growth without becoming unreliable.
