# Module 12: Slowly Changing Dimensions

## Goal

The goal of this module is to understand how to handle changes in dimension data over time.

In dimensional modelling, dimensions describe facts.

Examples:

```text
dim_customer
dim_product
dim_branch
dim_account
dim_employee
````

But dimension values can change.

Examples:

```text
Customer changes address
Customer moves from Student segment to Premium segment
Branch changes region
Product changes category
Account status changes
```

The key modelling question is:

> Do we overwrite the old value, or do we keep history?

That is what Slowly Changing Dimensions, or SCDs, help us decide.

## Why SCDs matter

Suppose a customer was in the `Student` segment in 2025 and moved to the `Premium` segment in 2026.

They made transactions in both years.

Question:

> When reporting 2025 transactions, should those transactions show the customer as Student or Premium?

If we overwrite the customer segment, all historical transactions may now appear under Premium. That may be wrong.

So we need a strategy.

## SCD Type 0: Never change

SCD Type 0 means the value does not change after it is first loaded.

Examples:

```text
date_of_birth
original_customer_join_date
original_account_open_date
```

If the value changes in the source, it is usually treated as a correction issue, not a normal business change.

Example:

```text
dim_customer
- customer_key
- customer_number
- date_of_birth
```

You normally do not track a full history of date of birth changes.

You correct it if it was captured incorrectly.

## SCD Type 1: Overwrite

SCD Type 1 means the value is updated and no history is kept.

Example:

Before:

```text
customer_number | first_name | segment
----------------|------------|---------
C001            | Thabo      | Student
```

After update:

```text
customer_number | first_name | segment
----------------|------------|---------
C001            | Thabo      | Premium
```

The old value is gone.

Use Type 1 when:

```text
History is not needed
The old value was wrong
Only the latest value matters
```

Examples:

```text
Correcting spelling mistakes
Fixing formatting issues
Correcting captured values
Updating latest email address when history is not required
```

Risk:

```text
Historical reports can change when dimension values are overwritten.
```

## SCD Type 2: Keep full history

SCD Type 2 means we create a new row when important descriptive data changes.

Example:

```text
customer_key | customer_number | segment | effective_from | effective_to | is_current
-------------|-----------------|---------|----------------|--------------|-----------
101          | C001            | Student | 2025-01-01     | 2025-12-31   | false
205          | C001            | Premium | 2026-01-01     | null         | true
```

Same business customer:

```text
customer_number = C001
```

Different warehouse rows:

```text
customer_key = 101
customer_key = 205
```

Facts link to the version that was true at the time.

Example:

```text
2025 transaction → customer_key 101
2026 transaction → customer_key 205
```

This allows point-in-time reporting.

Use Type 2 when:

```text
History matters
Reports must reflect what was true at the time
Regulatory or audit requirements exist
Customer segmentation changes must be tracked
Risk ratings change over time
```

## Important SCD Type 2 columns

A Type 2 dimension usually has:

```text
surrogate key
business key
descriptive attributes
effective_from_date
effective_to_date
is_current
```

Example:

```text
dim_customer
- customer_key
- customer_number
- customer_type
- age_band
- customer_segment
- effective_from_date
- effective_to_date
- is_current
```

Key distinction:

```text
customer_key = surrogate warehouse key
customer_number = business/source key
```

This matters because one customer number can appear multiple times in the dimension history.

## SCD Type 3: Limited history in columns

SCD Type 3 keeps limited history by adding previous-value columns.

Example:

```text
customer_number | current_segment | previous_segment
----------------|-----------------|-----------------
C001            | Premium         | Student
```

This is simpler than Type 2, but limited.

It only works when you need a small amount of history, such as current and previous value.

Use Type 3 rarely. Type 2 is usually more flexible for analytics.

## Banking example

Customer changes province and segment.

In a Type 2 model:

```text
dim_customer
- customer_key
- customer_number
- province
- segment
- effective_from_date
- effective_to_date
- is_current
```

Example records:

```text
customer_key | customer_number | province      | segment | effective_from | effective_to | is_current
-------------|-----------------|---------------|---------|----------------|--------------|-----------
10           | C900            | Gauteng       | Student | 2025-01-01     | 2025-12-31   | false
18           | C900            | Western Cape  | Premium | 2026-01-01     | null         | true
```

Transaction facts:

```text
fact_transaction
- transaction_key
- date_key
- customer_key
- transaction_amount
```

Then:

```text
2025 transactions point to customer_key 10.
2026 transactions point to customer_key 18.
```

Historical reporting remains accurate.

## Account status example

An account status can change over time:

```text
ACTIVE → SUSPENDED → ACTIVE → CLOSED
```

If historical reporting matters, use a status history design.

Operational-style history table:

```text
account_status_history
- account_status_history_id
- account_id
- account_status_id
- effective_from_date
- effective_to_date
- is_current
```

Dimensional-style version:

```text
dim_account
- account_key
- account_number
- account_status
- effective_from_date
- effective_to_date
- is_current
```

Facts should link to the correct account version for the reporting date.

## How facts connect to Type 2 dimensions

For Type 2 dimensions, facts should connect to the correct dimension row.

Example:

```text
fact_transaction.transaction_date = 2025-08-10
customer_number = C001
```

The pipeline should find the customer dimension row where:

```text
customer_number = C001
transaction_date >= effective_from_date
transaction_date <= effective_to_date, or effective_to_date is null
```

Then store the correct `customer_key` in the fact.

## Common SCD mistakes

### Mistake 1: Overwriting everything

If everything is Type 1, historical reports can silently change.

Example:

```text
2025 transactions may suddenly report under the customer’s 2026 segment.
```

That is dangerous when historical accuracy matters.

### Mistake 2: Type 2 everything

Not every change deserves history.

Tracking every spelling correction, phone typo, or formatting change can bloat the dimension.

Be deliberate.

### Mistake 3: Joining facts to current dimension rows only

Bad logic:

```text
Join fact to dim_customer where is_current = true
```

This destroys point-in-time history.

For historical reporting, facts should already store the correct surrogate key, or the join must use date ranges carefully.

### Mistake 4: Not defining the business key

For Type 2, you need a stable business key.

Examples:

```text
customer_number
account_number
product_code
branch_code
```

Without a business key, you cannot know which source entity the historical rows belong to.

### Mistake 5: Overlapping effective date ranges

Bad:

```text
customer_number | segment | effective_from | effective_to
----------------|---------|----------------|-------------
C001            | Student | 2025-01-01     | 2025-12-31
C001            | Premium | 2025-06-01     | null
```

The customer has two segments for the same date range.

This must be prevented with data quality checks.

## SCD decision pattern

Use this pattern:

```text
Correction?
→ Type 1

Never-changing original value?
→ Type 0

History needed for reporting?
→ Type 2

Only previous/current needed?
→ Type 3
```

## Banking SCD recommendations

Likely Type 2:

```text
customer segment
customer risk rating
account status
branch region, if branch hierarchy changes matter
product category, if product hierarchy changes matter
```

Likely Type 1:

```text
spelling corrections
formatting fixes
incorrect captured values
latest contact detail when history is not required
```

Likely Type 0:

```text
original account open date
original customer join date
date of birth, unless corrected
```

## Key takeaways

* Slowly Changing Dimensions control how descriptive data changes over time.
* Type 0 means do not change.
* Type 1 means overwrite.
* Type 2 means keep history with new rows and effective dates.
* Type 3 means keep limited history in extra columns.
* Type 2 is the most important SCD pattern for historical analytics.
* Facts should link to the dimension version that was true at the time of the event.
* Do not join historical facts only to current dimension rows.
