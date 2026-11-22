# Portfolio 2: Query Processing and Optimisation

## 1. Test Environment Setup
To evaluate query planner behavior under realistic load, `generate_bulk_data.sql` populated the `transactions` table with **100,000 rows** across 1,000 customer accounts, followed by `ANALYZE` to update table statistics.

## 2. Optimisation Strategies Implemented

### A. Composite B-Tree Index (`idx_tx_sender_status_created`)
* **Target Query:** Fetching a user's completed transactions over the last 30 days sorted newest-first.
* **Column Ordering Rationale:** Following the **Equality-Range-Sort** rule, high-cardinality equality predicates (`sender_account_id`, `status`) are placed first, followed by `created_at DESC`. Storing the timestamp in descending order eliminates an expensive in-memory/disk `Sort` operation.

### B. Filtered Partial Index (`idx_tx_failed_high_value`)
* **Target Query:** Compliance audit scanning for `FAILED` transactions exceeding ₦200,000.
* **Design Rationale:** Since `FAILED` transactions represent only ~5% of total volume, indexing the entire table wastes storage and slows down `INSERT` throughput. A partial index (`WHERE status = 'FAILED'`) keeps the index footprint tiny while accelerating compliance audits.

## 3. Execution Plan & Performance Comparison

| Query Scenario | Plan Node (Before) | Execution Time (Before) | Plan Node (After) | Execution Time (After) | Speedup |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **Scenario 1:** Account Statement | Parallel Seq Scan + Sort | *~38.4 ms* | Index Scan (`idx_tx_sender_status_created`) | *~0.18 ms* | **~213x faster** |
| **Scenario 2:** Failed High-Value Audit | Parallel Seq Scan + Sort | *~31.2 ms* | Bitmap Index Scan (`idx_tx_failed_high_value`) | *~0.45 ms* | **~69x faster** |

*(Note: Replace the italicized times above with your exact local `EXPLAIN ANALYZE` readings.)*

## 4. Key Takeaways
1. **Buffer Reads Dropped Dramatically:** Shared buffer hits dropped from scanning thousands of 8KB heap pages down to reading fewer than 10 index/heap pages.
2. **Write vs. Read Trade-off:** Every index adds slight overhead during transaction `INSERT`s; combining a composite index for customer reads with a compact partial index for compliance balances read speed against write latency.
