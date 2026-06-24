# Module 06: Logical Data Modelling

## Goal

The goal of this module is to convert a conceptual model into a structured table design.

A logical model defines:

- tables
- columns
- primary keys
- foreign keys
- relationships
- optional and mandatory fields
- uniqueness rules
- resolving tables for many-to-many relationships

It is still mostly database-independent. We are not yet focusing deeply on PostgreSQL, MySQL, indexes, partitions, or storage details.

## What is logical data modelling?

Logical data modelling takes business ideas like this:

```text
Customer holds Account
Account has Transaction
Product classifies Account
Branch manages Account
````

And converts them into tables like this:

```text
customer
account
account_holder
account_transaction
product
branch
```

The conceptual model explains the business.

The logical model explains the data structure.

## Conceptual vs logical

Conceptual model:

```text
Customer holds Account
Account has Transaction
```

Logical model:

```text
customer
- customer_id
- customer_number
- first_name
- last_name
- date_of_birth

account
- account_id
- account_number
- product_id
- branch_id
- open_date
- close_date

account_holder
- account_holder_id
- customer_id
- account_id
- holder_role
- start_date
- end_date

account_transaction
- transaction_id
- account_id
- transaction_type_id
- channel_id
- transaction_datetime
- amount
```

The logical model is more precise.

## What a logical model must answer

A good logical model should answer:

```text
What tables do we need?
What does one row in each table represent?
What columns belong in each table?
What is the primary key?
What foreign keys connect the tables?
Which fields are required?
Which fields are optional?
Which values should be unique?
Which relationships are one-to-many?
Which relationships are many-to-many?
```

If these questions are not answered, the model is not ready.

## Step 1: Start from the conceptual model

Example conceptual model:

```text
Customer holds Account
Account belongs to Product
Branch manages Account
Account has Transaction
Transaction has Transaction Type
Transaction happens through Channel
```

Main entities:

```text
Customer
Account
Product
Branch
Transaction
Transaction Type
Channel
```

Many-to-many relationship:

```text
Customer many-to-many Account
```

Resolving entity:

```text
Account Holder
```

## Step 2: Create one table per strong entity

Strong entities can exist independently.

Examples:

```text
customer
account
product
branch
transaction_type
channel
```

`account_transaction` is also an important event table because transactions are business events.

## Step 3: Add resolving tables for many-to-many relationships

Because this relationship is many-to-many:

```text
Customer many-to-many Account
```

We create:

```text
account_holder
```

The model becomes:

```text
customer 1 --- many account_holder
account  1 --- many account_holder
```

The many-to-many relationship is now resolved into two one-to-many relationships.

## Step 4: Define the grain of each table

This is non-negotiable.

```text
customer:
One row per customer.

account:
One row per bank account.

account_holder:
One row per customer-account relationship.

product:
One row per banking product.

branch:
One row per branch.

account_transaction:
One row per posted account transaction.

transaction_type:
One row per transaction type.

channel:
One row per transaction channel.
```

If a table does not have a clear grain, it is not ready.

## Step 5: Add columns that belong at that grain

Columns must belong to the table’s grain.

### Customer table

```text
customer
- customer_id
- customer_number
- national_id
- passport_number
- first_name
- last_name
- date_of_birth
- customer_type
```

These columns describe the customer.

### Account table

```text
account
- account_id
- account_number
- product_id
- branch_id
- open_date
- close_date
```

These columns describe the account.

### Account holder table

```text
account_holder
- account_holder_id
- customer_id
- account_id
- holder_role
- ownership_percentage
- start_date
- end_date
```

These columns describe the relationship between a customer and an account.

`holder_role` belongs here because a customer can be the primary holder on one account and a joint holder on another.

### Account transaction table

```text
account_transaction
- transaction_id
- transaction_reference
- account_id
- transaction_type_id
- channel_id
- transaction_datetime
- posted_date
- amount
- currency_code
- description
```

These columns describe the transaction event.

## Banking logical model example

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

```text
branch
- branch_id PK
- branch_code UNIQUE
- branch_name
- province
- city
```

```text
product
- product_id PK
- product_code UNIQUE
- product_name
- product_category
```

```text
account
- account_id PK
- account_number UNIQUE
- product_id FK
- branch_id FK
- open_date
- close_date NULLABLE
```

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

```text
transaction_type
- transaction_type_id PK
- transaction_type_code UNIQUE
- transaction_type_name
- transaction_category
```

```text
channel
- channel_id PK
- channel_code UNIQUE
- channel_name
- channel_group
```

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
- description
```

