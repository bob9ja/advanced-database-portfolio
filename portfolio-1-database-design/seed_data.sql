-- Insert KYC Tiers
INSERT INTO kyc_tiers (tier_id, tier_name, daily_transfer_limit, max_balance_limit) VALUES
(1, 'Tier 1 - Basic', 50000.00, 300000.00),
(2, 'Tier 2 - Standard', 500000.00, 5000000.00),
(3, 'Tier 3 - Premium', 5000000.00, NULL);

-- Insert Sample Customers
INSERT INTO customers (first_name, last_name, email, phone_number, bvn, tier_id) VALUES
('Amina', 'Bello', 'amina.bello@example.ng', '+2348011112222', '22100000001', 3),
('Chinedu', 'Okafor', 'chinedu.okafor@example.ng', '+2348033334444', '22100000002', 2),
('Tunde', 'Bakare', 'tunde.bakare@example.ng', '+2348055556666', '22100000003', 1);

-- Insert Bank Accounts
INSERT INTO accounts (customer_id, account_number, account_type, currency, balance) VALUES
(1, '0123456789', 'CURRENT', 'NGN', 1250000.00),
(1, '0123456790', 'SAVINGS', 'NGN', 450000.00),
(2, '0987654321', 'SAVINGS', 'NGN', 320000.00),
(3, '0555666777', 'SAVINGS', 'NGN', 45000.00);

-- Insert Sample Completed Transaction + Double-Entry Ledger Rows
WITH new_tx AS (
    INSERT INTO transactions (reference_code, sender_account_id, receiver_account_id, amount, transaction_type, status, narration)
    VALUES ('TRX-20261122-0001', 1, 3, 20000.00, 'TRANSFER', 'COMPLETED', 'Invoice settlement')
    RETURNING transaction_id
)
INSERT INTO ledger_entries (transaction_id, account_id, entry_type, amount, balance_after)
SELECT transaction_id, 1, 'DEBIT', 20000.00, 1250000.00 FROM new_tx
UNION ALL
SELECT transaction_id, 3, 'CREDIT', 20000.00, 320000.00 FROM new_tx;
