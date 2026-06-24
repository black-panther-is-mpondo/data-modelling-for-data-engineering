# Module 03: Entities, Attributes, and Relationships

## Goal

The goal of this module is to understand the three basic building blocks of a data model:

```text
Entity
Attribute
Relationship
````

A strong data model starts with knowing what these are and how they work together.

## Core idea

Think of it like this:

```text
Entity = thing
Attribute = detail about the thing
Relationship = how things connect
```

Example:

```text
Customer opens Account
Account has Transaction
```

Here:

```text
Customer = entity
Account = entity
Transaction = entity

customer_name = attribute
account_number = attribute
transaction_amount = attribute

opens / has = relationships
```

## Entity

An entity is a real-world object, concept, person, place, or event that we want to store data about.

Examples:

```text
Customer
Account
Transaction
Product
Branch
Employee
Loan
Payment
Course
Student
Order
```

A useful test:

> Can this thing have records of its own?

If yes, it may be an entity.

For example:

```text
Customer
```

There can be many customers, so `Customer` is an entity.

```text
Account
```

There can be many accounts, so `Account` is an entity.

```text
Transaction
```

There can be many transactions, so `Transaction` is an entity.

But:

```text
customer_first_name
```

is not an entity. It is an attribute of `Customer`.

## Attribute

An attribute is a property or detail about an entity.

Example:

```text
Customer
- customer_id
- first_name
- last_name
- date_of_birth
- national_id
- email
```

The entity is `Customer`.

The attributes describe the customer.

Another example:

```text
Account
- account_id
- account_number
- account_type
- open_date
- account_status
```

The entity is `Account`.

The attributes describe the account.

## Relationship

A relationship shows how entities are connected.

Examples:

```text
Customer owns Account
Account has Transaction
Branch manages Account
Student enrolls in Course
Customer places Order
```

Relationships often come from verbs:

```text
owns
has
manages
places
makes
enrolls
belongs to
contains
```

In modelling, we care about the relationship type:

```text
One-to-one
One-to-many
Many-to-many
```

## One-to-one relationship

A one-to-one relationship means one record in table A relates to one record in table B.

Example:

```text
Person 1 --- 1 Passport
```

One person has one passport.

One passport belongs to one person.

In practice, one-to-one relationships are less common than people think. Often, the two things can be stored in the same table unless there is a strong reason to separate them.

Possible reasons to separate:

```text
Sensitive information
Optional details
Different access permissions
Different lifecycle
Very wide table
```

Banking example:

```text
Customer 1 --- 1 KYC Profile
```

KYC data may be separated from customer data because it has different compliance, privacy, or access rules.

## One-to-many relationship

A one-to-many relationship means one record in table A can relate to many records in table B.

Examples:

```text
Account 1 --- many Transactions
Branch 1 --- many Accounts
Account Type 1 --- many Accounts
Transaction Type 1 --- many Transactions
```

In the database, the foreign key usually goes on the many side.

Example:

```text
branch
- branch_id
- branch_name

