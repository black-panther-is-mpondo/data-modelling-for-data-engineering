# Module 14: Data Lakes and Lakehouses

## Goal

The goal of this module is to understand how data modelling works in modern data platforms such as data lakes and lakehouses.

Traditional modelling is often discussed using relational databases and warehouses, but data engineers also work with files, object storage, distributed processing, and table formats.

## Core idea

A data lake stores large amounts of raw and processed data.

A lakehouse combines data lake flexibility with data warehouse-style structure and reliability.

Simple version:

```text
Data lake = flexible storage for raw and processed data
Data warehouse = structured storage for analytics
Lakehouse = data lake + warehouse-style table management
````

## Data lake

A data lake stores data in a flexible way, usually in object storage.

Examples of object storage:

```text
Amazon S3
Azure Data Lake Storage
Google Cloud Storage
MinIO
```

Data lakes can store many formats:

```text
CSV
JSON
Parquet
Avro
Images
Logs
Documents
API extracts
Database dumps
```

This is useful because source data is not always clean or relational.

## Data warehouse

A data warehouse is structured for analytics and reporting.

It usually stores curated data in well-defined tables.

Examples:

```text
Snowflake
BigQuery
Redshift
SQL Server Data Warehouse
PostgreSQL-based warehouse
```

A warehouse is usually stronger for:

```text
SQL analytics
BI reporting
Governed tables
Performance optimisation
Business metrics
```

## Lakehouse

A lakehouse tries to combine the flexibility of a data lake with the reliability of a warehouse.

Common lakehouse technologies include:

```text
Delta Lake
Apache Iceberg
Apache Hudi
```

They add table-management features on top of files.

Examples of features:

```text
ACID transactions
Schema enforcement
Schema evolution
Time travel
Versioning
Upserts and deletes
Partition management
```

## Why modelling still matters

Some people think data lakes mean no modelling is needed.

That is wrong.

A data lake without modelling becomes a data swamp.

A data swamp is a messy storage area where nobody trusts the data.

Problems include:

```text
Unclear file names
Unknown source systems
Duplicate datasets
No business definitions
No quality checks
No ownership
No reliable curated layer
```

Modelling is still needed to make data usable.

## Common lakehouse layers

A common data engineering pattern is:

```text
Bronze
Silver
Gold
```

These layers help separate raw data, cleaned data, and business-ready data.

## Bronze layer

The bronze layer stores raw or near-raw data.

Purpose:

```text
Preserve source data
Keep audit trail
Support reprocessing
Avoid losing original records
```

Example:

```text
bronze/core_banking/account_transactions/
bronze/crm/customers/
bronze/mobile_app/logins/
```

Bronze data may still contain:

```text
source column names
duplicates
invalid values
missing values
source-specific formats
```

Bronze is not usually the best layer for BI users.

## Silver layer

The silver layer stores cleaned and standardised data.

Purpose:

```text
Clean data types
Standardise column names
Deduplicate records
Apply basic quality rules
Resolve common formats
Prepare integrated entities
```

Example:

```text
silver/customer
silver/account
silver/account_transaction
silver/branch
silver/product
```

Silver data is more structured than bronze.

It often starts to look like a logical model.

## Gold layer

The gold layer stores business-ready data.

Purpose:

```text
Serve dashboards
Serve reports
Serve analytics
Serve machine learning features
Apply business definitions
Publish trusted metrics
```

Example:

```text
gold/fact_transaction
gold/fact_daily_account_balance
gold/dim_customer
gold/dim_account
gold/dim_product
```

The gold layer often uses dimensional modelling.

## Banking lakehouse example

Source systems:

```text
Core banking
CRM
Mobile banking app
Card platform
Branch system
```

Bronze layer:

```text
bronze/core_banking/accounts
bronze/core_banking/transactions
bronze/crm/customers
bronze/mobile_app/logins
bronze/card_platform/card_transactions
```

Silver layer:

```text
silver/customer
silver/account
silver/account_holder
silver/account_transaction
silver/product
silver/branch
silver/channel
```

Gold layer:

```text
gold/fact_transaction
gold/fact_daily_account_balance
gold/dim_customer
gold/dim_account
gold/dim_product
gold/dim_branch
gold/dim_channel
gold/dim_date
```

## Modelling by layer

Different layers have different modelling goals.

## Bronze modelling

Bronze focuses on source preservation.

Typical design:

```text
Keep source structure
Add ingestion metadata
Partition by ingestion date
Avoid heavy transformation
```

Useful metadata columns:

```text
source_system
source_file
ingestion_batch_id
ingested_at
raw_record_hash
```

Example:

```text
bronze_core_banking_transactions
- source_system
- source_file
- ingestion_batch_id
- ingested_at
- raw_payload
```

or if semi-structured:

```text
bronze_core_banking_transactions
- source_system
- source_file
- ingestion_batch_id
- ingested_at
- account_no
- txn_ref
- txn_date
- txn_amount
```

## Silver modelling

Silver focuses on clean, reusable entities.

Typical design:

```text
Standardise names
Standardise data types
Apply basic validation
Deduplicate
Create business entities
Prepare relationships
```

Example:

```text
silver_account_transaction
- transaction_id
- transaction_reference
- account_id
- transaction_type_id
- channel_id
- transaction_datetime
- posted_date
- amount
- currency_code
- source_system
- loaded_at
```

Silver is often closer to a normalised model.

It is useful for data engineering reuse.

## Gold modelling

Gold focuses on business consumption.

Typical design:

```text
Dimensional models
Aggregated marts
Business metrics
Reporting-friendly tables
Semantic consistency
```

Example:

```text
gold_fact_transaction
- date_key
- account_key
- product_key
- branch_key
- channel_key
- transaction_type_key
- transaction_amount
- transaction_count
```

Gold is usually what BI tools consume.

## File formats

In lakehouses, physical modelling includes file format choices.

Common formats:

```text
CSV
JSON
Parquet
Avro
ORC
```

For analytics, Parquet is commonly preferred because it is:

```text
Columnar
Compressed
Efficient for scans
Good for analytical queries
```

CSV is simple, but weak for large-scale analytics.

Problems with CSV:

```text
No strong data types
Large file size
Slower scanning
Parsing issues
Poor schema enforcement
```

## Table formats

Lakehouse table formats manage files as tables.

Common formats:

```text
Delta Lake
Apache Iceberg
Apache Hudi
```

They help with:

```text
Schema evolution
ACID transactions
Time travel
Upserts
Deletes
Compaction
Metadata management
```

Without a table format, a lake can become a folder full of files with weak governance.

## Partitioning in the lakehouse

Partitioning physically organises data by selected columns.

Common partition columns:

```text
ingestion_date
posted_date
year
month
country
source_system
```

Banking example:

```text
gold/fact_transaction/posted_year=2026/posted_month=06/
```

Partitioning helps when queries filter on the partition column.

Example:

```sql
SELECT *
FROM gold_fact_transaction
WHERE posted_date >= DATE '2026-06-01'
  AND posted_date < DATE '2026-07-01';
