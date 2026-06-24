# 03: Logical Model

## Purpose

This document defines the logical data model for the banking capstone project.

The logical model converts the conceptual model into a structured set of tables, columns, keys, relationships, grains, and business rules.

It is still mostly database-independent. Physical details such as exact SQL syntax, indexes, and partitions are handled in the physical model.

## Logical modelling goal

The goal is to create a clean model that supports:

```text
Customers
Accounts
Joint account ownership
Products
Branches
Transactions
Channels
Daily balances
Customer segment history
Account status history
````

The model must also avoid common banking modelling problems such as:

```text
Forcing one customer per account
Mixing transactions and balances
Overwriting historical segment or status changes
Double-counting transactions for joint accounts
```

## Tables

The logical model contains the following tables:

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

## Table grains

Every table must have a clear grain.

```text
customer:
One row per customer.

customer_segment:
One row per customer segment.

customer_segment_history:
One row per customer segment assignment for a time period.

branch:
One row per bank branch.

product:
One row per banking product.

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
One row per account per balance date.
```

## Customer

Stores one row per customer.

```text
customer
- customer_id PK
- customer_number UNIQUE
- national_id UNIQUE NULLABLE
- passport_number NULLABLE
- first_name
- last_name
- date_of_birth
- customer_type
- created_date
```

### Notes

`customer_id` is the internal primary key.

`customer_number` is the business key used by the bank.

`national_id` is nullable because not all customers may have a South African national ID.

`passport_number` is nullable because it only applies to some customers.

## Customer Segment

Stores the allowed customer segments.

```text
customer_segment
- customer_segment_id PK
- customer_segment_code UNIQUE
- customer_segment_name
```

Example values:

```text
STUDENT
MASS_MARKET
MIDDLE_INCOME
PREMIUM
PRIVATE_BANKING
BUSINESS
```

## Customer Segment History

Tracks how a customer's segment changes over time.

```text
customer_segment_history
- customer_segment_history_id PK
- customer_id FK
- customer_segment_id FK
- effective_from_date
- effective_to_date NULLABLE
- is_current
```

### Grain

```text
One row per customer segment assignment for a time period.
```

### Notes

This table supports historical reporting.

A customer can move from one segment to another, and the model should not lose the old segment.

Example:

```text
Customer C001:
Student from 2025-01-01 to 2025-12-31
Premium from 2026-01-01 onwards
```

## Branch

Stores one row per branch.

```text
branch
- branch_id PK
- branch_code UNIQUE
- branch_name
- province
- city
```

A branch can manage many accounts.

## Product

Stores one row per banking product.

```text
product
- product_id PK
- product_code UNIQUE
- product_name
- product_category
```

A product can classify many accounts.

Example products:

```text
Savings Account
Current Account
Fixed Deposit
Business Account
```

## Account

Stores one row per bank account.

```text
account
- account_id PK
- account_number UNIQUE
- product_id FK
- branch_id FK
- open_date
- close_date NULLABLE
```

### Notes

An account belongs to one product.

An account belongs to one branch.

`close_date` is nullable because active accounts are not closed.

Current account status is not stored directly here in this logical model because status history is tracked separately.

## Account Status

Stores allowed account statuses.

```text
account_status
- account_status_id PK
- account_status_code UNIQUE
- account_status_name
```

Example values:

```text
ACTIVE
DORMANT
SUSPENDED
CLOSED
```

## Account Status History

Tracks account status changes over time.

```text
account_status_history
- account_status_history_id PK
- account_id FK
- account_status_id FK
- effective_from_date
- effective_to_date NULLABLE
- is_current
```

### Grain

```text
One row per account status assignment for a time period.
```

### Notes

This table supports historical status reporting.

Example:

```text
Account ACC100:
ACTIVE from 2025-01-01 to 2025-08-31
SUSPENDED from 2025-09-01 to 2025-09-10
ACTIVE from 2025-09-11 onwards
```

## Account Holder

Stores the relationship between customers and accounts.

```text
account_holder
- account_holder_id PK
- customer_id FK
- account_id FK
- holder_role
- ownership_percentage NULLABLE
- start_date
- end_date NULLABLE
```

### Grain

```text
One row per customer-account relationship.
```

### Why this table exists

Customer and Account have a many-to-many relationship.

```text
One customer can hold many accounts.
One account can be held by many customers.
```

The `account_holder` table resolves this many-to-many relationship.

### Example

```text
customer_id | account_id | holder_role
------------|------------|------------
1           | 100        | PRIMARY
2           | 100        | JOINT
1           | 200        | PRIMARY
```

This means account 100 is jointly held by customer 1 and customer 2.

## Channel

Stores one row per transaction channel.

```text
channel
- channel_id PK
- channel_code UNIQUE
- channel_name
- channel_group
```

Example values:

```text
BRANCH
ATM
MOBILE_APP
INTERNET_BANKING
CARD
USSD
CALL_CENTRE
```

## Transaction Type

Stores one row per transaction type.

```text
transaction_type
- transaction_type_id PK
- transaction_type_code UNIQUE
- transaction_type_name
- transaction_category
```

Example values:

```text
DEPOSIT
WITHDRAWAL
TRANSFER
CARD_PAYMENT
DEBIT_ORDER
FEE
INTEREST
```

## Account Transaction

Stores posted account transactions.

```text
account_transaction
- transaction_id PK
- transaction_reference UNIQUE
- account_id FK
- transaction_type_id FK
- channel_id FK
- transaction_datetime
- posted_date
- amount
- currency_code
- description NULLABLE
```

### Grain

```text
One row per posted account transaction.
```

### Notes

A transaction belongs to one account.

A transaction has one transaction type.

A transaction happens through one channel.

Transactions are modelled at account level, not customer level. This prevents automatic double-counting for joint accounts.

## Daily Account Balance

Stores daily account balance snapshots.

```text
daily_account_balance
- daily_account_balance_id PK
- account_id FK
- balance_date
- opening_balance
- closing_balance
- available_balance
- currency_code
```

### Grain

```text
One row per account per day.
```

### Notes

This table is separate from `account_transaction` because balances are snapshots, not events.

There should be only one balance record per account per date.

## Relationship summary

```text
customer 1 --- many customer_segment_history
customer_segment 1 --- many customer_segment_history

