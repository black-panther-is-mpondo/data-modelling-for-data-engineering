# 01: Business Requirements

## Purpose

This document defines the business requirements for the banking capstone project.

The goal is to understand what the business needs before creating conceptual, logical, physical, and analytical data models.

Good data modelling starts with business understanding, not tables.

## Business scenario

A retail bank wants to organise and analyse data about its customers, accounts, products, branches, transactions, and balances.

The bank needs a model that can support:

```text
Operational understanding
Historical tracking
Analytics and reporting
Data quality checks
````

The model should be clean enough for data engineering pipelines and understandable enough for analytics users.

## Business objectives

The business wants to answer questions such as:

```text
How many customers does the bank have?
How many active accounts exist?
Which customers hold which accounts?
Which accounts are jointly held?
Which products are most popular?
Which branches manage the most accounts?
What is the transaction value by channel?
What is the transaction volume by product?
What are account balances by day?
How do customer segments change over time?
How do account statuses change over time?
```

## In scope

The following areas are in scope:

```text
Customers
Accounts
Account ownership
Products
Branches
Transactions
Transaction types
Channels
Daily account balances
Customer segment history
Account status history
```

## Out of scope

The following areas are not included in this first version:

```text
Loans
Credit cards
Fraud detection
Marketing campaigns
Customer complaints
Employee relationship managers
Interest calculations
Fees and charges configuration
Regulatory reporting
Real-time payment processing
```

These can be added later if the business scope grows.

## Core business concepts

## Customer

A customer is a person or organisation that has a relationship with the bank.

A customer may:

```text
Hold one account
Hold many accounts
Hold no account yet
Be the primary holder of an account
Be a joint holder of an account
Move between customer segments over time
```

Important customer information includes:

```text
Customer number
Name
Date of birth
Customer type
National ID or passport number
Customer segment
```

## Account

An account is a banking account opened by the bank for one or more customers.

An account may:

```text
Belong to one product
Be managed by one branch
Have one or many account holders
Have many transactions
Have daily balance snapshots
Change status over time
```

Important account information includes:

```text
Account number
Product
Branch
Open date
Close date
Account status
```

## Account holder

An account holder represents the relationship between a customer and an account.

This is required because customers and accounts have a many-to-many relationship.

```text
One customer can hold many accounts.
One account can be held by many customers.
```

Important account holder information includes:

```text
Customer
Account
Holder role
Ownership percentage
Start date
End date
```

Example holder roles:

```text
PRIMARY
JOINT
SIGNATORY
AUTHORIZED_USER
```

## Product

A product describes the type of banking product linked to an account.

Examples:

```text
Savings Account
Current Account
Cheque Account
Fixed Deposit
Business Account
```

A product can be linked to many accounts.

## Branch

A branch represents the bank branch that manages or opened the account.

A branch can manage many accounts.

Important branch information includes:

```text
Branch code
Branch name
Province
City
```

## Transaction

A transaction is a posted movement on an account.

Examples:

```text
Deposit
Withdrawal
Card payment
Transfer
Debit order
Bank charge
```

A transaction must belong to one account.

Important transaction information includes:

```text
Transaction reference
Account
Transaction type
Channel
Transaction datetime
Posted date
Amount
Currency
Description
```

## Transaction type

A transaction type classifies a transaction.

Examples:

```text
Deposit
Withdrawal
Transfer
Card Payment
Debit Order
Fee
Interest
```

A transaction type can classify many transactions.

## Channel

A channel describes how the transaction happened.

Examples:

```text
Branch
ATM
Mobile App
Internet Banking
Card
USSD
Call Centre
```

A channel can be used by many transactions.

## Daily account balance

A daily account balance records the state of an account on a specific date.

This is a snapshot, not a transaction.

Grain:

```text
One row per account per day.
```

Important balance information includes:

```text
Account
Balance date
Opening balance
Closing balance
Available balance
Currency
```

## Customer segment history

Customer segment can change over time.

Examples:

```text
Student
Mass Market
Middle Income
Premium
Private Banking
Business
```

The model should keep history so that old transactions can still be analysed using the segment that was true at the time.

## Account status history

Account status can change over time.

Examples:

```text
ACTIVE
DORMANT
SUSPENDED
CLOSED
```

The model should track account status changes instead of only keeping the latest value.

## Main business rules

The following business rules apply:

```text
A customer can exist without an account.
An account must have at least one account holder.
A customer can hold many accounts.
An account can have many customers.
An account must belong to one product.
An account must belong to one branch.
A transaction must belong to one account.
A transaction must have one transaction type.
A transaction must happen through one channel.
A transaction amount must not be zero.
An account can have zero, one, or many transactions.
A daily balance must belong to one account.
There can only be one daily balance per account per date.
An account close date cannot be before the open date.
A history record end date cannot be before the start date.
```

## Key modelling challenges

## Challenge 1: Joint accounts

Joint accounts create a many-to-many relationship between customers and accounts.

A weak model would put `customer_id` directly inside the `account` table.

That would fail because one account can have many customers.

The model must use:

```text
account_holder
```

to resolve the relationship.

## Challenge 2: Customer-level transaction reporting

Transactions belong to accounts, not directly to customers.

This matters because of joint accounts.

Example:

```text
Account ACC100 has two customers.
A transaction of R1,000 happens on ACC100.
```

If the transaction is joined to both customers, the transaction amount may be double-counted.

The business must define whether customer-level reporting should:

```text
Stay at account level
Use the primary holder only
Allocate by ownership percentage
Use another allocation rule
```

This capstone keeps transactions at account level and documents the risk.

## Challenge 3: Events vs snapshots

Transactions and balances are different types of facts.

A transaction is an event.

A balance is a state at a point in time.

Therefore, the model separates:

```text
account_transaction
daily_account_balance
```

This prevents mixed grain problems.

## Challenge 4: Historical changes

Customer segment and account status can change over time.

If the model only stores the latest value, historical reports may become misleading.

Therefore, the model includes:

```text
customer_segment_history
account_status_history
```

## Required outputs

The capstone should produce:

```text
Business requirements document
Conceptual data model
Logical data model
Physical data model
PostgreSQL-style DDL script
Analytics star schema
Data quality rules
Model documentation
```

## Success criteria

The model is successful if it can:

```text
Represent customers and accounts correctly
Support joint accounts
Store posted transactions
Store daily account balances
Track customer segment history
Track account status history
Support reporting by product, branch, channel, and date
Avoid obvious double-counting risks
Document business rules clearly
Provide quality rules for trusted data
```

## Key takeaway

The most important requirement in this capstone is not simply to create tables.

The important requirement is to model the banking business correctly.

The model must respect:

```text
Business meaning
Relationships
Grain
History
Data quality
Reporting needs
```
