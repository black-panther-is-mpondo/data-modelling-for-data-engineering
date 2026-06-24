# Module 02: Business Requirements Thinking

## Goal

The goal of this module is to learn how to read a business requirement and convert it into a data model.

Before designing tables, a data modeller must understand the business process.

A weak modeller asks:

> What columns are in the file?

A strong modeller asks:

> What is happening in the business?

## Why business requirements matter

Data models should represent business meaning, not just source file layouts.

A source file may be flat, messy, duplicated, or badly named. The modeller’s job is to understand the real-world process behind the data and design a structure that supports it correctly.

## Modelling method

When reading a requirement, use this method:

```text
Step 1: Identify nouns
Step 2: Identify verbs
Step 3: Identify business events
Step 4: Identify business rules
Step 5: Identify what can repeat
Step 6: Identify what changes over time
Step 7: Define the grain
````

## Step 1: Identify nouns

Nouns often suggest possible entities.

Example requirement:

```text
Customers place orders for products. Each order can contain multiple products. Customers can return products.
```

Possible nouns:

```text
Customers
Orders
Products
Returns
```

Possible entities:

```text
Customer
Order
Product
Return
```

Not every noun becomes a table. Some nouns become attributes.

Example:

```text
Customers have an email address.
```

`Email address` is usually an attribute of `Customer`, not a separate entity.

However, if the business tracks multiple emails per customer, verification status, or email history, then email may become its own table.

## Step 2: Identify verbs

Verbs often suggest relationships or events.

From this requirement:

```text
Customers place orders.
Orders contain products.
Customers return products.
```

We get:

```text
Customer places Order
Order contains Product
Customer makes Return
```

These relationships help shape the model.

## Step 3: Identify business events

A business event is something that happens and should be recorded.

Examples:

```text
A customer places an order.
A student enrolls in a course.
A payment is made.
A loan application is submitted.
A transaction occurs.
A product is returned.
```

Events often become transaction tables in operational models or fact tables in analytical models.

## Step 4: Identify business rules

Business rules are constraints that must be true.

Examples:

```text
Each order must belong to one customer.
An order can contain many products.
A payment must be linked to an order.
A customer can exist before placing an order.
A product can exist without being ordered.
```

Business rules influence:

* relationships
* optionality
* mandatory fields
* foreign keys
* validation rules
* data quality checks

## Step 5: Identify what can repeat

Repeating data usually suggests a separate table.

Bad design:

```text
order_id
product_1
product_2
product_3
```

Better design:

```text
order
order_item
```

Because products repeat inside an order.

Another example:

```text
customer_id
phone_1
phone_2
phone_3
```

If the business genuinely needs multiple phone numbers per customer, model it as:

```text
customer
customer_phone
```

## Step 6: Identify what changes over time

Some attributes change, and the model must decide whether history matters.

Examples:

```text
Customer address
Product price
Employment status
Account status
Risk rating
Branch assignment
Customer segment
```

Key question:

> Do we only need the latest value, or do we need history?

If only the latest value matters, overwriting may be acceptable.

If history matters, create a history-aware design.

Examples:

```text
customer_address_history
account_status_history
customer_segment_history
```

In analytics, this often becomes a Slowly Changing Dimension pattern.

## Step 7: Define the grain

The grain means:

> What does one row represent?

Examples:

```text
One row per customer
One row per order
One row per order item
One row per payment
One row per student-course enrollment
One row per account transaction
One row per account per day
```

Grain is one of the most important modelling concepts.

A lot of bad models happen because different grains are mixed in one table.

## Example: Clinic requirement

Requirement:

```text
A clinic treats patients. Patients book appointments with doctors. During an appointment, the doctor may prescribe one or more medicines.
```

### Nouns

```text
Clinic
Patients
Appointments
Doctors
Medicines
```

Possible entities:

```text
Patient
Doctor
Appointment
Medicine
```

`Clinic` may or may not be an entity depending on scope. If there is one clinic only, it may be out of scope. If there are many clinic branches, then it should become an entity.

### Verbs and relationships

```text
Patients book appointments.
Doctors treat patients.
Doctors prescribe medicines.
```

Relationships:

```text
Patient 1 --- many Appointment
Doctor 1 --- many Appointment
Appointment many --- many Medicine
```

The many-to-many relationship between appointment and medicine is resolved using:

```text
appointment_prescription
```

### Grains

```text
patient:
One row per patient.

doctor:
One row per doctor.

appointment:
One row per booked appointment.

medicine:
One row per medicine.

appointment_prescription:
One row per medicine prescribed in an appointment.
```

## Banking example

Requirement:

```text
A bank has customers. Customers can open one or more accounts. Some accounts can be jointly owned by multiple customers. Each account can have many transactions. Transactions can be deposits, withdrawals, transfers, or card payments.
```

Possible entities:

```text
Customer
Account
Account Holder
Transaction
Transaction Type
```

Relationships:

```text
Customer many-to-many Account
Account one-to-many Transaction
Transaction many-to-one Transaction Type
```

The important modelling point is joint accounts.

Because one customer can have many accounts, and one account can have many customers, we need a resolving table:

```text
account_holder
```

Grains:

```text
customer:
One row per customer.

account:
One row per account.

account_holder:
One row per customer-account relationship.

transaction:
One row per account transaction.

transaction_type:
One row per transaction type.
```

## Common mistakes

### Mistake 1: Starting with columns instead of the business process

Bad thinking:

```text
What columns do I have?
```

Better thinking:

```text
What business process does this data represent?
```

### Mistake 2: Treating every noun as a table

Not every noun becomes a table. Some become attributes.

Example:

```text
Customer email
```

Usually this is an attribute of `Customer`.

But if multiple emails or email history are required, it may become a separate table.

### Mistake 3: Ignoring repeating data

Repeating columns like this are a warning sign:

```text
phone_1
phone_2
phone_3
```

or:

```text
product_1
product_2
product_3
```

These usually need child tables.

### Mistake 4: Not asking what changes over time

If customer segment, account status, or product price changes over time, the model must decide whether to keep history.

### Mistake 5: Not defining grain

A table without clear grain is dangerous.

Always ask:

```text
What does one row represent?
```

## Key questions to ask before modelling

Use these questions when starting a model:

```text
Who or what are we storing data about?
What events happen?
What needs to be measured?
What relationships exist?
What can repeat?
What changes over time?
What must be historically preserved?
What business rules must always be true?
What questions must the model answer?
What does one row represent?
```

## Key takeaways

* Business requirements drive the model.
* Nouns often suggest entities.
* Verbs often suggest relationships or events.
* Business rules influence constraints and validation.
* Repeating data usually needs a separate table.
* Changing data may require history tracking.
* Grain must be defined clearly.
* Good modelling starts with business understanding, not SQL.