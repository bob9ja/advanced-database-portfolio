# MIT 8103: Advanced Database Systems Portfolio

## Case Study: CoreTrust Digital Bank (Retail Banking & Fintech Platform)

* **Organisation Name:** CoreTrust Digital Bank Ltd. (Simulated Retail Banking System)
* **Nature of Business/System:** A modern retail banking and instant payment platform supporting customer onboarding, multi-tier KYC verification, savings/current accounts, internal/inter-bank fund transfers, and double-entry ledger auditing.
* **Database Users:** 
  * Retail Customers (via mobile/web banking interfaces)
  * Bank Tellers & Customer Support Officers
  * Compliance & Audit Officers
  * Database Administrators (DBAs)
* **Major Data Stored:** Customer profiles, KYC compliance tiers, bank accounts, double-entry ledger postings, transaction records, and unstructured device/fraud audit logs.
* **Key Operations Supported:**
  1. Customer registration and KYC tier assignment
  2. Opening multi-currency/multi-type accounts (Savings, Current)
  3. Atomic peer-to-peer (P2P) fund transfers with double-entry ledger recording
  4. Failed transaction reversals and balance reconciliation
  5. High-speed transaction history filtering and fraud telemetry logging

## Repository Structure
* `portfolio-1-database-design/` — ERD, relational schema, constraints, normalisation analysis, and seed script.
* `portfolio-2-query-optimisation/` — Complex SQL queries, `EXPLAIN ANALYZE` execution plans, indexing strategy, and performance benchmarks.
* `portfolio-3-transactions-concurrency/` — ACID transactions, `COMMIT`/`ROLLBACK` tests, isolation levels, and row-level locking demonstrations.
* `portfolio-4-nosql/` — MongoDB document data model for fraud/audit telemetry and aggregation queries.
* `portfolio-5-distributed-cloud/` — Primary-replica Docker setup, sharding strategy, and CAP theorem analysis.
