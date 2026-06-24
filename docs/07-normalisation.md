# Module 07: Normalisation

## Goal

The goal of this module is to understand how to organise data into clean tables so that duplication, inconsistency, and maintenance problems are reduced.

Normalisation helps answer:

> Does this fact belong in this table?

## What is normalisation?

Normalisation is the process of structuring data so that:

- data is not unnecessarily repeated
- updates are safer
- relationships are clearer
- contradictions are avoided
- each fact is stored in the right place

In simple terms:

> Normalisation helps you avoid messy “everything-in-one-table” designs.

## Why normalisation matters

Imagine this banking table:

```text
customer_account_transaction

customer_id
customer_name
customer_phone
account_number
account_type
branch_name
transaction_id
transaction_date
transaction_amount
transaction_type
````

At first, this looks convenient because everything is in one place.

But it creates problems.

## Problem 1: Customer details are repeated

If one customer has 1,000 transactions, the customer name and phone number appear 1,000 times.

That is duplication.

## Problem 2: Updates become dangerous

If the customer changes phone number, every transaction row must be updated.

If some rows are missed, the same customer now has different phone numbers in different rows.

## Problem 3: Branch details are repeated

If a branch name changes, the change must be made everywhere the branch name appears.

## Problem 4: Aggregations can become wrong

If the table mixes customer, account, transaction, and branch information, joins and totals can easily be miscalculated.

## Better approach

Split the data into tables that each have a clear responsibility:

```text
customer
account
account_holder
branch
account_transaction
transaction_type
account_type
```

Each table stores facts about one thing at one grain.

## Update, insert, and delete anomalies

Normalisation helps prevent three common problems:

```text
Update anomaly
Insert anomaly
Delete anomaly
```

## Update anomaly

An update anomaly happens when the same fact appears in many places.

Example:

```text
customer_id | customer_name | customer_phone | transaction_id
------------|---------------|----------------|---------------
1           | Thabo         | 0711111111     | T001
1           | Thabo         | 0711111111     | T002
1           | Thabo         | 0711111111     | T003
```

If Thabo changes phone number, multiple rows must be updated.

Better:

```text
customer
- customer_id
- customer_name
- customer_phone

account_transaction
- transaction_id
- account_id
- amount
```

Now the phone number is stored once.

## Insert anomaly

An insert anomaly happens when you cannot insert one kind of fact unless another unrelated fact exists.

Example:

If everything is stored in `customer_account_transaction`, you may not be able to add a new customer unless they already have an account and transaction.

Better:

```text
customer
```

can store the customer independently.

## Delete anomaly

A delete anomaly happens when deleting one fact accidentally deletes another important fact.

Example:

If the only transaction for an account is deleted from a wide table, you may lose the only stored information about the account.

Better:

```text
account
```

stores account details separately from transactions.

## First Normal Form: 1NF

First Normal Form means:

```text
Each column should contain atomic values.
There should be no repeating groups.
Each row should be uniquely identifiable.
```

Atomic means each field contains one value, not a list.

## 1NF violation: list in a column

Bad design:

```text
customer
- customer_id
- customer_name
- phone_numbers
```

Example:

```text
customer_id | customer_name | phone_numbers
------------|---------------|--------------------------
1           | Thabo         | 0711111111, 0722222222
```

This violates 1NF because `phone_numbers` contains multiple values.

Better:

```text
customer
- customer_id
- customer_name

customer_phone
- customer_phone_id
- customer_id
- phone_number
- phone_type
```

Grain:

```text
customer:
One row per customer.

customer_phone:
One row per phone number per customer.
```

## 1NF violation: repeating columns

Bad design:

```text
order
- order_id
- product_1
- product_2
- product_3
```

Better:

```text
order
- order_id
- customer_id
- order_date

order_item
- order_id
- product_id
- quantity
```

Now an order can have any number of products.

Banking version of the same mistake:

```text
account
- primary_customer_id
- joint_customer_id_1
- joint_customer_id_2
```

Better:

```text
account_holder
- account_id
- customer_id
- holder_role
```

Now an account can have one, two, or many holders without changing the table structure.

## Second Normal Form: 2NF

Second Normal Form applies when a table has a composite key.

It says:

```text
Every non-key column must depend on the whole composite key, not just part of it.
```

## 2NF example

Bad table:

```text
enrollment
- student_id
- course_id
- student_name
- course_name
- final_mark
```

Assume the key is:

```text
student_id + course_id
```

Now ask:

```text
Does student_name depend on both student_id and course_id?
```

No. It depends only on `student_id`.

```text
Does course_name depend on both student_id and course_id?
```

No. It depends only on `course_id`.

```text
Does final_mark depend on both student_id and course_id?
```

Yes. The final mark belongs to that student in that course.

Better:

```text
student
- student_id
- student_name

