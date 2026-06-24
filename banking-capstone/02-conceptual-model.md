# 02: Conceptual Model

## Purpose

This document defines the conceptual data model for the banking capstone project.

The conceptual model focuses on business meaning.

It identifies:

```text
Main business entities
Relationships between entities
Cardinality
Optionality
Important business rules
````

It does not focus on SQL, data types, indexes, or database-specific design.

## Business view

The bank needs to model the following business statement:

```text
Customers hold accounts.
Accounts belong to products.
Accounts are managed by branches.
Accounts have transactions.
Transactions have transaction types.
Transactions happen through channels.
Accounts have daily balances.
Customers can move between segments over time.
Accounts can move between statuses over time.
```

## Main entities

The main conceptual entities are:

```text
Customer
Account
Account Holder
Product
Branch
Transaction
Transaction Type
Channel
Daily Account Balance
Customer Segment
Customer Segment History
Account Status
Account Status History
```

## Entity descriptions

## Customer

A customer is a person or organisation that has a relationship with the bank.

A customer may hold one or more accounts.

A customer may also exist before opening an account.

Examples:

```text
Individual customer
Business customer
Joint account holder
Primary account holder
```

## Account

An account is a banking account opened for one or more customers.

An account belongs to one product.

An account is managed by one branch.

An account can have many transactions and many daily balance records.

## Account Holder

An account holder represents the relationship between a customer and an account.

This entity exists because customers and accounts have a many-to-many relationship.

```text
One customer can hold many accounts.
One account can be held by many customers.
```

The account holder entity allows the model to support joint accounts.

## Product

A product describes the type of bank account.

Examples:

```text
Savings Account
Current Account
Fixed Deposit
Business Account
```

One product can be linked to many accounts.

## Branch

A branch represents a bank branch.

A branch can manage many accounts.

## Transaction

A transaction is a posted movement on an account.

Examples:

```text
Deposit
Withdrawal
Transfer
Card payment
Debit order
Bank fee
```

A transaction must belong to one account.

## Transaction Type

A transaction type classifies a transaction.

Examples:

```text
Deposit
Withdrawal
Transfer
Card Payment
Fee
Interest
```

One transaction type can classify many transactions.

## Channel

A channel describes how a transaction happened.

Examples:

```text
ATM
Branch
Mobile App
Internet Banking
Card
USSD
Call Centre
```

One channel can be used for many transactions.

## Daily Account Balance

A daily account balance records the state of an account on a specific date.

This is not the same as a transaction.

Grain:

```text
One row per account per day.
```

## Customer Segment

A customer segment classifies a customer for business reporting.

Examples:

```text
Student
Mass Market
Middle Income
Premium
Private Banking
Business
```

## Customer Segment History

Customer segment history records how a customer's segment changes over time.

This is needed because a customer can move from one segment to another.

Example:

```text
Student → Middle Income → Premium
```

## Account Status

An account status describes the state of an account.

Examples:

```text
ACTIVE
DORMANT
SUSPENDED
CLOSED
```

## Account Status History

Account status history records how an account's status changes over time.

Example:

```text
ACTIVE → SUSPENDED → ACTIVE → CLOSED
```

## Conceptual relationships

The main relationships are:

```text
Customer holds Account
Account belongs to Product
Branch manages Account
Account has Transaction
Transaction has Transaction Type
Transaction uses Channel
Account has Daily Account Balance
Customer belongs to Customer Segment over time
Account has Account Status over time
```

## Relationship summary

```text
Customer many-to-many Account
Account many-to-one Product
Account many-to-one Branch
Account one-to-many Transaction
Transaction many-to-one Transaction Type
Transaction many-to-one Channel
Account one-to-many Daily Account Balance
Customer one-to-many Customer Segment History
Customer Segment one-to-many Customer Segment History
Account one-to-many Account Status History
Account Status one-to-many Account Status History
```

## Conceptual diagram

```text
Customer
   |
   | many-to-many
   |
Account
   |
   | many-to-one
   |
Product

Account
   |
   | many-to-one
   |
Branch

Account
   |
   | one-to-many
   |
Transaction
   |
   | many-to-one
   |
Transaction Type

