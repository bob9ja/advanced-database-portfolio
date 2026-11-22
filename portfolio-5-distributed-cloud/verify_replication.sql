-- 1. Run on PRIMARY (localhost:5433) to verify active streaming replication slot
SELECT client_addr, state, sync_state, write_lag, flush_lag, replay_lag
FROM pg_stat_replication;

-- 2. Run on PRIMARY (localhost:5433) to insert a test record
CREATE TABLE IF NOT EXISTS replication_heartbeat (
    id SERIAL PRIMARY KEY,
    node_source VARCHAR(50),
    checked_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
INSERT INTO replication_heartbeat (node_source) VALUES ('Committed on Primary Node');

-- 3. Run on REPLICA (localhost:5434) to verify immediate replication & read-only enforcement
SELECT pg_is_in_recovery(); -- Must return TRUE
SELECT * FROM replication_heartbeat; -- Shows the row replicated from Primary

-- 4. Attempt a write on REPLICA (localhost:5434) — Must fail with "cannot execute INSERT in a read-only transaction"
INSERT INTO replication_heartbeat (node_source) VALUES ('Illegal Write on Replica');