course
- course_id
- course_name

enrollment
- student_id
- course_id
- final_mark
```

## Banking 2NF example

Bad table:

```text
account_holder
- customer_id
- account_id
- customer_name
- account_number
- holder_role
- start_date
```

Assume the key is:

```text
customer_id + account_id
```

Now ask:

```text
Does customer_name depend on customer_id + account_id?
```

No. It depends only on `customer_id`.

```text
Does account_number depend on customer_id + account_id?
```

No. It depends only on `account_id`.

```text
Does holder_role depend on customer_id + account_id?
```

Yes. A customer can have different roles on different accounts.

Better:

```text
customer
- customer_id
- customer_name

account
- account_id
- account_number

account_holder
- customer_id
- account_id
- holder_role
- start_date
```

## Third Normal Form: 3NF

Third Normal Form says:

```text
Non-key columns should not depend on other non-key columns.
```

Another way to say it:

> A column should depend on the key, the whole key, and nothing but the key.

## 3NF example

Bad table:

```text
account
- account_id
- account_number
- branch_code
- branch_name
- branch_city
```

Primary key:

```text
account_id
```

Problem:

```text
branch_name
branch_city
```

depend on `branch_code`, not directly on `account_id`.

Better:

```text
account
- account_id
- account_number
- branch_id

branch
- branch_id
- branch_code
- branch_name
- branch_city
```

Now branch details live in the branch table.

## Banking 3NF example

Bad table:

```text
account_transaction
- transaction_id
- account_id
- transaction_type_code
- transaction_type_name
- transaction_category
- amount
```

Problem:

```text
transaction_type_name
transaction_category
```

depend on `transaction_type_code`, not directly on `transaction_id`.

Better:

```text
account_transaction
- transaction_id
- account_id
- transaction_type_id
- amount

transaction_type
- transaction_type_id
- transaction_type_code
- transaction_type_name
- transaction_category
```

## Normalised banking model

A cleaner banking model may look like this:

```text
customer
- customer_id
- customer_number
- national_id
- first_name
- last_name
- date_of_birth

branch
- branch_id
- branch_code
- branch_name
- province
- city

account_type
- account_type_id
- account_type_code
- account_type_name

account
- account_id
- account_number
- account_type_id
- branch_id
- open_date
- close_date
- account_status

account_holder
- account_holder_id
- customer_id
- account_id
- holder_role
- start_date
- end_date

transaction_type
- transaction_type_id
- transaction_type_code
- transaction_type_name
- transaction_category

account_transaction
- transaction_id
- account_id
- transaction_type_id
- transaction_datetime
- amount
- transaction_reference
```

Each table has a clear responsibility.

## Normalisation vs denormalisation

Normalisation is useful, but it is not always the final goal.

For operational systems, normalisation is usually good because we want:

* data integrity
* fewer duplicates
* safer updates
* clear relationships

For analytics and reporting, heavily normalised models can become painful because users need many joins.

So in analytics, we often use dimensional modelling:

```text
fact_transaction
dim_customer
dim_account
dim_branch
dim_date
dim_transaction_type
```

This is more denormalised and easier for reporting.

Senior rule:

> Normalise when you need integrity. Denormalise carefully when you need simpler and faster analytics.

## Common mistakes

### Mistake 1: One giant table

Bad:

```text
customer_account_transaction
```

Better:

```text
customer
account
account_holder
account_transaction
```

### Mistake 2: Repeating numbered columns

Bad:

```text
phone_1
phone_2
phone_3
```

Better:

```text
customer_phone
```

### Mistake 3: Repeating lookup descriptions everywhere

Bad:

```text
transaction_type_code
transaction_type_name
transaction_type_category
```

inside every transaction row.

Better:

```text
transaction_type
```

### Mistake 4: Over-normalising

Normalisation should improve clarity. It should not make the model unnecessarily complicated.

Bad over-design:

```text
customer_first_name
customer_last_name
customer_birth_day
customer_birth_month
customer_birth_year
```

split into unnecessary tables.

## Normalisation checklist

Ask:

```text
Does each table have one clear grain?
Are there repeating columns like product_1, product_2, product_3?
Are there list values inside one column?
Are customer details repeated in transaction rows?
Are lookup descriptions repeated unnecessarily?
Do non-key columns depend on the primary key?
For composite keys, do columns depend on the full key?
Are we storing the same fact in multiple places?
Could updates create inconsistent data?
Could deletes accidentally remove important facts?
```

## Key takeaways

* Normalisation reduces unnecessary duplication.
* 1NF removes repeating groups and list values.
* 2NF ensures columns depend on the whole composite key.
* 3NF ensures columns do not depend on other non-key columns.
* Store each fact once, in the table where it belongs.
* Normalisation is usually best for operational models.
* Analytics models may intentionally denormalise for reporting performance and usability.