account
- account_id
- branch_id
- account_number
```

Because many accounts can belong to one branch, `branch_id` belongs in the `account` table.

## Many-to-many relationship

A many-to-many relationship means many records in table A can relate to many records in table B.

Banking example:

```text
Customer many --- many Account
```

Why?

```text
One customer can have many accounts.
One account can have many customers.
```

This is common because of joint accounts.

You cannot model this properly by putting only `customer_id` inside `account`.

Bad model:

```text
account
- account_id
- customer_id
```

This fails if the account has multiple customers.

Better model:

```text
customer
account
account_holder
```

The `account_holder` table resolves the many-to-many relationship.

```text
customer 1 --- many account_holder
account  1 --- many account_holder
```

Example:

```text
account_holder
- account_holder_id
- customer_id
- account_id
- holder_role
- start_date
- end_date
```

Grain:

```text
One row per customer-account relationship.
```

## Resolving table

A resolving table, also called a bridge or junction table, is used to resolve a many-to-many relationship.

Examples:

```text
Student many --- many Course
```

Resolved by:

```text
enrollment
```

```text
Customer many --- many Account
```

Resolved by:

```text
account_holder
```

```text
Order many --- many Product
```

Resolved by:

```text
order_item
```

A resolving table often becomes an important business entity because it can have its own attributes.

Example:

```text
enrollment
- student_id
- course_id
- enrollment_date
- final_mark
```

Here, `final_mark` belongs to the relationship between student and course.

It does not belong only to student or only to course.

## Strong entity vs weak entity

A strong entity can exist independently.

Examples:

```text
Customer
Product
Branch
Course
```

A weak entity depends on another entity.

Examples:

```text
Order Item
Enrollment
Account Holder
Repayment Schedule Line
```

`Order Item` cannot exist without an order.

`Enrollment` cannot exist without a student and a course.

`Account Holder` cannot exist without a customer and an account.

## Attribute or entity?

Sometimes it is not obvious whether something should be an attribute or a separate entity.

Ask:

> Does this thing have its own attributes, history, or many records?

If yes, it may deserve its own table.

## Example: Customer email

Usually:

```text
customer
- email
```

But if the business allows multiple emails per customer, tracks verification status, or keeps email history, then use:

```text
customer_email
- customer_email_id
- customer_id
- email
- email_type
- is_verified
- effective_from
- effective_to
```

## Example: Account type

Account type is usually a separate lookup table:

```text
account_type
- account_type_id
- account_type_code
- account_type_name
```

Because many accounts can share the same account type.

## Example: Branch

Branch should usually be an entity:

```text
branch
- branch_id
- branch_code
- branch_name
- province
```

Because many accounts, customers, employees, or transactions may relate to a branch.

## Optional vs mandatory relationships

Relationships can be optional or mandatory.

Example:

```text
Customer 1 --- many Account
```

Can a customer exist without an account?

In banking, yes. A person may be registered as a prospect or applicant before opening an account.

So:

```text
Customer can exist without Account.
Account must have at least one Customer.
```

Another example:

```text
Account 1 --- many Transaction
```

A new account may have no transactions yet.

So:

```text
Account can exist without Transaction.
Transaction must belong to one Account.
```

This matters when designing foreign keys, nullable fields, and validation rules.

## Cardinality and participation

When describing relationships, define two things:

```text
Cardinality = how many?
Participation = must it exist?
```

Example:

```text
Account 1 --- many Transactions
```

More precise:

```text
One account can have zero, one, or many transactions.
Each transaction must belong to exactly one account.
```

That is stronger than simply saying:

```text
Account has many transactions.
```

## Banking example

Requirement:

```text
A bank has branches. Each branch manages many accounts. Customers can hold one or more accounts. Some accounts are jointly held. Each account has many transactions. Each transaction has a transaction type.
```

Entities:

```text
Branch
Customer
Account
Account Holder
Transaction
Transaction Type
```

Attributes:

```text
Branch
- branch_id
- branch_code
- branch_name
- province

Customer
- customer_id
- national_id
- first_name
- last_name
- date_of_birth

Account
- account_id
- account_number
- account_type
- open_date
- account_status

Account Holder
- customer_id
- account_id
- holder_role
- start_date
- end_date

Transaction
- transaction_id
- account_id
- transaction_type_id
- transaction_datetime
- amount

Transaction Type
- transaction_type_id
- transaction_type_name
```

Relationships:

```text
Branch 1 --- many Account
Customer many --- many Account, resolved by Account Holder
Account 1 --- many Transaction
Transaction Type 1 --- many Transaction
```

Participation:

```text
A branch can manage zero, one, or many accounts.
Each account must belong to one branch.

A customer can hold zero, one, or many accounts.
Each account must have at least one account holder.

An account can have zero, one, or many transactions.
Each transaction must belong to one account.

A transaction type can classify many transactions.
Each transaction must have one transaction type.
```

## Common mistakes

### Mistake 1: Treating a many-to-many relationship as one-to-many

Bad:

```text
account
- account_id
- customer_id
```

This fails for joint accounts.

Better:

```text
account_holder
- account_id
- customer_id
```

### Mistake 2: Calling every column an entity

Bad entities:

```text
customer_name
customer_email
account_number
```

These are attributes, not entities.

### Mistake 3: Using vague resolving table names

Weak:

```text
customer_account_map
```

Better:

```text
account_holder
```

A good table name should explain what one row represents.

### Mistake 4: Not defining the grain

Every table needs a clear grain.

Always ask:

```text
What does one row represent?
```

## Key takeaways

* Entities are things we store data about.
* Attributes describe entities.
* Relationships connect entities.
* One-to-many relationships place the foreign key on the many side.
* Many-to-many relationships need resolving tables.
* Resolving tables often carry important business attributes.
* Optionality matters because not every relationship must exist immediately.
* Cardinality tells us how many records can relate.
* Participation tells us whether the relationship is required.
* Good table names should describe the business meaning of each row.
