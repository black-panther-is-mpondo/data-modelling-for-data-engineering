-- Banking Capstone Physical Model
-- PostgreSQL-style DDL

-- ============================================================
-- Drop tables
-- ============================================================
-- Drop order matters because of foreign key dependencies.

DROP TABLE IF EXISTS daily_account_balance;
DROP TABLE IF EXISTS account_transaction;
DROP TABLE IF EXISTS account_holder;
DROP TABLE IF EXISTS account_status_history;
DROP TABLE IF EXISTS account_status;
DROP TABLE IF EXISTS account;
DROP TABLE IF EXISTS transaction_type;
DROP TABLE IF EXISTS channel;
DROP TABLE IF EXISTS product;
DROP TABLE IF EXISTS branch;
DROP TABLE IF EXISTS customer_segment_history;
DROP TABLE IF EXISTS customer_segment;
DROP TABLE IF EXISTS customer;

-- ============================================================
-- Customer tables
-- ============================================================

CREATE TABLE customer (
    customer_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    customer_number VARCHAR(50) NOT NULL UNIQUE,
    national_id VARCHAR(50) UNIQUE,
    passport_number VARCHAR(50),
    first_name VARCHAR(100) NOT NULL,
    last_name VARCHAR(100) NOT NULL,
    date_of_birth DATE NOT NULL,
    customer_type VARCHAR(30) NOT NULL CHECK (
        customer_type IN ('INDIVIDUAL', 'BUSINESS')
    ),
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP
);

CREATE TABLE customer_segment (
    customer_segment_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    customer_segment_code VARCHAR(50) NOT NULL UNIQUE,
    customer_segment_name VARCHAR(100) NOT NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP
);

CREATE TABLE customer_segment_history (
    customer_segment_history_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    customer_id BIGINT NOT NULL REFERENCES customer(customer_id),
    customer_segment_id BIGINT NOT NULL REFERENCES customer_segment(customer_segment_id),
    effective_from_date DATE NOT NULL,
    effective_to_date DATE,
    is_current BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP,
    CHECK (
        effective_to_date IS NULL
        OR effective_to_date >= effective_from_date
    )
);

-- ============================================================
-- Reference tables
-- ============================================================

CREATE TABLE branch (
    branch_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    branch_code VARCHAR(50) NOT NULL UNIQUE,
    branch_name VARCHAR(150) NOT NULL,
    province VARCHAR(100),
    city VARCHAR(100),
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP
);

CREATE TABLE product (
    product_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    product_code VARCHAR(50) NOT NULL UNIQUE,
    product_name VARCHAR(150) NOT NULL,
    product_category VARCHAR(100) NOT NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP
);

CREATE TABLE channel (
    channel_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    channel_code VARCHAR(50) NOT NULL UNIQUE,
    channel_name VARCHAR(100) NOT NULL,
    channel_group VARCHAR(100) NOT NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP
);

CREATE TABLE transaction_type (
    transaction_type_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    transaction_type_code VARCHAR(50) NOT NULL UNIQUE,
    transaction_type_name VARCHAR(100) NOT NULL,
    transaction_category VARCHAR(100) NOT NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP
);

-- ============================================================
-- Account tables
-- ============================================================

CREATE TABLE account (
    account_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    account_number VARCHAR(50) NOT NULL UNIQUE,
    product_id BIGINT NOT NULL REFERENCES product(product_id),
    branch_id BIGINT NOT NULL REFERENCES branch(branch_id),
    open_date DATE NOT NULL,
    close_date DATE,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP,
    CHECK (
        close_date IS NULL
        OR close_date >= open_date
    )
);

CREATE TABLE account_status (
    account_status_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    account_status_code VARCHAR(50) NOT NULL UNIQUE,
    account_status_name VARCHAR(100) NOT NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP
);

CREATE TABLE account_status_history (
    account_status_history_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    account_id BIGINT NOT NULL REFERENCES account(account_id),
    account_status_id BIGINT NOT NULL REFERENCES account_status(account_status_id),
    effective_from_date DATE NOT NULL,
    effective_to_date DATE,
    is_current BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP,
    CHECK (
        effective_to_date IS NULL
        OR effective_to_date >= effective_from_date
    )
);

CREATE TABLE account_holder (
    account_holder_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    customer_id BIGINT NOT NULL REFERENCES customer(customer_id),
    account_id BIGINT NOT NULL REFERENCES account(account_id),
    holder_role VARCHAR(50) NOT NULL CHECK (
        holder_role IN ('PRIMARY', 'JOINT', 'SIGNATORY', 'AUTHORIZED_USER')
    ),
    ownership_percentage NUMERIC(5,2),
    start_date DATE NOT NULL,
    end_date DATE,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP,
    CHECK (
        end_date IS NULL
        OR end_date >= start_date
    ),
    CHECK (
        ownership_percentage IS NULL
        OR ownership_percentage BETWEEN 0 AND 100
    ),
    UNIQUE (customer_id, account_id, start_date)
);

