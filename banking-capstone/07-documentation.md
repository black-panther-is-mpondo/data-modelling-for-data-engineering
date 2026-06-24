# 07: Model Documentation

## Purpose

This document gives a final documented view of the banking capstone data model.

It summarises:

```text
Business purpose
Scope
Tables
Grain
Keys
Relationships
Business rules
Data quality rules
Analytics usage
Known limitations
````

The goal is to make the model understandable, maintainable, and trustworthy.

## Business purpose

This model supports a simplified retail banking environment.

It helps the bank understand:

```text
Customers
Accounts
Account ownership
Products
Branches
Transactions
Channels
Daily balances
Customer segment history
Account status history
```

It supports both operational-style modelling and analytics-style reporting.

## Business questions supported

The model can support questions such as:

```text
How many customers does the bank have?
How many active accounts exist?
Which customers hold which accounts?
Which accounts are jointly held?
Which products are most used?
Which branches manage the most accounts?
What is transaction value by channel?
What is transaction volume by product?
What are daily balances by account?
How do customer segments change over time?
How do account statuses change over time?
```

## Scope

## In scope

```text
Customers
Accounts
Account holders
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

## Operational model tables

The operational-style model contains:

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

## Table documentation

## customer

Stores one row per customer.

### Grain

```text
One row per customer.
```

### Key columns

```text
customer_id:
Primary key.

customer_number:
Business customer identifier. Must be unique.

national_id:
Optional national identifier. Sensitive field.

passport_number:
Optional passport identifier. Sensitive field.
```

### Notes

A customer can exist without an account.

This supports customers who are registered before opening an account.

## customer_segment

Stores one row per customer segment.

### Grain

```text
One row per customer segment.
```

### Key columns

```text
customer_segment_id:
Primary key.

customer_segment_code:
Business segment code. Must be unique.
```

### Example values

```text
STUDENT
MASS_MARKET
MIDDLE_INCOME
PREMIUM
PRIVATE_BANKING
BUSINESS
```

## customer_segment_history

Stores customer segment changes over time.

### Grain

```text
One row per customer segment assignment for a time period.
```

### Key columns

```text
customer_segment_history_id:
Primary key.

customer_id:
Foreign key to customer.

customer_segment_id:
Foreign key to customer_segment.

effective_from_date:
Start date of the segment assignment.

effective_to_date:
End date of the segment assignment.

is_current:
Indicates the latest active segment row.
```

### Notes

This table supports historical reporting.

It prevents the model from only storing the latest customer segment.

## branch

Stores one row per bank branch.

### Grain

```text
One row per branch.
```

### Key columns

```text
branch_id:
Primary key.

branch_code:
Business branch code. Must be unique.
```

## product

Stores one row per banking product.

### Grain

```text
One row per product.
```

### Key columns

```text
product_id:
Primary key.

product_code:
Business product code. Must be unique.
```

## account

Stores one row per bank account.

### Grain

```text
One row per account.
```

### Key columns

```text
account_id:
Primary key.

account_number:
Business account identifier. Must be unique.

product_id:
Foreign key to product.

branch_id:
Foreign key to branch.
```

### Notes

An account belongs to one product.

An account belongs to one branch.

An account must have at least one account holder, but that rule is enforced through validation rather than a simple foreign key.

## account_status

Stores one row per account status.

### Grain

```text
One row per account status.
```

### Key columns

```text
account_status_id:
Primary key.

account_status_code:
Business status code. Must be unique.
```

### Example values

```text
ACTIVE
DORMANT
SUSPENDED
CLOSED
```

## account_status_history

Stores account status changes over time.

### Grain

```text
One row per account status assignment for a time period.
```

### Key columns

```text
account_status_history_id:
Primary key.

account_id:
Foreign key to account.

account_status_id:
Foreign key to account_status.

effective_from_date:
Start date of the account status.

effective_to_date:
End date of the account status.

is_current:
Indicates the latest active status row.
```

## account_holder

Stores the relationship between customers and accounts.

### Grain

```text
One row per customer-account relationship.
```

### Key columns

```text
account_holder_id:
Primary key.

customer_id:
Foreign key to customer.

account_id:
Foreign key to account.

holder_role:
Role of the customer on the account.

ownership_percentage:
Optional percentage used for allocation.

start_date:
Start date of the relationship.

end_date:
End date of the relationship.
```

### Notes

This table resolves the many-to-many relationship between customer and account.

It supports joint accounts.

## channel

Stores one row per transaction channel.

### Grain

```text
One row per channel.
```

### Example values

```text
ATM
Branch
Mobile App
Internet Banking
Card
USSD
Call Centre
```

## transaction_type

Stores one row per transaction type.

### Grain

```text
One row per transaction type.
```

### Example values

```text
Deposit
Withdrawal
Transfer
Card Payment
Debit Order
Fee
Interest
```

## account_transaction

Stores one row per posted account transaction.

### Grain

```text
One row per posted account transaction.
```

### Key columns

```text
transaction_id:
Primary key.

transaction_reference:
Business transaction reference. Must be unique.

account_id:
Foreign key to account.

transaction_type_id:
Foreign key to transaction_type.

channel_id:
Foreign key to channel.
```

### Measures

```text
amount
```

### Notes

Transactions belong to accounts, not directly to customers.

Customer-level transaction reporting must be handled carefully because of joint accounts.

## daily_account_balance

Stores daily account balance snapshots.

### Grain

```text
One row per account per balance date.
```

### Key columns

```text
daily_account_balance_id:
Primary key.

account_id:
Foreign key to account.

balance_date:
Date of the balance snapshot.
```

### Measures

```text
opening_balance
closing_balance
available_balance
```

### Notes

