# Module 05: Conceptual Data Modelling

## Goal

The goal of this module is to understand how to create a high-level business model before thinking about SQL tables, columns, indexes, or database-specific details.

A conceptual model helps us answer:

> What does the business care about, and how do the main things connect?

## What is a conceptual data model?

A conceptual data model is the business-level view of the data.

It focuses on:

- main business entities
- relationships between entities
- cardinality
- business rules
- scope and assumptions

It does not focus on:

- SQL data types
- indexes
- partitions
- exact column lengths
- physical database syntax
- performance tuning

At this stage, the goal is meaning, not implementation.

## Why conceptual modelling matters

Conceptual modelling prevents us from jumping into table creation too early.

A source file may contain:

```text
customer_name
account_number
transaction_date
transaction_amount
branch_name
product_name
````

A beginner may create one wide table from those columns.

A modeller asks:

```text
Is Customer a separate business entity?
Is Account separate from Customer?
Can one Customer have many Accounts?
Can one Account have many Transactions?
Is Product a lookup or a full entity?
Is Branch important for reporting?
```

This thinking leads to a better model.

## Conceptual vs logical vs physical

### Conceptual model

Business-friendly:

```text
Customer holds Account
Account has Transaction
```

### Logical model

More structured:

```text
customer
account
account_holder
account_transaction
```

### Physical model

Database-specific:

```sql
CREATE TABLE account_holder (
    account_holder_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    customer_id BIGINT NOT NULL,
    account_id BIGINT NOT NULL,
    holder_role VARCHAR(50) NOT NULL
);
```

The conceptual model protects the business meaning before technical implementation begins.

## What goes into a conceptual model?

A conceptual model usually includes:

```text
Entities
Relationships
Cardinality
Business rules
Scope assumptions
```

Example:

```text
Customer owns Account
Account has Transaction
Branch manages Account
Product classifies Account
```

This can be drawn simply as:

```text
Customer --- owns --- Account --- has --- Transaction

Branch --- manages --- Account

Product --- classifies --- Account
```

## Banking example

Business statement:

```text
A bank has customers. Customers can hold accounts. Some accounts are jointly held. Accounts belong to products. Accounts have transactions. Transactions happen through channels. Branches may manage accounts.
```

Possible entities:

```text
Customer
Account
Product
Transaction
Channel
Branch
```

Relationships:

```text
Customer holds Account
Account belongs to Product
Account has Transaction
Transaction uses Channel
Branch manages Account
```

The important relationship is:

```text
Customer holds Account
```

This is many-to-many because:

```text
One customer can hold many accounts.
One account can be held by many customers.
```

Later, in the logical model, this is resolved using:

```text
Account Holder
```

## Cardinality

Cardinality means how many records can relate to how many other records.

Examples:

```text
One customer can hold many accounts.
One account can have many transactions.
One product can classify many accounts.
One branch can manage many accounts.
```

But we should be more precise by including optionality.

Better:

```text
A customer can exist without an account.
An account must have at least one account holder.
An account can exist before its first transaction.
A transaction cannot exist without an account.
```

This is stronger than only saying:

```text
Customer has Account.
Account has Transaction.
```

## Optionality

Optionality tells us whether the relationship must exist.

Example:

```text
Customer can exist without Account.
```

This means a customer record may exist before the customer opens an account.

Example:

```text
Transaction must belong to Account.
```

This means a transaction cannot exist without an account.

Optionality later affects:

* nullable fields
* foreign keys
* validation rules
* business constraints

## Business rules

Business rules describe what must be true.

Banking examples:

```text
Each account must be linked to at least one customer.
A transaction must belong to exactly one account.
A product can exist even if no account currently uses it.
A branch can exist even if no accounts are assigned to it yet.
A customer can exist before opening an account.
```

These rules later become design decisions such as:

```text
Foreign keys
Nullable columns
Unique constraints
Bridge tables
History tables
Validation checks
```

## Scope assumptions

A conceptual model should clearly state what is in scope and out of scope.

Example scope:

```text
We are modelling retail banking accounts.
We are modelling customers, accounts, products, branches, transactions, and channels.
We are modelling posted account transactions.
```

Example exclusions:

```text
We are not modelling loans yet.
We are not modelling fraud detection yet.
We are not modelling card authorisations yet.
We are not modelling employee relationship managers yet.
```

This matters because no model can include everything.

Good modelling includes boundaries.

## Conceptual model example

For the banking starter model:

```text
Customer holds Account
Account belongs to Product
Account has Transaction
Transaction uses Channel
Branch manages Account
```

With cardinality:

```text
Customer many-to-many Account
Account many-to-one Product
Account one-to-many Transaction
Transaction many-to-one Channel
Branch one-to-many Account
```

With optionality:

```text
A customer can hold zero, one, or many accounts.
An account must have at least one customer.
An account can have zero, one, or many transactions.
A transaction must belong to one account.
A product can classify zero, one, or many accounts.
Each account must belong to one product.
A branch can manage zero, one, or many accounts.
Each account must be managed by one branch.
```

## Simple conceptual diagram

```text
Customer
   |
   | many-to-many
   |
Account
   |
   | one-to-many
   |
Transaction
   |
   | many-to-one
   |
Transaction Type

Account many-to-one Product
Account many-to-one Branch
Transaction many-to-one Channel
```

At conceptual level, this is enough to discuss the model with business and technical people.

## Common mistakes

### Mistake 1: Adding technical detail too early

This is too detailed for a conceptual model:

```text
customer_id BIGINT
first_name VARCHAR(100)
created_at TIMESTAMP
idx_customer_national_id
```

That belongs in the physical model.

### Mistake 2: Ignoring many-to-many relationships

This sounds simple:

```text
Customer owns Account
```

But in banking, joint accounts make it many-to-many.

Ignoring this will create a weak model.

### Mistake 3: Modelling reports instead of business entities

A dashboard may show:

```text
Monthly active customers by branch
```

But the conceptual model should focus on:

```text
Customer
Account
Branch
Transaction
```

The report is an output.

The model represents the business.

### Mistake 4: Not documenting scope

If scope is unclear, the model becomes too broad or people assume it covers more than it does.

Always state what is included and excluded.

## What good looks like

A good conceptual model should be understandable to business and technical people.

It should clearly show:

* the main entities
* how they relate
* whether relationships are one-to-many or many-to-many
* what must exist and what is optional
* what is in scope
* what is out of scope

## Key takeaways

* A conceptual model is the business-level view of data.
* It focuses on entities, relationships, cardinality, business rules, and scope.
* It avoids SQL and database-specific details.
* It helps prevent poor table design by protecting business meaning.
* Many-to-many relationships should be identified early.
* Optionality matters because it affects later design.
* Scope assumptions should be documented.