Transaction
   |
   | many-to-one
   |
Channel

Account
   |
   | one-to-many
   |
Daily Account Balance

Customer
   |
   | one-to-many
   |
Customer Segment History
   |
   | many-to-one
   |
Customer Segment

Account
   |
   | one-to-many
   |
Account Status History
   |
   | many-to-one
   |
Account Status
```

## Resolving the many-to-many relationship

The most important modelling decision is the relationship between customer and account.

A customer can hold many accounts.

An account can have many customers.

This means the relationship is many-to-many.

A many-to-many relationship should be resolved with a separate entity:

```text
Account Holder
```

Conceptually:

```text
Customer many-to-many Account
```

Logically:

```text
Customer one-to-many Account Holder
Account one-to-many Account Holder
```

This gives us:

```text
Customer
   |
   | one-to-many
   |
Account Holder
   |
   | many-to-one
   |
Account
```

## Account Holder business meaning

`Account Holder` is not just a technical joining table.

It has business meaning.

It describes the customer's relationship to the account.

Examples:

```text
Primary holder
Joint holder
Signatory
Authorised user
```

It can also store:

```text
Start date
End date
Ownership percentage
```

## Optionality

## Customer and Account

```text
A customer can exist without an account.
An account must have at least one account holder.
```

This supports customers who are registered before opening an account.

## Account and Transaction

```text
An account can exist without transactions.
A transaction must belong to one account.
```

A new account may have no transactions yet.

## Account and Daily Account Balance

```text
An account can have many daily balance records.
A daily balance must belong to one account.
```

## Product and Account

```text
A product can exist without accounts.
An account must belong to one product.
```

This allows the bank to create a product before any customer opens that product.

## Branch and Account

```text
A branch can exist without accounts.
An account must belong to one branch.
```

## Customer and Customer Segment History

```text
A customer can have many segment history records.
A segment history record must belong to one customer.
```

## Account and Account Status History

```text
An account can have many status history records.
A status history record must belong to one account.
```

## Business rules

The conceptual model supports the following rules:

```text
A customer can hold zero, one, or many accounts.
An account must have at least one account holder.
An account can have one or many account holders.
An account belongs to one product.
An account is managed by one branch.
A transaction belongs to one account.
A transaction has one transaction type.
A transaction happens through one channel.
An account can have zero, one, or many transactions.
A daily balance belongs to one account and one date.
A customer can change segment over time.
An account can change status over time.
```

## Grain at conceptual level

Even at conceptual level, the grain should be clear.

```text
Customer:
One business customer.

Account:
One banking account.

Account Holder:
One customer-account relationship.

Transaction:
One posted account transaction.

Daily Account Balance:
One account balance snapshot for one day.

Customer Segment History:
One customer's segment for a period of time.

Account Status History:
One account's status for a period of time.
```

## Important modelling cautions

## Joint account caution

Joint accounts make customer-level reporting risky.

Example:

```text
Account ACC100 has two holders.
Transaction T001 of R1,000 happens on ACC100.
```

If the transaction is joined to both customers, the amount may be counted twice.

The conceptual model keeps transactions attached to accounts.

Customer-level transaction reporting needs a separate allocation or attribution rule.

## Transaction vs balance caution

Transactions and balances should not be mixed.

A transaction is an event.

A balance is a snapshot.

Therefore, the model separates:

```text
Transaction
Daily Account Balance
```

## Current value vs history caution

Customer segment and account status can change over time.

If we only store the latest value, historical reporting can be wrong.

Therefore, the model includes:

```text
Customer Segment History
Account Status History
```

## Conceptual model outcome

The conceptual model gives us a business-level structure that can now be converted into a logical model.

The next step is to define:

```text
Tables
Columns
Primary keys
Foreign keys
Unique rules
Optional fields
```

## Key takeaway

The conceptual model protects the business meaning before technical implementation begins.

The most important ideas in this capstone are:

```text
Customer and Account are separate entities.
Customer and Account have a many-to-many relationship.
Account Holder resolves the many-to-many relationship.
Transactions belong to accounts.
Balances are snapshots and should be separate from transactions.
Customer segment and account status need history.
```