-- ============================================================
-- Transaction and balance tables
-- ============================================================

CREATE TABLE account_transaction (
    transaction_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    transaction_reference VARCHAR(100) NOT NULL UNIQUE,
    account_id BIGINT NOT NULL REFERENCES account(account_id),
    transaction_type_id BIGINT NOT NULL REFERENCES transaction_type(transaction_type_id),
    channel_id BIGINT NOT NULL REFERENCES channel(channel_id),
    transaction_datetime TIMESTAMP NOT NULL,
    posted_date DATE NOT NULL,
    amount NUMERIC(18,2) NOT NULL CHECK (amount <> 0),
    currency_code CHAR(3) NOT NULL,
    description VARCHAR(255),
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE daily_account_balance (
    daily_account_balance_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    account_id BIGINT NOT NULL REFERENCES account(account_id),
    balance_date DATE NOT NULL,
    opening_balance NUMERIC(18,2) NOT NULL,
    closing_balance NUMERIC(18,2) NOT NULL,
    available_balance NUMERIC(18,2) NOT NULL,
    currency_code CHAR(3) NOT NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    UNIQUE (account_id, balance_date)
);

-- ============================================================
-- Indexes
-- ============================================================

CREATE INDEX idx_customer_segment_history_customer_id
ON customer_segment_history(customer_id);

CREATE INDEX idx_customer_segment_history_segment_id
ON customer_segment_history(customer_segment_id);

CREATE INDEX idx_account_product_id
ON account(product_id);

CREATE INDEX idx_account_branch_id
ON account(branch_id);

CREATE INDEX idx_account_status_history_account_id
ON account_status_history(account_id);

CREATE INDEX idx_account_status_history_status_id
ON account_status_history(account_status_id);

CREATE INDEX idx_account_holder_customer_id
ON account_holder(customer_id);

CREATE INDEX idx_account_holder_account_id
ON account_holder(account_id);

CREATE INDEX idx_account_transaction_account_id
ON account_transaction(account_id);

CREATE INDEX idx_account_transaction_type_id
ON account_transaction(transaction_type_id);

CREATE INDEX idx_account_transaction_channel_id
ON account_transaction(channel_id);

CREATE INDEX idx_account_transaction_posted_date
ON account_transaction(posted_date);

CREATE INDEX idx_daily_account_balance_account_id
ON daily_account_balance(account_id);

CREATE INDEX idx_daily_account_balance_balance_date
ON daily_account_balance(balance_date);

-- ============================================================
-- Seed reference data
-- ============================================================

INSERT INTO customer_segment (
    customer_segment_code,
    customer_segment_name
)
VALUES
    ('STUDENT', 'Student'),
    ('MASS_MARKET', 'Mass Market'),
    ('MIDDLE_INCOME', 'Middle Income'),
    ('PREMIUM', 'Premium'),
    ('PRIVATE_BANKING', 'Private Banking'),
    ('BUSINESS', 'Business');

INSERT INTO account_status (
    account_status_code,
    account_status_name
)
VALUES
    ('ACTIVE', 'Active'),
    ('DORMANT', 'Dormant'),
    ('SUSPENDED', 'Suspended'),
    ('CLOSED', 'Closed');

INSERT INTO channel (
    channel_code,
    channel_name,
    channel_group
)
VALUES
    ('BRANCH', 'Branch', 'Physical'),
    ('ATM', 'ATM', 'Self Service'),
    ('MOBILE_APP', 'Mobile App', 'Digital'),
    ('INTERNET_BANKING', 'Internet Banking', 'Digital'),
    ('CARD', 'Card', 'Card'),
    ('USSD', 'USSD', 'Digital'),
    ('CALL_CENTRE', 'Call Centre', 'Assisted');

INSERT INTO transaction_type (
    transaction_type_code,
    transaction_type_name,
    transaction_category
)
VALUES
    ('DEPOSIT', 'Deposit', 'Credit'),
    ('WITHDRAWAL', 'Withdrawal', 'Debit'),
    ('TRANSFER', 'Transfer', 'Transfer'),
    ('CARD_PAYMENT', 'Card Payment', 'Debit'),
    ('DEBIT_ORDER', 'Debit Order', 'Debit'),
    ('FEE', 'Fee', 'Debit'),
    ('INTEREST', 'Interest', 'Credit');

-- ============================================================
-- Notes
-- ============================================================
-- 1. Transactions are stored at account grain.
-- 2. Daily balances are stored at account-day grain.
-- 3. Joint account ownership is handled by account_holder.
-- 4. Customer-level transaction reporting needs allocation rules.
-- 5. Customer segment and account status history require extra checks
--    to prevent overlapping effective date ranges.
