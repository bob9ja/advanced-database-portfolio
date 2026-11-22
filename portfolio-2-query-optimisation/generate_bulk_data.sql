
-- ==========================================================
-- Portfolio 2: Bulk Data Generator for Performance Testing
-- ==========================================================

-- 1. Generate 1,000 synthetic customers
INSERT INTO customers (first_name, last_name, email, phone_number, bvn, tier_id)
SELECT 
    'Customer_' || g,
    'User_' || g,
    'user' || g || '@coretrust.ng',
    '+23480' || LPAD(g::text, 8, '0'),
    LPAD((22200000000 + g)::text, 11, '0'),
    (g % 3) + 1
FROM generate_series(10, 1009) AS g;

-- 2. Generate 1,000 corresponding accounts
INSERT INTO accounts (customer_id, account_number, account_type, currency, balance)
SELECT 
    customer_id,
    LPAD((1000000000 + customer_id)::text, 10, '0'),
    CASE WHEN customer_id % 2 = 0 THEN 'SAVINGS' ELSE 'CURRENT' END,
    'NGN',
    ROUND((RANDOM() * 5000000)::numeric, 2)
FROM customers
WHERE customer_id >= 4;

-- 3. Generate 100,000 historical transactions over the past 365 days
INSERT INTO transactions (
    reference_code, 
    sender_account_id, 
    receiver_account_id, 
    amount, 
    transaction_type, 
    status, 
    narration, 
    created_at
)
SELECT 
    'BULK-TRX-' || g,
    (g % 990) + 1,
    ((g + 7) % 990) + 1,
    ROUND((RANDOM() * 250000 + 500)::numeric, 2),
    'TRANSFER',
    CASE 
        WHEN g % 20 = 0 THEN 'FAILED'
        WHEN g % 50 = 0 THEN 'REVERSED'
        ELSE 'COMPLETED'
    END,
    'Automated payment batch #' || g,
    NOW() - (RANDOM() * INTERVAL '365 days')
FROM generate_series(1, 100000) AS g;

-- Update PostgreSQL statistics so the query planner has accurate row counts
ANALYZE customers;
ANALYZE accounts;
ANALYZE transactions;
