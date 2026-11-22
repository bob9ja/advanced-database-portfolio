-- ==========================================================
-- Portfolio 1: CoreTrust Digital Bank Relational Schema
-- DBMS: PostgreSQL 15+
-- ==========================================================

-- Clean slate for re-runs
DROP TABLE IF EXISTS ledger_entries CASCADE;
DROP TABLE IF EXISTS transactions CASCADE;
DROP TABLE IF EXISTS accounts CASCADE;
DROP TABLE IF EXISTS customers CASCADE;
DROP TABLE IF EXISTS kyc_tiers CASCADE;

-- 1. KYC Tiers Lookup Table (Eliminates transitive dependency for 3NF)
CREATE TABLE kyc_tiers (
    tier_id INT PRIMARY KEY,
    tier_name VARCHAR(30) NOT NULL UNIQUE,
    daily_transfer_limit NUMERIC(15, 2) NOT NULL CHECK (daily_transfer_limit > 0),
    max_balance_limit NUMERIC(15, 2) -- NULL means unlimited
);

-- 2. Customers Table
CREATE TABLE customers (
    customer_id SERIAL PRIMARY KEY,
    first_name VARCHAR(50) NOT NULL,
    last_name VARCHAR(50) NOT NULL,
    email VARCHAR(120) NOT NULL UNIQUE,
    phone_number VARCHAR(20) NOT NULL UNIQUE,
    bvn CHAR(11) NOT NULL UNIQUE, -- Bank Verification Number
    tier_id INT NOT NULL REFERENCES kyc_tiers(tier_id) ON UPDATE CASCADE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- 3. Bank Accounts Table
CREATE TABLE accounts (
    account_id SERIAL PRIMARY KEY,
    customer_id INT NOT NULL REFERENCES customers(customer_id) ON DELETE RESTRICT,
    account_number CHAR(10) NOT NULL UNIQUE,
    account_type VARCHAR(20) NOT NULL CHECK (account_type IN ('SAVINGS', 'CURRENT', 'DOMICILIARY')),
    currency CHAR(3) NOT NULL DEFAULT 'NGN',
    balance NUMERIC(15, 2) NOT NULL DEFAULT 0.00 CHECK (balance >= 0.00),
    status VARCHAR(15) NOT NULL DEFAULT 'ACTIVE' CHECK (status IN ('ACTIVE', 'FROZEN', 'CLOSED')),
    opened_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- 4. Transactions Header Table
CREATE TABLE transactions (
    transaction_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    reference_code VARCHAR(32) NOT NULL UNIQUE,
    sender_account_id INT REFERENCES accounts(account_id),
    receiver_account_id INT REFERENCES accounts(account_id),
    amount NUMERIC(15, 2) NOT NULL CHECK (amount > 0.00),
    transaction_type VARCHAR(20) NOT NULL CHECK (transaction_type IN ('TRANSFER', 'DEPOSIT', 'WITHDRAWAL', 'REVERSAL')),
    status VARCHAR(15) NOT NULL CHECK (status IN ('PENDING', 'COMPLETED', 'FAILED', 'REVERSED')),
    narration VARCHAR(255),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT chk_different_accounts CHECK (sender_account_id IS DISTINCT FROM receiver_account_id)
);

-- 5. Double-Entry Ledger Table (Immutable Audit Trail)
CREATE TABLE ledger_entries (
    entry_id BIGSERIAL PRIMARY KEY,
    transaction_id UUID NOT NULL REFERENCES transactions(transaction_id) ON DELETE RESTRICT,
    account_id INT NOT NULL REFERENCES accounts(account_id) ON DELETE RESTRICT,
    entry_type VARCHAR(10) NOT NULL CHECK (entry_type IN ('DEBIT', 'CREDIT')),
    amount NUMERIC(15, 2) NOT NULL CHECK (amount > 0.00),
    balance_after NUMERIC(15, 2) NOT NULL CHECK (balance_after >= 0.00),
    recorded_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);
