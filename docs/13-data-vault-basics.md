# Module 13: Data Vault Basics

## Goal

The goal of this module is to understand the basic idea of Data Vault modelling and why it is useful in data engineering.

Data Vault is mainly used in data warehouses where we need to handle:

- multiple source systems
- changing data over time
- auditability
- historical tracking
- scalable ingestion
- source traceability

## Core idea

Data Vault separates data into three main structure types:

```text
Hub
Link
Satellite
````

Simple version:

```text
Hub = business key
Link = relationship
Satellite = descriptive history
```

## Why Data Vault exists

In a normal relational model, we may create tables like:

```text
customer
account
account_holder
transaction
```

That works well for many systems.

But in enterprise data warehouses, data can come from many systems:

```text
Core banking system
Mobile banking app
CRM system
Loan system
Card system
Fraud system
Call centre system
```

Each source may have different versions of the same business concept.

For example, customer data may appear in:

```text
CRM
Core banking
Loan origination
Card platform
```

Data Vault helps store this data historically and traceably without forcing all sources into one perfect model too early.

## Hub

A hub stores a unique business key.

Examples:

```text
Customer
Account
Product
Branch
Transaction
```

A hub does not store descriptive attributes like name, province, segment, or status.

It stores the stable business identity.

Example:

```text
hub_customer
- customer_hk
- customer_number
- load_datetime
- record_source
```

Here:

```text
customer_number
```

is the business key.

```text
customer_hk
```

is usually a hash key generated from the business key.

## Link

A link stores a relationship between hubs.

Example relationship:

```text
Customer holds Account
```

Data Vault version:

```text
link_account_holder
- account_holder_hk
- customer_hk
- account_hk
- load_datetime
- record_source
```

This links:

```text
hub_customer
hub_account
```

Another relationship:

```text
Account belongs to Branch
```

Possible link:

```text
link_account_branch
- account_branch_hk
- account_hk
- branch_hk
- load_datetime
- record_source
```

Links are useful because relationships can change and can come from different source systems.

## Satellite

A satellite stores descriptive attributes and history.

Example customer satellite:

```text
sat_customer_details
- customer_hk
- first_name
- last_name
- date_of_birth
- customer_type
- load_datetime
- record_source
- hashdiff
```

Example customer segment satellite:

```text
sat_customer_segment
- customer_hk
- customer_segment
- risk_rating
- effective_from_date
- load_datetime
- record_source
- hashdiff
```

A satellite hangs off a hub or link.

It answers:

```text
What did we know about this business key?
When did we know it?
Where did it come from?
Did the descriptive values change?
```

## Data Vault banking example

Business model:

```text
Customer holds Account
Account belongs to Product
Account has Transactions
Branch manages Account
```

Data Vault structures:

```text
hub_customer
hub_account
hub_product
hub_branch
hub_transaction
```

Links:

```text
link_account_holder
link_account_product
link_account_branch
link_account_transaction
```

Satellites:

```text
sat_customer_details
sat_customer_segment
sat_account_details
sat_account_status
sat_product_details
sat_branch_details
sat_transaction_details
```

## Example: Customer

### Hub

```text
hub_customer
- customer_hk
- customer_number
- load_datetime
- record_source
```

### Satellite

```text
sat_customer_details
- customer_hk
- first_name
- last_name
- date_of_birth
- customer_type
- load_datetime
- record_source
- hashdiff
```

### Segment satellite

```text
sat_customer_segment
- customer_hk
- customer_segment
- risk_rating
- load_datetime
- record_source
- hashdiff
```

Why split details and segment?

Because they may change at different rates and may come from different sources.

Customer details may come from CRM.

Customer segment may come from an analytics or risk system.

## Example: Account holder relationship

In a normal model:

```text
account_holder
- customer_id
- account_id
- holder_role
- start_date
- end_date
```

In Data Vault:

```text
hub_customer
hub_account
link_account_holder
sat_account_holder_details
```

Link:

```text
link_account_holder
- account_holder_hk
- customer_hk
- account_hk
- load_datetime
- record_source
```

Satellite on the link:

```text
sat_account_holder_details
- account_holder_hk
- holder_role
- ownership_percentage
- effective_from_date
- effective_to_date
- load_datetime
- record_source
- hashdiff
```

The link records the relationship.

The satellite records descriptive details about that relationship.

## Hash keys

Data Vault often uses hash keys.

Example:

```text
customer_hk = hash(customer_number)
account_hk = hash(account_number)
```

Hash keys are useful because:

```text
They are consistent across loads.
They can be generated before database insertion.
They support parallel loading.
They avoid dependence on database identity columns.
They work well in distributed data platforms.
```

## Hashdiff

A hashdiff is a hash of descriptive satellite attributes.

Example:

```text
hashdiff = hash(first_name, last_name, date_of_birth, customer_type)
```

It helps detect whether a satellite record has changed.

If the hashdiff is the same as the latest record, there may be no change to insert.

If the hashdiff is different, insert a new satellite record.

## Record source

`record_source` stores where the row came from.

Examples:

```text
CRM
CORE_BANKING
MOBILE_APP
CARD_PLATFORM
LOAN_SYSTEM
```

This is critical for lineage.

It helps answer:

```text
Which system supplied this value?
Where did this customer record come from?
Which source caused the change?
```

## Load datetime

`load_datetime` records when the row was loaded into the warehouse.

It is not always the same as the business effective date.

Example:

```text
effective_from_date = 2026-01-01
load_datetime = 2026-01-03 02:15:00
```

This means the business change started on 2026-01-01, but the warehouse loaded it on 2026-01-03.

Both dates can matter.

## Raw Vault vs Business Vault

## Raw Vault

Raw Vault stores data close to the source, with minimal business transformation.

It focuses on:

```text
Auditability
History
Traceability
Source alignment
```

## Business Vault

Business Vault adds business rules and derived logic.

Examples:

```text
Calculated customer risk band
Standardised customer segment
Derived active account indicator
Business-defined product grouping
```

Raw Vault captures what the source said.

Business Vault captures business interpretation.

## Data Vault to Dimensional Model

Data Vault is often not the final layer for BI users.

A common flow is:

```text
Source systems
    ↓
