# Portfolio 1: Database Design and Modelling

## 1. Entity-Relationship Overview
* **KYC_TIERS (1) $\longrightarrow$ (Many) CUSTOMERS:** Each customer belongs to a single regulatory KYC tier that dictates their transaction limits.
* **CUSTOMERS (1) $\longrightarrow$ (Many) ACCOUNTS:** A single customer can hold multiple accounts (e.g., Savings and Current).
* **ACCOUNTS (1) $\longrightarrow$ (Many) TRANSACTIONS:** Accounts act as either senders or receivers across many transactions.
* **TRANSACTIONS (1) $\longrightarrow$ (Many) LEDGER_ENTRIES:** Implements double-entry accounting; every completed transfer generates two immutable ledger records (one `DEBIT` and one `CREDIT`).

## 2. Normalisation Analysis (1NF to 3NF)
* **First Normal Form (1NF):** All columns contain atomic values (e.g., `first_name` and `last_name` are separated rather than stored as a composite `full_name`), and every table has a primary key (`SERIAL` or `UUID`).
* **Second Normal Form (2NF):** All non-key attributes are fully functionally dependent on their table's primary key. Account balances and statuses are separated from `customers` so they depend strictly on `account_id`.
* **Third Normal Form (3NF):** Transitive dependencies are eliminated. Because `daily_transfer_limit` and `max_balance_limit` depend on a customer's `tier_id` rather than `customer_id`, tier rules were extracted into `kyc_tiers`. Storing limits directly in `customers` would cause update anomalies whenever regulatory limits change.

## 3. Integrity & Business Constraints
* **Domain Constraints:** `CHECK (balance >= 0.00)` prevents account overdrafts at the database engine level; `CHECK (amount > 0.00)` blocks zero or negative transfers.
* **Referential Integrity:** `ON DELETE RESTRICT` on `accounts` and `ledger_entries` guarantees financial records cannot be accidentally deleted while linked to active customers or transactions.
* **Self-Transfer Prevention:** `chk_different_accounts` prevents an account from transferring funds to itself.
