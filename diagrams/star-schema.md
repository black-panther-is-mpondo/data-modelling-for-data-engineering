# Star Schema Diagram

This diagram shows the analytics star schema for the banking capstone project.

The star schema is designed for reporting, dashboards, and business analysis.

## Transaction star schema

```mermaid
erDiagram
    DIM_DATE ||--o{ FACT_TRANSACTION : filters
    DIM_ACCOUNT ||--o{ FACT_TRANSACTION : describes
    DIM_PRODUCT ||--o{ FACT_TRANSACTION : describes
    DIM_BRANCH ||--o{ FACT_TRANSACTION : describes
    DIM_CHANNEL ||--o{ FACT_TRANSACTION : describes
    DIM_TRANSACTION_TYPE ||--o{ FACT_TRANSACTION : describes

    FACT_TRANSACTION {
        bigint transaction_key PK
        varchar transaction_reference
        bigint date_key FK
        bigint account_key FK
        bigint product_key FK
        bigint branch_key FK
        bigint channel_key FK
        bigint transaction_type_key FK
        numeric transaction_amount
        integer transaction_count
    }

    DIM_DATE {
        bigint date_key PK
        date full_date
        integer day_of_month
        varchar day_name
        integer week_number
        integer month_number
        varchar month_name
        integer quarter_number
        integer year
        boolean is_weekend
    }

    DIM_ACCOUNT {
        bigint account_key PK
        varchar account_number_masked
        date open_date
        date close_date
        varchar account_status
        date effective_from_date
        date effective_to_date
        boolean is_current
    }

    DIM_PRODUCT {
        bigint product_key PK
        varchar product_code
        varchar product_name
        varchar product_category
    }

    DIM_BRANCH {
        bigint branch_key PK
        varchar branch_code
        varchar branch_name
        varchar province
        varchar city
    }

    DIM_CHANNEL {
        bigint channel_key PK
        varchar channel_code
        varchar channel_name
        varchar channel_group
    }

    DIM_TRANSACTION_TYPE {
        bigint transaction_type_key PK
        varchar transaction_type_code
        varchar transaction_type_name
        varchar transaction_category
    }
```

## Daily balance star schema

```mermaid
erDiagram
    DIM_DATE ||--o{ FACT_DAILY_ACCOUNT_BALANCE : filters
    DIM_ACCOUNT ||--o{ FACT_DAILY_ACCOUNT_BALANCE : describes
    DIM_PRODUCT ||--o{ FACT_DAILY_ACCOUNT_BALANCE : describes
    DIM_BRANCH ||--o{ FACT_DAILY_ACCOUNT_BALANCE : describes
    DIM_ACCOUNT_STATUS ||--o{ FACT_DAILY_ACCOUNT_BALANCE : describes

    FACT_DAILY_ACCOUNT_BALANCE {
        bigint date_key FK
        bigint account_key FK
        bigint product_key FK
        bigint branch_key FK
        bigint account_status_key FK
        numeric opening_balance
        numeric closing_balance
        numeric available_balance
        integer account_count
    }

    DIM_ACCOUNT_STATUS {
        bigint account_status_key PK
        varchar account_status_code
        varchar account_status_name
    }
```

## Customer bridge for joint accounts

```mermaid
erDiagram
    DIM_ACCOUNT ||--o{ BRIDGE_ACCOUNT_CUSTOMER : has
    DIM_CUSTOMER ||--o{ BRIDGE_ACCOUNT_CUSTOMER : holds

    BRIDGE_ACCOUNT_CUSTOMER {
        bigint account_key FK
        bigint customer_key FK
        varchar holder_role
        numeric allocation_percentage
        date effective_from_date
        date effective_to_date
        boolean is_current
    }

    DIM_CUSTOMER {
        bigint customer_key PK
        varchar customer_number
        varchar customer_type
        varchar age_band
        varchar province
        varchar customer_segment
        date effective_from_date
        date effective_to_date
        boolean is_current
    }
```

## Fact table grains

```text
fact_transaction:
One row per posted account transaction.

fact_daily_account_balance:
One row per account per day.
```

## Measures

```text
fact_transaction.transaction_amount:
Additive.

fact_transaction.transaction_count:
Additive.

fact_daily_account_balance.opening_balance:
Semi-additive.

fact_daily_account_balance.closing_balance:
Semi-additive.

fact_daily_account_balance.available_balance:
Semi-additive.

fact_daily_account_balance.account_count:
Semi-additive.
```

## Important reporting warning

Transactions belong to accounts.

Customers and accounts have a many-to-many relationship.

Because of this, customer-level transaction reporting must use a clear rule.

Possible rules:

```text
Report at account level only.
Assign transaction value to the primary holder.
Allocate transaction value by ownership percentage.
Allocate transaction value equally across account holders.
```

Without a rule, joining transactions to customers through account holders can double-count transaction amounts.

## Example path for account-level transaction reporting

```text
fact_transaction
    → dim_date
    → dim_account
    → dim_product
    → dim_branch
    → dim_channel
    → dim_transaction_type
```

## Example path for customer-level transaction reporting

```text
fact_transaction
    → dim_account
    → bridge_account_customer
    → dim_customer
```

Use allocation logic when summing transaction values by customer.

## Key takeaway

The star schema separates business events and snapshots into different fact tables:

```text
fact_transaction
fact_daily_account_balance
```

It uses dimensions to make reporting easier:

```text
dim_date
dim_account
dim_product
dim_branch
dim_channel
dim_transaction_type
dim_customer
```

It uses a bridge table to handle joint account reporting:

```text
bridge_account_customer
```
