
-- ==========================================================
-- Portfolio 2: Query Processing & Optimisation Benchmarks
-- ==========================================================

-- ----------------------------------------------------------
-- SCENARIO 1: Mobile App Account Statement Query (Before Index)
-- ----------------------------------------------------------
EXPLAIN (ANALYZE, BUFFERS)
SELECT transaction_id, reference_code, receiver_account_id, amount, created_at
FROM transactions
WHERE sender_account_id = 42
  AND status = 'COMPLETED'
  AND created_at >= NOW() - INTERVAL '30 days'
ORDER BY created_at DESC;

-- ----------------------------------------------------------
-- SCENARIO 2: Compliance Failed High-Value Audit (Before Index)
-- ----------------------------------------------------------
EXPLAIN (ANALYZE, BUFFERS)
SELECT transaction_id, sender_account_id, amount, created_at
FROM transactions
WHERE status = 'FAILED'
  AND amount > 200000.00
ORDER BY created_at DESC;


-- ==========================================================
-- APPLYING INDEXING OPTIMISATIONS
-- ==========================================================

-- Optimisation 1: Composite B-Tree Index (Equality columns first, Range/Sort column last)
CREATE INDEX idx_tx_sender_status_created 
ON transactions (sender_account_id, status, created_at DESC);

-- Optimisation 2: Partial Index (Only indexes the ~5% FAILED rows, saving disk & RAM)
CREATE INDEX idx_tx_failed_high_value 
ON transactions (amount, created_at DESC) 
WHERE status = 'FAILED';

-- Refresh planner statistics
ANALYZE transactions;


-- ----------------------------------------------------------
-- RE-RUN SCENARIO 1 (After Composite Index)
-- ----------------------------------------------------------
EXPLAIN (ANALYZE, BUFFERS)
SELECT transaction_id, reference_code, receiver_account_id, amount, created_at
FROM transactions
WHERE sender_account_id = 42
  AND status = 'COMPLETED'
  AND created_at >= NOW() - INTERVAL '30 days'
ORDER BY created_at DESC;

-- ----------------------------------------------------------
-- RE-RUN SCENARIO 2 (After Partial Index)
-- ----------------------------------------------------------
EXPLAIN (ANALYZE, BUFFERS)
SELECT transaction_id, sender_account_id, amount, created_at
FROM transactions
WHERE status = 'FAILED'
  AND amount > 200000.00
ORDER BY created_at DESC;
