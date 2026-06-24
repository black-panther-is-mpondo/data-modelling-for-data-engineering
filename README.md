# Data Modelling for Data Engineering

This repository documents my learning journey through data modelling for data engineering.

The goal is to understand how to move from business requirements to clean, reliable, scalable data models that support operational systems, analytics, reporting, and data warehouse design.

## What this repository covers

This repo is split into two main parts:

1. General data modelling notes
2. A banking end-to-end capstone project

## Course Notes

| Module | Topic |
|---|---|
| 01 | [What Is Data Modelling?](docs/01-what-is-data-modelling.md) |
| 02 | [Business Requirements Thinking](docs/02-business-requirements-thinking.md) |
| 03 | [Entities, Attributes, and Relationships](docs/03-entities-attributes-relationships.md) |
| 04 | [Keys and Identifiers](docs/04-keys-and-identifiers.md) |
| 05 | [Conceptual Data Modelling](docs/05-conceptual-data-modelling.md) |
| 06 | [Logical Data Modelling](docs/06-logical-data-modelling.md) |
| 07 | [Normalisation](docs/07-normalisation.md) |
| 08 | [Physical Data Modelling](docs/08-physical-data-modelling.md) |
| 09 | [OLTP vs OLAP Modelling](docs/09-oltp-vs-olap.md) |
| 10 | [Dimensional Modelling](docs/10-dimensional-modelling.md) |
| 11 | [Fact Table Types](docs/11-fact-table-types.md) |
| 12 | [Slowly Changing Dimensions](docs/12-slowly-changing-dimensions.md) |
| 13 | [Data Vault Basics](docs/13-data-vault-basics.md) |
| 14 | [Data Lakes and Lakehouses](docs/14-data-lakes-and-lakehouses.md) |
| 15 | [Data Quality and Governance](docs/15-data-quality-and-governance.md) |
| 16 | [Performance and Scalability](docs/16-performance-and-scalability.md) |
| 17 | [Data Model Documentation](docs/17-data-model-documentation.md) |

## Banking Capstone Project

The capstone applies the course concepts to a retail banking scenario.

| Section | Topic |
|---|---|
| 01 | [Business Requirements](banking-capstone/01-business-requirements.md) |
| 02 | [Conceptual Model](banking-capstone/02-conceptual-model.md) |
| 03 | [Logical Model](banking-capstone/03-logical-model.md) |
| 04 | [Physical Model](banking-capstone/04-physical-model.md) |
| 05 | [Analytics Star Schema](banking-capstone/05-analytics-star-schema.md) |
| 06 | [Data Quality Rules](banking-capstone/06-data-quality-rules.md) |
| 07 | [Documentation](banking-capstone/07-documentation.md) |
| SQL | [Banking Model DDL](banking-capstone/sql/banking_model_ddl.sql) |

## Main concepts

The main concepts covered include:

- Business requirements analysis
- Entities, attributes, and relationships
- Primary keys and foreign keys
- Conceptual, logical, and physical data models
- Normalisation
- OLTP vs OLAP modelling
- Dimensional modelling
- Fact and dimension tables
- Slowly changing dimensions
- Data Vault basics
- Lakehouse modelling
- Data quality and governance
- Performance and scalability
- Data model documentation

## Capstone focus

The banking capstone models:

- Customers
- Accounts
- Joint account ownership
- Products
- Branches
- Transactions
- Transaction types
- Channels
- Daily account balances
- Customer segment history
- Account status history

## Modelling flow

The general modelling process used in this repository is:

```text
Business requirements
→ Conceptual model
→ Logical model
→ Physical model
→ Analytics model
→ Data quality rules
→ Documentation
```