Raw Vault
    ↓
Business Vault
    ↓
Dimensional model / Data mart
    ↓
Reports and dashboards
```

Example:

```text
hub_customer + sat_customer_details + sat_customer_segment
    ↓
dim_customer

hub_account + sat_account_details + sat_account_status
    ↓
dim_account

hub_transaction + sat_transaction_details
    ↓
fact_transaction
```

Data Vault is excellent for integration and history.

Dimensional models are usually better for reporting.

## When Data Vault is useful

Data Vault is useful when:

```text
There are many source systems.
Source systems change often.
History and auditability are important.
Data lineage matters.
Loads need to be parallelised.
The warehouse needs to scale over time.
Business rules change often.
```

Banking, insurance, telecoms, and large enterprises often benefit from Data Vault patterns.

## When Data Vault may be too much

Data Vault can be overkill when:

```text
There is only one simple source.
The project is small.
The reporting requirement is basic.
The team does not need full historical traceability.
The extra modelling complexity is not worth it.
```

Do not use Data Vault just because it sounds advanced.

Use it when the problem needs it.

## Common mistakes

### Mistake 1: Putting descriptive attributes in hubs

Bad:

```text
hub_customer
- customer_hk
- customer_number
- first_name
- last_name
- segment
```

Better:

```text
hub_customer
- customer_hk
- customer_number
- load_datetime
- record_source

sat_customer_details
- customer_hk
- first_name
- last_name
- segment
- load_datetime
- record_source
```

A hub should store the business key, not descriptive history.

### Mistake 2: Skipping record source

Without `record_source`, lineage becomes weak.

You need to know where data came from.

### Mistake 3: Treating Data Vault as the BI layer

Data Vault tables are usually not friendly for business users.

For dashboards, build dimensional marts from the vault.

### Mistake 4: Creating hubs for everything

Not every code or attribute needs a hub.

A hub should represent a meaningful business concept with a stable business key.

### Mistake 5: Ignoring business keys

Data Vault depends heavily on business keys.

If the business key is poorly understood, the vault model will be weak.

## Data Vault checklist

Before using Data Vault, ask:

```text
What are the core business keys?
Which relationships need links?
Which descriptive attributes belong in satellites?
Which source systems provide each attribute?
Do we need full history?
Do we need record source tracking?
Do we need hash keys and hashdiffs?
Will BI users consume dimensional marts built from the vault?
Is Data Vault justified for this project?
```

## Key takeaways

* Data Vault separates business keys, relationships, and descriptive history.
* Hubs store business keys.
* Links store relationships between hubs.
* Satellites store descriptive attributes and history.
* Hash keys support scalable loading.
* Hashdiffs help detect changes.
* Record source supports lineage.
* Data Vault is strong for integration, auditability, and historical tracking.
* Dimensional models are usually still needed for reporting.
