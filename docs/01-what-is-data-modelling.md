# Module 01: What Is Data Modelling?

## Goal

The goal of this module is to understand what data modelling means in data engineering and why it matters before creating tables, pipelines, dashboards, or reports.

Data modelling is not just writing SQL tables. It is the process of designing how business meaning should be represented in data.

## What is data modelling?

Data modelling is the process of designing how data should be structured, stored, related, and used.

It answers questions like:

- What things exist in the business?
- What information do we need about those things?
- How are those things related?
- What rules must the data follow?
- What does one row in each table represent?
- How should the data support reporting, analytics, or operations?

In simple terms:

> Data modelling turns business reality into a clear data structure.

## Why data modelling matters

Bad data modelling creates problems such as:

- duplicated data
- unclear relationships
- inconsistent definitions
- slow queries
- broken joins
- wrong reporting numbers
- hard-to-maintain pipelines

Good data modelling helps make data:

- easier to understand
- easier to query
- easier to maintain
- more reliable
- more consistent
- safer for reporting and analytics

## Data modelling vs just creating tables

A common mistake is to start with the source file and create a table that looks exactly like the file.

For example, a source file may contain:

```text
customer_name
customer_email
order_date
product_1
product_2
product_3
payment_amount
payment_method
````

This may look simple, but it is weak modelling.

Problems:

* What if an order has more than three products?
* What if a customer changes email?
* What if an order has multiple payments?
* What if the same product appears in many orders?
* What if we need total sales by product?

A better approach is to first identify the business concepts:

```text
Customer
Order
Product
Payment
```

Then we design how they relate:

```text
Customer places Order
Order contains Product
Order has Payment
```

That is data modelling thinking.

## The three levels of data modelling

Data modelling usually happens at three levels:

1. Conceptual model
2. Logical model
3. Physical model

## Conceptual model

A conceptual model is the high-level business view.

It focuses on:

* main business entities
* relationships
* business rules
* scope

Example:

```text
Customer places Order
Order contains Product
Order has Payment
```

At this stage, we do not worry about SQL, data types, indexes, or partitions.

## Logical model

A logical model converts the business view into structured tables and fields.

Example:

```text
customer
- customer_id
- first_name
- last_name
- email

order
- order_id
- customer_id
- order_date
- order_status

product
- product_id
- product_name
- category

order_item
- order_id
- product_id
- quantity
- unit_price

payment
- payment_id
- order_id
- payment_date
- payment_amount
- payment_method
```

The logical model includes:

* tables
* columns
* primary keys
* foreign keys
* relationships
* optional and mandatory fields

## Physical model

A physical model is the actual database implementation.

Example:

```sql
CREATE TABLE customer (
    customer_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    first_name VARCHAR(100) NOT NULL,
    last_name VARCHAR(100) NOT NULL,
    email VARCHAR(255) UNIQUE,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);
```

The physical model includes:

* SQL data types
* constraints
* indexes
* partitions
* audit columns
* database-specific choices

## Entities, attributes, and relationships

Every data model is built from three main building blocks:

```text
Entity
Attribute
Relationship
```

## Entity

An entity is a thing we store data about.

Examples:

```text
Customer
Product
Order
Payment
Account
Transaction
Student
Course
```

A useful test:

> Can this thing have records of its own?

If yes, it may be an entity.

## Attribute

An attribute is a detail about an entity.

Example:

```text
Customer
- first_name
- last_name
- email
- date_of_birth
```

The entity is `Customer`.

The attributes describe the customer.

## Relationship

A relationship describes how entities connect.

Examples:

```text
Customer places Order
Order contains Product
Account has Transaction
Student enrolls in Course
```

Relationships often come from verbs in the business requirement.

## Grain

The grain is one of the most important ideas in data modelling.

Grain means:

> What does one row represent?

Examples:

```text
One row per customer
One row per order
One row per order item
One row per payment
One row per account transaction
One row per account per day
```

If the grain is unclear, the table is dangerous.

A table without clear grain can cause duplicates, broken joins, and wrong totals.

## Example

Business requirement:

```text
A customer places orders. Each order can contain multiple products. A payment is made for an order.
```

Possible entities:

```text
Customer
Order
Product
Payment
```

Relationships:

```text
Customer places Order
Order contains Product
Order has Payment
```

Cardinality:

```text
One customer can place many orders.
One order belongs to one customer.

One order can contain many products.
One product can appear in many orders.

One order can have one or more payments.
One payment belongs to one order.
```

The many-to-many relationship between `Order` and `Product` is resolved using `Order Item`.

Model:

```text
Customer
  |
  | one-to-many
  v
Order
  |
  | one-to-many
  v
Order Item
  ^
  | many-to-one
  |
Product

Order
  |
  | one-to-many
  v
Payment
```

## Common beginner mistake

A beginner may design this:

```text
order
- order_id
- customer_name
- product_1
- product_2
- product_3
- payment_amount
```

This is weak because it stores repeating product columns.

A better design is:

```text
order
- order_id
- customer_id
- order_date

order_item
- order_id
- product_id
- quantity
- unit_price
```

Now an order can have one product, three products, or one hundred products without changing the table structure.

## Why data engineers need data modelling

Data engineers often receive raw data that is messy, flat, duplicated, or badly named.

Example raw data:

```text
order_id
customer_name
customer_email
product_name
quantity
payment_amount
payment_method
order_date
```

The raw file does not always show the correct model.

A data engineer must ask:

* Is customer data repeated because the same customer placed many orders?
* Is product data repeated because many orders contain the same product?
* Can an order have multiple payments?
* Can product price change over time?
* What should one row represent?
* What relationships exist?
* What should be preserved historically?

This is why data modelling is a core data engineering skill.

## Key takeaways

* Data modelling represents business meaning in data.
* It is not the same as blindly creating tables from files.
* Conceptual models focus on business meaning.
* Logical models define tables, columns, keys, and relationships.
* Physical models implement the design in a real database.
* Entities are things we store data about.
* Attributes describe entities.
* Relationships connect entities.
* Grain means what one row represents.
* A strong model starts with business understanding, not SQL.