```

Good partitioning can reduce how much data is scanned.

Bad partitioning can create too many small folders and slow down the system.

## Small files problem

Data lakes often suffer from too many small files.

Example:

```text
10 million tiny Parquet files
```

This can make queries slow because the engine spends too much time opening files.

Possible solutions:

```text
Compaction
Batching writes
Avoiding overly granular partitions
Using table optimisation commands
```

## Schema evolution

Schema evolution means the structure of data changes over time.

Examples:

```text
A new column is added
A column is renamed
A data type changes
A source system removes a field
```

Lakehouse table formats can help manage schema evolution, but the modelling decision still matters.

Ask:

```text
Is this a real business attribute?
Which layer should accept the change?
Does the gold model need this field?
Will old reports break?
Do we need backward compatibility?
```

## Data quality in a lakehouse

Data quality should improve by layer.

Bronze:

```text
Check that data arrived
Check file metadata
Check row counts
Check schema presence
```

Silver:

```text
Check primary keys
Check duplicates
Check required fields
Check valid codes
Check referential relationships
```

Gold:

```text
Check business metrics
Check aggregation logic
Check reporting totals
Check conformed dimensions
Check historical consistency
```

## Lakehouse modelling mistake

Bad approach:

```text
Dump everything into object storage
Let users figure it out
```

Better approach:

```text
Design layers
Define ownership
Document entities
Apply quality rules
Publish trusted gold models
```

## Data lake vs lakehouse vs warehouse

| Platform       | Main strength                           | Risk                    |
| -------------- | --------------------------------------- | ----------------------- |
| Data lake      | Flexible storage                        | Can become messy        |
| Data warehouse | Structured analytics                    | Can be less flexible    |
| Lakehouse      | Flexible storage with table reliability | Needs strong governance |

## Common mistakes

### Mistake 1: Treating bronze as trusted data

Bronze is raw or near-raw.

It should not be treated as business-ready.

### Mistake 2: No clear silver layer

Without silver, every gold model may clean the same source data differently.

That causes inconsistent metrics.

### Mistake 3: Building gold directly from messy raw files

This makes gold models fragile.

Better:

```text
bronze → silver → gold
```

### Mistake 4: No metadata columns

Without source and load metadata, debugging becomes difficult.

Always consider:

```text
source_system
source_file
ingestion_batch_id
loaded_at
```

### Mistake 5: Poor partitioning

Too few partitions can scan too much data.

Too many partitions can create operational overhead.

Partition based on real query patterns.

## Lakehouse modelling checklist

Before accepting a lakehouse design, ask:

```text
Do we have bronze, silver, and gold layers?
Is bronze preserving source data?
Is silver clean and reusable?
Is gold business-ready?
Are file formats appropriate?
Are table formats needed?
Are partitioning choices based on query patterns?
Are metadata and lineage columns included?
Are quality checks applied by layer?
Are gold tables documented for BI users?
Is the lake being governed, or is it becoming a swamp?
```

## Key takeaways

* Data lakes store flexible raw and processed data.
* Lakehouses add warehouse-style reliability to data lakes.
* Modelling still matters in lakehouse architecture.
* Bronze stores raw or near-raw data.
* Silver stores cleaned and standardised data.
* Gold stores business-ready analytics models.
* Parquet is usually better than CSV for analytical workloads.
* Table formats like Delta, Iceberg, and Hudi help manage lakehouse tables.
* Good partitioning improves performance.
* Without governance, a data lake can become a data swamp.
