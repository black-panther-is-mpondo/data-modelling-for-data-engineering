# Logical Model Diagram

This diagram shows the logical data model for the banking capstone project.

The logical model converts the conceptual business model into structured tables, keys, and relationships.

## Logical ERD

```mermaid
erDiagram
    CUSTOMER ||--o{ CUSTOMER_SEGMENT_HISTORY : has
    CUSTOMER_SEGMENT ||--o{ CUSTOMER_SEGMENT_HISTORY : classifies

    CUSTOMER ||--o{ ACCOUNT_HOLDER : holds
    ACCOUNT ||--o{ ACCOUNT_HOLDER : has_holder

    PRODUCT ||--o{ ACCOUNT : classifies
    BRANCH ||--o{ ACCOUNT : manages

    ACCOUNT ||--o{ ACCOUNT_STATUS_HISTORY : has
    ACCOUNT_STATUS ||--o{ ACCOUNT_STATUS_HISTORY : classifies

    ACCOUNT ||--o{ ACCOUNT_TRANSACTION : has
    TRANSACTION_TYPE ||--o{ ACCOUNT_TRANSACTION : classifies
    CHANNEL ||--o{ ACCOUNT_TRANSACTION : used_by

    ACCOUNT ||--o{ DAILY_ACCOUNT_BALANCE : has

    CUSTOMER {
        bigint customer_id PK
        varchar customer_number UK
        varchar national_id UK
        varchar passport_number
        varchar first_name
        varchar last_name
        date date_of_birth
        varchar customer_type
    }

    CUSTOMER_SEGMENT {
        bigint customer_segment_id PK
        varchar customer_segment_code UK
        varchar customer_segment_name
    }

    CUSTOMER_SEGMENT_HISTORY {
        bigint customer_segment_history_id PK
        bigint customer_id FK
        bigint customer_segment_id FK
        date effective_from_date
        date effective_to_date
        boolean is_current
    }

    PRODUCT {
        bigint product_id PK
        varchar product_code UK
        varchar product_name
        varchar product_category
    }

    BRANCH {
        bigint branch_id PK
        varchar branch_code UK
        varchar branch_name
        varchar province
        varchar city
    }

    ACCOUNT {
        bigint account_id PK
        varchar account_number UK
        bigint product_id FK
        bigint branch_id FK
        date open_date
        date close_date
    }

    ACCOUNT_STATUS {
        bigint account_status_id PK
        varchar account_status_code UK
        varchar account_status_name
    }

    ACCOUNT_STATUS_HISTORY {
        bigint account_status_history_id PK
        bigint account_id FK
        bigint account_status_id FK
        date effective_from_date
        date effective_to_date
        boolean is_current
    }

    ACCOUNT_HOLDER {
        bigint account_holder_id PK
        bigint customer_id FK
        bigint account_id FK
        varchar holder_role
        numeric ownership_percentage
        date start_date
        date end_date
    }

    CHANNEL {
        bigint channel_id PK
        varchar channel_code UK
        varchar channel_name
        varchar channel_group
    }

    TRANSACTION_TYPE {
        bigint transaction_type_id PK
        varchar transaction_type_code UK
        varchar transaction_type_name
        varchar transaction_category
    }

    ACCOUNT_TRANSACTION {
        bigint transaction_id PK
        varchar transaction_reference UK
        bigint account_id FK
        bigint transaction_type_id FK
        bigint channel_id FK
        timestamp transaction_datetime
        date posted_date
        numeric amount
        char currency_code
        varchar description
    }

    DAILY_ACCOUNT_BALANCE {
        bigint daily_account_balance_id PK
        bigint account_id FK
        date balance_date
        numeric opening_balance
        numeric closing_balance
        numeric available_balance
        char currency_code
    }
```

## Table grains

```text
customer:
One row per customer.

customer_segment:
One row per customer segment.

customer_segment_history:
One row per customer segment assignment for a time period.

product:
One row per banking product.

branch:
One row per branch.

account:
One row per bank account.

account_status:
One row per account status.

account_status_history:
One row per account status assignment for a time period.

account_holder:
One row per customer-account relationship.

channel:
One row per transaction channel.

transaction_type:
One row per transaction type.

account_transaction:
One row per posted account transaction.

daily_account_balance:
One row per account per day.
```

## Main many-to-many relationship

The many-to-many relationship is:

```text
Customer many-to-many Account
```

Resolved by:

```text
account_holder
```

Expanded:

```text
customer 1 --- many account_holder
account  1 --- many account_holder
```

## Important design notes

### Account holder

`account_holder` is not just a technical bridge.

It stores business meaning about the customer-account relationship:

```text
holder_role
ownership_percentage
start_date
end_date
```

### Transaction grain

`account_transaction` stays at account grain.

It does not directly store `customer_id`.

This avoids accidental double-counting in joint account scenarios.

### Balance grain

`daily_account_balance` is separate from `account_transaction`.

A transaction is an event.

A balance is a daily snapshot.

### History

Customer segment and account status are historised through:

```text
customer_segment_history
account_status_history
```

This protects historical reporting.