Balances are snapshots, not transaction events.

There should only be one balance row per account per date.

## Relationship documentation

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

## Main many-to-many relationship

The main many-to-many relationship is:

```text
customer many --- many account
```

This is resolved by:

```text
account_holder
```

Expanded:

```text
customer 1 --- many account_holder
account 1 --- many account_holder
```

## Business rules

The model represents these business rules:

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

## Data quality rules

Important quality rules include:

```text
customer.customer_number must be unique.
account.account_number must be unique.
account_transaction.transaction_reference must be unique.
daily_account_balance must be unique by account_id and balance_date.
account_holder must be unique by customer_id, account_id, and start_date.
transaction amount must not be zero.
account close_date cannot be before open_date.
history effective_to_date cannot be before effective_from_date.
customer segment history must not overlap for the same customer.
account status history must not overlap for the same account.
```

## Analytics model

The analytics model uses a star schema.

## Fact tables

```text
fact_transaction
fact_daily_account_balance
```

## Dimension tables

```text
dim_date
dim_customer
dim_account
dim_product
dim_branch
dim_channel
dim_transaction_type
dim_account_status
dim_customer_segment
```

## Bridge table

```text
bridge_account_customer
```

This bridge supports account-to-customer reporting where accounts may have multiple holders.

## Fact table grain

```text
fact_transaction:
One row per posted account transaction.

fact_daily_account_balance:
One row per account per day.
```

## Measure behaviour

```text
transaction_amount:
Additive.

transaction_count:
Additive.

opening_balance:
Semi-additive.

closing_balance:
Semi-additive.

available_balance:
Semi-additive.
```

Balances should not be blindly summed across dates.

Use average daily balance, latest balance, or end-of-month balance depending on the reporting requirement.

## Joint account reporting caution

Transactions belong to accounts.

If transactions are joined to customers through account holders, a single transaction can appear once per holder.

Example:

```text
Account ACC100 has two holders.
Transaction T001 has amount R1,000.
Joining to both holders gives two rows.
Summing without allocation may produce R2,000.
```

Customer-level transaction reporting must use a documented rule:

```text
Report at account level only.
Assign to primary holder only.
Allocate by ownership percentage.
Use another approved allocation rule.
```

## Security and privacy

Sensitive fields include:

```text
customer.national_id
customer.passport_number
customer.date_of_birth
account.account_number
```

General reporting models should avoid exposing sensitive identifiers directly.

Recommended reporting alternatives:

```text
age_band instead of date_of_birth
masked account number instead of full account number
customer segment instead of national identifier
province or branch instead of precise personal address
```

## Known limitations

This model does not currently include:

```text
Loans
Credit cards
Fraud alerts
Card authorisations
Marketing campaigns
Customer complaints
Employee relationship managers
Interest calculations
Fee configuration
Regulatory reporting
```

The model also does not fully enforce every business rule through database constraints.

Some rules need pipeline validation, application logic, or data quality checks.

Examples:

```text
An account must have at least one account holder.
Customer segment history must not overlap.
Account status history must not overlap.
Customer-level transaction allocation must follow a business-approved rule.
```

## Usage examples

## Account count by branch

```sql
SELECT
    b.branch_name,
    COUNT(*) AS account_count
FROM account a
JOIN branch b
    ON a.branch_id = b.branch_id
GROUP BY
    b.branch_name
ORDER BY
    account_count DESC;
```

## Transaction value by channel

```sql
SELECT
    c.channel_name,
    SUM(t.amount) AS total_transaction_amount,
    COUNT(*) AS transaction_count
FROM account_transaction t
JOIN channel c
    ON t.channel_id = c.channel_id
GROUP BY
    c.channel_name
ORDER BY
    total_transaction_amount DESC;
```

## Daily closing balance by product

```sql
SELECT
    b.balance_date,
    p.product_name,
    SUM(b.closing_balance) AS total_closing_balance
FROM daily_account_balance b
JOIN account a
    ON b.account_id = a.account_id
JOIN product p
    ON a.product_id = p.product_id
GROUP BY
    b.balance_date,
    p.product_name
ORDER BY
    b.balance_date,
    p.product_name;
```

## Current account status

```sql
SELECT
    a.account_number,
    s.account_status_name,
    h.effective_from_date
FROM account a
JOIN account_status_history h
    ON a.account_id = h.account_id
JOIN account_status s
    ON h.account_status_id = s.account_status_id
WHERE h.is_current = TRUE;
```

## Current customer segment

```sql
SELECT
    c.customer_number,
    s.customer_segment_name,
    h.effective_from_date
FROM customer c
JOIN customer_segment_history h
    ON c.customer_id = h.customer_id
JOIN customer_segment s
    ON h.customer_segment_id = s.customer_segment_id
WHERE h.is_current = TRUE;
```

## Final documentation checklist

```text
Business purpose is clear.
Scope is documented.
Tables are described.
Grain is documented for every important table.
Primary keys and business keys are clear.
Relationships are documented.
Many-to-many relationship is resolved.
Business rules are listed.
Data quality rules are listed.
Analytics model is documented.
Joint account double-counting risk is documented.
Sensitive fields are identified.
Known limitations are stated.
Example queries are included.
```

## Key takeaway

This capstone shows the full modelling path:

```text
Business requirements
→ Conceptual model
→ Logical model
→ Physical model
→ Analytics star schema
→ Data quality rules
→ Documentation
```

The strongest modelling decisions are:

```text
Customer and Account are separate.
Account Holder resolves joint account ownership.
Transactions remain at account grain.
Daily balances are separate snapshots.
Customer segment and account status are historised.
Analytics uses fact and dimension tables.
Joint account reporting requires allocation rules.
```
