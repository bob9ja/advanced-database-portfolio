# Portfolio 4: NoSQL and Advanced Data Models

## 1. Selected NoSQL Model: Document Store (MongoDB)
While CoreTrust Digital Bank relies on PostgreSQL for ACID-compliant account balances and double-entry ledgers, **MongoDB (Document Data Model)** is used to store high-volume **Transaction Fraud & Device Telemetry Logs**.

## 2. Why Document Modelling Fits This Use Case
1. **Polymorphic / Schema-Flexible Payloads:** Banking transactions originate from heterogeneous channels (`MOBILE_APP`, `WEB_PORTAL`, `USSD`). Mobile apps capture GPS coordinates and OS versions, web portals capture browser agents and Tor/VPN flags, and USSD captures telco cell-tower IDs. Storing these in a relational database would require sparse tables with dozens of `NULL` columns or complex EAV (Entity-Attribute-Value) joins.
2. **Embedded Locality (Zero-Join Reads):** All context required by a compliance analyst (`device_context`, `geolocation`, `triggered_rules`) is embedded inside a single BSON document, enabling single-seek read performance during real-time fraud scoring (< 25 ms).
3. **High Write Throughput:** Audit telemetry is append-heavy. MongoDB's document model ingests nested JSON payloads directly from microservices without object-relational impedance mismatch.

## 3. Data Linking Strategy (Polyglot Persistence)
Each MongoDB document stores `transaction_ref` (e.g., `TRX-ACID-COMMIT-01`) and `customer_id`, acting as a logical foreign key back to the PostgreSQL `transactions` and `customers` tables when investigators need to cross-reference financial statements with device forensics.

## 4. Indexing & Aggregation
* **Compound Index:** `{ "fraud_engine.decision": 1, "fraud_engine.risk_score": -1 }` accelerates compliance dashboard filters for `BLOCKED` and `CHALLENGE_2FA` alerts.
* **Aggregation Pipeline:** Groups telemetry documents by `fraud_engine.decision` to compute total blocked exposure (`total_amount_ngn`) and average risk scores in real time.