branch 1 --- many account
product 1 --- many account

account 1 --- many account_status_history
account_status 1 --- many account_status_history

customer 1 --- many account_holder
account 1 --- many account_holder

account 1 --- many account_transaction
transaction_type 1 --- many account_transaction
channel 1 --- many account_transaction

account 1 --- many daily_account_balance
```

## Many-to-many relationship

The main many-to-many relationship is:

```text
customer many --- many account
```

Resolved by:

```text
account_holder
```

Expanded relationship:

```text
customer 1 --- many account_holder
account 1 --- many account_holder
```

## Logical diagram

```text
customer
   | 1
   |--- many customer_segment_history many --- 1 customer_segment

customer
   | 1
   |--- many account_holder many --- 1 account
                                      |
                                      | many-to-one product
                                      |
                                      | many-to-one branch
                                      |
                                      | 1
                                      |--- many account_transaction
                                      |
                                      |--- many daily_account_balance
                                      |
                                      |--- many account_status_history many --- 1 account_status

account_transaction many-to-one transaction_type
account_transaction many-to-one channel
```

## Primary keys

```text
customer.customer_id
customer_segment.customer_segment_id
customer_segment_history.customer_segment_history_id
branch.branch_id
product.product_id
account.account_id
account_status.account_status_id
account_status_history.account_status_history_id
account_holder.account_holder_id
channel.channel_id
transaction_type.transaction_type_id
account_transaction.transaction_id
daily_account_balance.daily_account_balance_id
```

## Business keys and unique rules

```text
customer.customer_number must be unique.
customer.national_id should be unique when present.
branch.branch_code must be unique.
product.product_code must be unique.
account.account_number must be unique.
account_status.account_status_code must be unique.
customer_segment.customer_segment_code must be unique.
channel.channel_code must be unique.
transaction_type.transaction_type_code must be unique.
account_transaction.transaction_reference must be unique.
daily_account_balance must be unique by account_id and balance_date.
```

For history tables:

```text
customer_segment_history should not have overlapping date ranges for the same customer.
account_status_history should not have overlapping date ranges for the same account.
```

For account holders:

```text
customer_id + account_id + start_date should be unique.
```

This supports history and prevents duplicate relationship records.

## Optional fields

The following fields are nullable:

```text
customer.national_id
customer.passport_number
account.close_date
account_holder.ownership_percentage
account_holder.end_date
account_transaction.description
customer_segment_history.effective_to_date
account_status_history.effective_to_date
```

## Required fields

The following should be required:

```text
customer.customer_number
customer.first_name
customer.last_name
customer.customer_type

branch.branch_code
branch.branch_name

product.product_code
product.product_name

account.account_number
account.product_id
account.branch_id
account.open_date

account_holder.customer_id
account_holder.account_id
account_holder.holder_role
account_holder.start_date

account_transaction.transaction_reference
account_transaction.account_id
account_transaction.transaction_type_id
account_transaction.channel_id
account_transaction.transaction_datetime
account_transaction.posted_date
account_transaction.amount
account_transaction.currency_code

daily_account_balance.account_id
daily_account_balance.balance_date
daily_account_balance.opening_balance
daily_account_balance.closing_balance
daily_account_balance.available_balance
daily_account_balance.currency_code
```

## Business rules represented in the logical model

```text
A customer can exist without an account.
An account must have at least one account holder.
A customer can hold many accounts.
An account can have many customers.
An account belongs to one product.
An account belongs to one branch.
A transaction belongs to one account.
A transaction has one transaction type.
A transaction happens through one channel.
A daily balance belongs to one account.
There can only be one daily balance per account per date.
Customer segment changes are tracked over time.
Account status changes are tracked over time.
```

## Double-counting caution

Transactions belong to accounts.

They do not directly belong to customers.

This is important because of joint accounts.

If transactions are joined from account to account holder to customer, a single transaction can appear once per account holder.

Example:

```text
Account ACC100 has two holders.
Transaction T001 has amount R1,000.
Joining to both holders produces two rows.
If summed without care, the amount becomes R2,000.
```

Customer-level reporting must therefore use a defined business rule, such as:

```text
Report at account level only.
Assign to primary holder only.
Allocate by ownership percentage.
Use an explicit bridge table in the analytics model.
```

## Logical model outcome

The logical model is ready to be converted into a physical model.

The physical model will decide:

```text
SQL data types
NOT NULL constraints
UNIQUE constraints
CHECK constraints
Foreign key constraints
Indexes
Audit columns
Implementation syntax
```

## Key takeaway

The logical model protects the business structure.

The most important decisions are:

```text
Separate Customer and Account.
Resolve Customer and Account through Account Holder.
Keep Transactions at account grain.
Keep Daily Account Balance separate from Transactions.
Track Customer Segment and Account Status as history.
Define uniqueness and grain clearly.
```
