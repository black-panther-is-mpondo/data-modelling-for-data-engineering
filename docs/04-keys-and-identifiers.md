# Module 04: Keys and Identifiers

## Goal

The goal of this module is to understand how records are uniquely identified and how tables connect safely.

Keys answer two important questions:

```text
1. How do I uniquely identify one record?
2. How do I link this record to another table correctly?
````

Example:

```text
customer
- customer_id
- customer_number
- national_id
- first_name
- last_name

account
- account_id
- account_number
- product_id
- branch_id

account_holder
- customer_id
- account_id
- holder_role
```

The keys tell us:

```text
Which customer is this?
Which account is this?
Which customers are linked to which accounts?
```

## Primary key

A primary key uniquely identifies one row in a table.

Example:

```text
customer
- customer_id
- first_name
- last_name
```

Here:

```text
customer_id
```

is the primary key.

Example data:

```text
customer_id | first_name | last_name
------------|------------|----------
1           | Thabo      | Mokoena
2           | Lerato     | Dlamini
3           | Aisha      | Khan
```

Each row has a unique identifier.

A primary key should be:

```text
Unique
Not null
Stable
```

## Foreign key

A foreign key is a column that points to the primary key of another table.

Example:

```text
branch
- branch_id
- branch_name

account
- account_id
- account_number
- branch_id
```

Here:

```text
account.branch_id
```

points to:

```text
branch.branch_id
```

This means each account belongs to a valid branch.

## Where does the foreign key go?

In a one-to-many relationship, the foreign key goes on the many side.

Example:

```text
Branch 1 --- many Account
```

So `branch_id` goes into the `account` table.

```text
account
- account_id
- branch_id
```

Not:

```text
branch
- branch_id
- account_id
```

A branch can have many accounts, so storing one `account_id` in branch would fail.

## Natural key

A natural key is a real-world identifier that already exists in the business.

Examples:

```text
national_id
passport_number
account_number
student_number
employee_number
product_code
email
```

Banking example:

```text
account_number
```

is a natural key because the business already uses it to identify an account.

Natural keys are useful, but they can be risky.

They can be:

```text
mistyped
missing
changed
reused
sensitive
not unique across systems
```

## Surrogate key

A surrogate key is an artificial/internal key created by the database or data warehouse.

Examples:

```text
customer_id
account_id
transaction_id
customer_key
product_key
```

Example:

```text
customer
- customer_id
- customer_number
- national_id
- first_name
- last_name
```

Here:

```text
customer_id
```

is the internal surrogate key.

```text
customer_number
national_id
```

are business or natural identifiers.

Surrogate keys are useful because they are:

```text
stable
short
controlled by the system
not sensitive
cleaner for joins
```

## Business key

A business key is the identifier the business uses to recognise something.

Examples:

```text
customer_number
account_number
loan_account_number
policy_number
transaction_reference
product_code
branch_code
```

A good model often keeps both:

```text
customer_id       internal primary key
customer_number   business key
```

The business key is important for matching data from source systems.

The surrogate key is better for internal joins.

## Candidate key

A candidate key is any column, or group of columns, that could uniquely identify a row.

Example:

```text
customer
- customer_id
- national_id
- email
```

Possible candidate keys:

```text
customer_id
national_id
email
```

But only one is chosen as the primary key.

In practice, `email` may look unique but may not be reliable. A person can change email, some people share emails, and some customers may not have one.

## Composite key

A composite key uses more than one column to uniquely identify a row.

Example:

```text
account_holder
- customer_id
- account_id
- holder_role
```

The combination:

```text
customer_id + account_id
```

can identify one customer-account relationship.

Example:

```text
customer_id | account_id | holder_role
------------|------------|-------------
1           | 100        | PRIMARY
2           | 100        | JOINT
1           | 200        | PRIMARY
```

`customer_id` appears more than once.

`account_id` appears more than once.

But the combination of `customer_id + account_id` identifies a specific relationship.

If we track history, we may need:

```text
customer_id + account_id + start_date
```

because the same customer could leave and rejoin an account later.

## Unique constraint

A unique constraint prevents duplicate values in a column or group of columns.

Example:

```text
account.account_number must be unique.
```

Even if `account_id` is the primary key, we should still protect the business key:

```text
account
- account_id PK
- account_number UNIQUE
```

This gives us:

```text
Internal safety through account_id
Business safety through account_number
```

## Banking model example

```text
customer
- customer_id PK
- customer_number UNIQUE
- national_id UNIQUE NULLABLE
- passport_number NULLABLE
- first_name
- last_name

account
- account_id PK
- account_number UNIQUE
- product_id FK
- branch_id FK
- open_date

branch
- branch_id PK
- branch_code UNIQUE
- branch_name

product
- product_id PK
- product_code UNIQUE
- product_name

account_holder
- account_holder_id PK
- customer_id FK
- account_id FK
- holder_role
- start_date
- end_date

account_transaction
- transaction_id PK
- transaction_reference UNIQUE
- account_id FK
- transaction_type_id FK
- channel_id FK
- transaction_datetime
- amount
```

## Why not use national_id as the primary key?

It may seem reasonable to use `national_id` as the customer primary key, but this is risky.

Reasons:

```text
Some customers may not have a national ID.
Foreign nationals may use passport numbers.
Business customers may use registration numbers.
The ID may be captured incorrectly.
The ID may need correction later.
It is sensitive personal data.
It may not be unique across all source systems.
Changing a primary key creates problems across related tables.
```

Better design:

```text
customer_id       internal primary key
customer_number   business key
national_id       sensitive natural key
passport_number   optional natural key
```

## Many-to-many keys

For a many-to-many relationship, create a resolving table.

Example:

```text
Customer many --- many Account
```

Resolving table:

```text
account_holder
- account_holder_id PK
- customer_id FK
- account_id FK
- holder_role
- start_date
- end_date
```

Useful uniqueness rule:

```text
customer_id + account_id + start_date should be unique
```

This prevents duplicate relationship records while still allowing history.

## Common mistakes

### Mistake 1: No primary key

Bad:

```text
account_transaction
- account_number
- transaction_date
- amount
```

What uniquely identifies one transaction?

Unclear.

Better:

```text
account_transaction
- transaction_id
- account_id
- transaction_datetime
- amount
```

### Mistake 2: Using names as keys

Bad:

```text
customer_name
```

Names are not unique. Two customers can have the same name, and names can change.

### Mistake 3: Confusing business keys and primary keys

A business key identifies something in the business.

A primary key identifies a row in the database.

They can be the same, but in serious systems they are often separated.

### Mistake 4: Ignoring composite uniqueness

Bad account holder table:

```text
account_holder
- customer_id
- account_id
- holder_role
```

Without a uniqueness rule, this duplicate can happen:

```text
customer_id | account_id | holder_role
------------|------------|-------------
1           | 100        | PRIMARY
1           | 100        | PRIMARY
```

Better: add a unique rule.

```text
customer_id + account_id + start_date
```

## Key takeaways

* Primary keys uniquely identify rows.
* Foreign keys link tables.
* Foreign keys usually go on the many side.
* Natural keys come from the real world.
* Surrogate keys are system-generated internal identifiers.
* Business keys are used by the business or source systems.
* Composite keys use multiple columns.
* Unique constraints protect business identifiers.
* Do not use sensitive or unstable values as primary keys.
* In many-to-many relationships, the resolving table needs careful key design.
