# Portfolio 5: Distributed and Cloud Database Architecture

## 1. Cloud & High-Availability Deployment (`docker-compose.yml`)
CoreTrust Digital Bank deploys a **Single-Leader Streaming Replication** topology across availability zones (simulated locally via Docker containers `coretrust-pg-primary` on port `5433` and `coretrust-pg-replica` on port `5434`).
* **Write Routing:** All transactional `INSERT`/`UPDATE` workloads (P2P transfers, deposits, ledger entries) route exclusively to the **Primary Node**.
* **Read Scaling:** Read-heavy workloads (customer account statements, compliance reporting, analytics) route to **Read Replicas**, offloading ~80% of query traffic from the primary ledger.
* **Failover:** If the Primary node fails, automated orchestration promotes the Replica with the lowest replication lag (`replay_lag`) to become the new Primary.

## 2. Horizontal Sharding Strategy
As customer volume scales into tens of millions of accounts, a single primary node hits vertical write I/O limits. CoreTrust partitions core tables horizontally:
* **Shard Key Selection (`customer_id` via Hash Partitioning):** Using consistent hashing on `customer_id` distributes customers, accounts, and transactions evenly across N database shards (e.g., Shard 0–3).
* **Why Hash Sharding Over Range Sharding:** Range sharding by `created_at` (date) creates a severe **write hotspot** on the current month's shard while older shards sit idle. Hash sharding by `customer_id` spreads concurrent writes uniformly across all nodes and ensures a customer's accounts and transactions co-locate on the same shard—avoiding expensive distributed cross-shard joins for statement queries.

## 3. CAP Theorem & Consistency Trade-Offs
Under the **CAP Theorem**, network partitions (**P**) are inevitable in distributed cloud environments, forcing an architectural choice between Consistency (**C**) and Availability (**A**):

| Subsystem | Data Store | CAP Choice | Justification |
| :--- | :--- | :--- | :--- |
| **Core Ledger & Balances** | PostgreSQL Cluster | **CP** (Strong Consistency) | During a network partition, the bank must reject transfers rather than accept writes against stale balances, preventing double-spending and negative balances. |
| **Fraud & Device Telemetry** | MongoDB Replica Set | **AP** (High Availability + Eventual Consistency) | Audit logs and analytics feeds tolerate brief replication lag (`eventual consistency`) so logging never blocks customer-facing payment latency. |
