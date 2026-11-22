// ==========================================================
// Portfolio 4: NoSQL Document Model (MongoDB)
// Use Case: CoreTrust Digital Bank Fraud & Audit Telemetry
// ==========================================================

use("coretrust_audit");

// Clean collection for repeatable execution
db.transaction_telemetry.drop();

// 1. Insert semi-structured fraud & device audit logs
// Notice how nested attributes vary organically per channel (Mobile App vs Web vs USSD)
db.transaction_telemetry.insertMany([
  {
    transaction_ref: "TRX-ACID-COMMIT-01",
    customer_id: 1,
    account_number: "0123456789",
    channel: "MOBILE_APP",
    amount_ngn: 30000.00,
    timestamp: ISODate("2026-11-22T09:15:00Z"),
    device_context: {
      device_id: "dev-iphone16-9981",
      os: "iOS 19.1",
      app_version: "5.4.0",
      ip_address: "102.89.45.112",
      geolocation: {
        city: "Abuja",
        country: "NG",
        coordinates: [7.4951, 9.0579]
      }
    },
    fraud_engine: {
      risk_score: 14,
      decision: "APPROVED",
      triggered_rules: [],
      latency_ms: 18
    }
  },
  {
    transaction_ref: "TRX-20261122-0088",
    customer_id: 2,
    account_number: "0987654321",
    channel: "WEB_PORTAL",
    amount_ngn: 485000.00,
    timestamp: ISODate("2026-11-22T09:42:10Z"),
    device_context: {
      browser: "Chrome 131.0",
      os: "Windows 11",
      ip_address: "185.220.101.4",
      is_vpn_or_tor: true,
      geolocation: {
        city: "Amsterdam",
        country: "NL"
      }
    },
    fraud_engine: {
      risk_score: 89,
      decision: "BLOCKED",
      triggered_rules: [
        "IMPOSSIBLE_TRAVEL_DETECTED",
        "TOR_EXIT_NODE_IP",
        "AMOUNT_NEAR_TIER2_LIMIT"
      ],
      latency_ms: 24
    }
  },
  {
    transaction_ref: "TRX-20261122-0091",
    customer_id: 2,
    account_number: "0987654321",
    channel: "MOBILE_APP",
    amount_ngn: 195000.00,
    timestamp: ISODate("2026-11-22T10:05:33Z"),
    device_context: {
      device_id: "dev-pixel9-4410",
      os: "Android 16",
      app_version: "5.4.0",
      ip_address: "197.210.76.88",
      geolocation: {
        city: "Lagos",
        country: "NG"
      }
    },
    fraud_engine: {
      risk_score: 76,
      decision: "CHALLENGE_2FA",
      triggered_rules: ["NEW_DEVICE_FINGERPRINT", "VELOCITY_3_TX_IN_1HR"],
      latency_ms: 21
    }
  },
  {
    transaction_ref: "TRX-20261122-0104",
    customer_id: 3,
    account_number: "0555666777",
    channel: "USSD",
    amount_ngn: 5000.00,
    timestamp: ISODate("2026-11-22T10:12:00Z"),
    ussd_context: {
      telco: "MTN-NG",
      session_hops: 4,
      cell_tower_id: "ABJ-GARKI-042"
    },
    fraud_engine: {
      risk_score: 8,
      decision: "APPROVED",
      triggered_rules: [],
      latency_ms: 9
    }
  }
]);

// 2. Create Compound Index for fast Compliance Risk Queries
db.transaction_telemetry.createIndex(
  { "fraud_engine.decision": 1, "fraud_engine.risk_score": -1 }
);

// 3. Query 1: Retrieve all BLOCKED or 2FA-challenged high-risk events (risk_score >= 70)
print("=== HIGH RISK TELEMETRY EVENTS ===");
printjson(
  db.transaction_telemetry.find(
    { "fraud_engine.risk_score": { $gte: 70 } },
    { _id: 0, transaction_ref: 1, customer_id: 1, channel: 1, amount_ngn: 1, "fraud_engine.decision": 1, "fraud_engine.triggered_rules": 1 }
  ).sort({ "fraud_engine.risk_score": -1 }).toArray()
);

// 4. Query 2: Aggregation Pipeline — Summarize transaction count & total value by Fraud Decision
print("=== FRAUD DECISION SUMMARY ===");
printjson(
  db.transaction_telemetry.aggregate([
    {
      $group: {
        _id: "$fraud_engine.decision",
        total_events: { $sum: 1 },
        total_amount_ngn: { $sum: "$amount_ngn" },
        avg_risk_score: { $avg: "$fraud_engine.risk_score" }
      }
    },
    { $sort: { avg_risk_score: -1 } }
  ]).toArray()
);