## Why each table exists

### `customer`

Stores the person or organisation that has a relationship with the bank.

Grain:

```text
One row per customer.
```

Do not store transaction fields here.

Do not store account balance here.

Do not store reporting totals here.

### `account`

Stores the bank account itself.

Grain:

```text
One row per account.
```

Do not store customer name here because an account can have multiple customers.

Ownership is handled by `account_holder`.

### `account_holder`

Stores the relationship between customers and accounts.

Grain:

```text
One row per customer-account relationship.
```

This is where we store:

```text
holder_role
ownership_percentage
start_date
end_date
```

This table makes joint accounts possible.

### `account_transaction`

Stores account movements.

Grain:

```text
One row per posted account transaction.
```

Do not store customer attributes here.

A transaction belongs directly to an account. Customer relationships are found through `account_holder`.

## Attributes must belong to the correct table

Ask:

> Does this column describe this table’s grain?

Examples:

```text
customer.first_name
```

Correct. It describes the customer.

```text
account.open_date
```

Correct. It describes the account.

```text
account_transaction.amount
```

Correct. It describes the transaction.

```text
customer.account_status
```

Wrong. Account status belongs to the account, not the customer.

```text
account.holder_role
```

Wrong. Holder role belongs to the customer-account relationship, so it belongs in `account_holder`.

```text
account_transaction.customer_name
```

Wrong. That duplicates customer data and causes maintenance problems.

## Optional and mandatory fields

Logical modelling should decide which fields are required and which are optional.

Examples:

```text
customer.national_id
```

May be nullable because foreign nationals or business customers may not have a national ID.

```text
account.close_date
```

Nullable because active accounts are not closed.

```text
account_transaction.amount
```

Should not be nullable because a transaction must have an amount.

```text
account_transaction.account_id
```

Should not be nullable because every transaction must belong to an account.

```text
account_holder.end_date
```

Nullable because current account-holder relationships are still active.

## Uniqueness rules

Primary keys are not the only uniqueness rules.

Examples:

```text
customer.customer_number must be unique.
account.account_number must be unique.
branch.branch_code must be unique.
product.product_code must be unique.
transaction_type.transaction_type_code must be unique.
channel.channel_code must be unique.
account_transaction.transaction_reference must be unique.
```

For `account_holder`, if we track history:

```text
customer_id + account_id + start_date should be unique.
```

If we do not track history:

```text
customer_id + account_id should be unique.
```

The choice depends on the business rule.

## Relationship summary

```text
customer 1 --- many account_holder
account  1 --- many account_holder

branch 1 --- many account
product 1 --- many account

account 1 --- many account_transaction
transaction_type 1 --- many account_transaction
channel 1 --- many account_transaction
```

The important many-to-many relationship is:

```text
customer many --- many account
```

Resolved by:

```text
account_holder
```

## Logical model diagram

```text
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

account_transaction many-to-one transaction_type
account_transaction many-to-one channel
```

## Common mistakes

### Mistake 1: Putting foreign keys in the wrong place

Bad:

```text
branch
- branch_id
- account_id
```

A branch can have many accounts, so one `account_id` does not belong in `branch`.

Better:

```text
account
- account_id
- branch_id
```

### Mistake 2: Hiding many-to-many relationships

Bad:

```text
account
- account_id
- customer_id
```

This only works if one account can have one customer.

Better:

```text
account_holder
- account_id
- customer_id
```

### Mistake 3: Mixing grains

Bad:

```text
customer_account_transaction
- customer_name
- account_number
- transaction_amount
- current_balance
```

This mixes:

```text
customer grain
account grain
transaction grain
balance snapshot grain
```

That causes duplicate values and incorrect totals.

### Mistake 4: Using vague resolving table names

Weak:

```text
customer_account_map
```

Better:

```text
account_holder
```

A good table name explains the business meaning of one row.

## Logical model checklist

Before accepting a logical model, ask:

```text
Does every table have a clear grain?
Does every table have a primary key?
Are foreign keys placed correctly?
Are many-to-many relationships resolved?
Do columns belong to the table’s grain?
Are optional fields clearly identified?
Are uniqueness rules defined?
Are lookup/reference tables separated where useful?
Can the model answer the business requirement?
```

## Key takeaways

* A logical model turns business concepts into structured tables.
* It defines tables, columns, keys, relationships, and rules.
* Every table must have a clear grain.
* Columns must belong to the grain of the table.
* Many-to-many relationships need resolving tables.
* Foreign keys usually go on the many side.
* Logical modelling is still mostly database-independent.