-- ==========================================================
-- Portfolio 3: ACID Transactions (COMMIT vs ROLLBACK)
-- ==========================================================

-- Reset Account 1 (Amina) to ₦100,000 and Account 3 (Chinedu) to ₦50,000 for clean testing
UPDATE accounts SET balance = 100000.00 WHERE account_id = 1;
UPDATE accounts SET balance = 50000.00 WHERE account_id = 3;

-- ----------------------------------------------------------
-- TEST 1: Successful Atomic Fund Transfer (COMMIT)
-- ----------------------------------------------------------
BEGIN;

DO $$
DECLARE
    v_tx_id UUID;
    v_sender_bal NUMERIC(15, 2);
    v_receiver_bal NUMERIC(15, 2);
    v_transfer_amt NUMERIC(15, 2) := 30000.00;
BEGIN
    -- 1. Lock both rows in deterministic account_id order to prevent deadlocks
    SELECT balance INTO v_sender_bal FROM accounts WHERE account_id = 1 FOR UPDATE;
    SELECT balance INTO v_receiver_bal FROM accounts WHERE account_id = 3 FOR UPDATE;

    -- 2. Debit Sender
    UPDATE accounts 
    SET balance = balance - v_transfer_amt 
    WHERE account_id = 1 
    RETURNING balance INTO v_sender_bal;

    -- 3. Credit Receiver
    UPDATE accounts 
    SET balance = balance + v_transfer_amt 
    WHERE account_id = 3 
    RETURNING balance INTO v_receiver_bal;

    -- 4. Record Transaction Header
    INSERT INTO transactions (reference_code, sender_account_id, receiver_account_id, amount, transaction_type, status, narration)
    VALUES ('TRX-ACID-COMMIT-01', 1, 3, v_transfer_amt, 'TRANSFER', 'COMPLETED', 'Atomic P2P Transfer')
    RETURNING transaction_id INTO v_tx_id;

    -- 5. Record Double-Entry Ledger Postings
    INSERT INTO ledger_entries (transaction_id, account_id, entry_type, amount, balance_after)
    VALUES 
        (v_tx_id, 1, 'DEBIT', v_transfer_amt, v_sender_bal),
        (v_tx_id, 3, 'CREDIT', v_transfer_amt, v_receiver_bal);
END $$;

COMMIT;

-- Verify: Account 1 = 70,000.00 | Account 3 = 80,000.00
SELECT account_id, account_number, balance FROM accounts WHERE account_id IN (1, 3);


-- ----------------------------------------------------------
-- TEST 2: Failed Overdraft Transfer (ROLLBACK)
-- Account 1 only has ₦70,000. Attempting to send ₦95,000 violates CHECK (balance >= 0).
-- ----------------------------------------------------------
BEGIN;

-- Step A: Credit receiver first (simulating partial execution before failure)
UPDATE accounts SET balance = balance + 95000.00 WHERE account_id = 3;

-- Step B: Attempt to debit sender (FAILS with check_violation error!)
UPDATE accounts SET balance = balance - 95000.00 WHERE account_id = 1;

-- Because Step B threw an error, PostgreSQL aborts the transaction block.
-- Issuing ROLLBACK undoes Step A completely so Account 3 does not get free money.
ROLLBACK;

-- Verify Atomicity: Account 1 is still 70,000.00 and Account 3 is still 80,000.00
SELECT account_id, account_number, balance FROM accounts WHERE account_id IN (1, 3);
