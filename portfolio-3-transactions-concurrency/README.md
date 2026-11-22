# Portfolio 3: Transactions and Concurrency Control

## 1. ACID Properties Implementation (`acid_transactions.sql`)
* **Atomicity:** Transfers wrap four write operations (debit sender, credit receiver, insert transaction header, insert two double-entry ledger rows) inside a single `BEGIN ... COMMIT` block. In Test 2, when debiting an underfunded account triggers `chk_balance_non_negative`, `ROLLBACK` reverts the earlier receiver credit so money is neither created nor lost.
* **Consistency:** Database `CHECK` constraints (`balance >= 0.00`) and double-entry ledger rules guarantee total system funds remain invariant before and after every transaction.
* **Isolation:** Concurrent transfers are isolated using row-level locks (`FOR UPDATE`) so intermediate uncommitted balances are never visible to other sessions.
* **Durability:** Once `COMMIT` succeeds, PostgreSQL flushes the Write-Ahead Log (WAL) to disk, guaranteeing transaction persistence even during power failure.

## 2. Concurrency Anomaly & Control Mechanism (`concurrency_test.sql`)

### Problem: Lost Update / Double-Spend Anomaly
If two withdrawal requests of ₦50,000 hit an account containing ₦70,000 simultaneously without locking, both sessions read `70,000.00`, both deduct `50,000.00`, and the second write overwrites the first—leaving a corrupted balance or causing an illegal overdraft.

### Solution: Pessimistic Row-Level Locking (`SELECT ... FOR UPDATE`)
1. **Session A** executes `SELECT ... FOR UPDATE`, acquiring an exclusive `ROW SHARE / FOR UPDATE` lock on `account_id = 1`.
2. **Session B** attempts `SELECT ... FOR UPDATE` on the same row and is immediately placed in a wait state by PostgreSQL's lock manager (verified via `pg_locks` / terminal block).
3. When **Session A** commits (`balance = 20,000.00`), **Session B** unblocks, reads the updated committed balance (`20,000.00`) rather than stale data, and safely aborts (`ROLLBACK`) when the ₦50,000 withdrawal fails the balance check.

### Deadlock Prevention Strategy
When locking multiple accounts during a transfer (sender and receiver), locks are always acquired in ascending order of `account_id` (`LEAST(sender, receiver)` first) to eliminate circular wait conditions and prevent deadlocks.
