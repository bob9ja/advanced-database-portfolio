-- ==========================================================
-- Portfolio 3: Concurrency Control (Two-Session Experiment)
-- Scenario: Account 1 has ₦70,000. Two ATM/App requests try to withdraw ₦50,000 at the exact same time.
-- ==========================================================

-- ================= TERMINAL 1 (Session A) =================
BEGIN TRANSACTION ISOLATION LEVEL READ COMMITTED;

-- Acquire exclusive row-level lock on Account 1
SELECT account_id, balance FROM accounts WHERE account_id = 1 FOR UPDATE;
-- Returns: 70,000.00 (Session A holds the lock; DO NOT COMMIT YET!)

-- [Now switch to Terminal 2 and run Session B's commands]

-- Back in Terminal 1: Complete withdrawal and release lock
UPDATE accounts SET balance = balance - 50000.00 WHERE account_id = 1;
COMMIT;


-- ================= TERMINAL 2 (Session B) =================
BEGIN TRANSACTION ISOLATION LEVEL READ COMMITTED;

-- Session B attempts to lock and read the same account row.
-- IT WILL FREEZE/BLOCK HERE until Session A runs COMMIT!
SELECT account_id, balance FROM accounts WHERE account_id = 1 FOR UPDATE;

-- Once Session A commits, Session B unblocks and sees the NEW committed balance (20,000.00),
-- preventing a Lost Update / Double-Spend!
-- Attempting to withdraw 50,000 now fails safely:
UPDATE accounts SET balance = balance - 50000.00 WHERE account_id = 1;
ROLLBACK;
