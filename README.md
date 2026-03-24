# 🚀 Database Performance Monitoring & Analytics System

🚀 End-to-end data pipeline to monitor system performance, ensure data quality, and generate actionable insights.

**Real-world ETL + SQL analytics system to monitor database performance, detect SLA breaches, and optimize system health.**

📌 Built to simulate real-world production monitoring systems used in backend and API environments
📌 Focus: Data Quality • Performance Analytics • System Reliability

---

## 🔹 Executive Summary

Modern applications generate massive logs that are often noisy and inconsistent. Poor data quality leads to incorrect decisions, while hidden performance issues impact system reliability.

👉 This project demonstrates how to **Generate → Validate → Store → Analyze → Monitor** logs using a complete end-to-end pipeline.

---

## 📌 Key Highlights

* End-to-end ETL pipeline (Python + SQL)
* Real-time log simulation with failures & latency
* Data validation with rejected data handling
* SLA, P95, P99 performance tracking
* 40+ SQL queries (basic → advanced → diagnostics)
* Power BI dashboard for system monitoring

---

## 🎯 Problem Statement

* Raw logs are **noisy, inconsistent, and unreliable**
* Poor data quality leads to **incorrect analytics and decisions**
* Performance issues remain hidden without **structured monitoring**

---

## 💡 Solution Overview

* Simulated logs with realistic latency, retries, and failures
* ETL pipeline to validate and clean incoming data
* Invalid records stored separately for debugging and traceability
* SQL analytics layer for KPI computation and diagnostics
* Power BI dashboard to visualize system performance

---

## 🔄 System Architecture

```id="arch1"
Log Simulator (Python)
        ↓
Raw Logs (CSV Buffer)
        ↓
ETL Validation Layer
   ↙                         ↘
Valid Data                  Rejected Data
(system_logs)              (rejected_logs)
   ↓                         ↓
Cleaned CSV                Rejected CSV
        ↘                   ↙
           ETL Metrics Tracking
                    ↓
        SQL Analytics Layer
 (Basic → KPI → Advanced → Diagnostics)
                    ↓
           Power BI Dashboard
```

---

## 🧱 Core Components

**1. Log Simulator (Python)**
Generates realistic system logs with latency, errors, and retries

**2. ETL Pipeline**
Validates data, separates valid and invalid records, and tracks pipeline metrics

**3. SQL Analytics Layer**
Implements KPI calculations, advanced diagnostics, and optimized queries

**4. Dashboard Layer (Power BI)**
Visualizes SLA compliance, latency trends, error rates, and system health

---

## 📸 Dashboard Preview

![Dashboard](dashboard/powerbi_screenshot.png)

**Key Insights:**

* SLA breach trends
* High latency endpoints
* Error rate spikes
* Overall system health score

---

## 📊 Sample Insights

* Identified high-latency endpoints impacting SLA compliance
* Detected error spikes during peak traffic periods
* Improved performance using SQL query optimization

---

## 📈 Results

* Processed **20K+** simulated system log records
* Achieved high data quality through ETL validation
* Identified performance bottlenecks affecting SLA
* Improved query performance through optimization techniques

---

## 🗂️ Project Structure

```id="struct1"
SQL_PROJECT/
│
├── data/
│   ├── raw/
│   └── processed/
├── sql/
├── scripts/
├── dashboard/
```

---

## 🧾 Database Design

| Table         | Purpose                  |
| ------------- | ------------------------ |
| system_logs   | Clean data for analytics |
| rejected_logs | Invalid data storage     |
| etl_metrics   | Pipeline tracking        |
| alerts        | Detected anomalies       |

---

## ⚙️ Tech Stack

![Python](https://img.shields.io/badge/Python-3.9-blue)
![SQL](https://img.shields.io/badge/SQL-MySQL-orange)
![PowerBI](https://img.shields.io/badge/PowerBI-Dashboard-yellow)

---

## ⚡ Quick Start

1. Setup database:

   ```sql
   source sql/00_schema_setup.sql;
   ```

2. Run log simulator:

   ```bash
   python scripts/log_simulator.py
   ```

3. Execute analytics:
   Run SQL scripts from the `sql/` folder in order

4. Open dashboard:
   Load `dashboard/performance_monitoring.pbix` in Power BI

---

## 🧮 Key Metrics

| Metric       | Purpose               |
| ------------ | --------------------- |
| Success Rate | System reliability    |
| Error Rate   | Failure tracking      |
| Avg Latency  | Performance indicator |
| SLA Breach   | Threshold violation   |
| Health Score | Overall system status |

---

## 🌍 Real-World Use Cases

* API performance monitoring
* Backend system health tracking
* Production log analytics
* Incident detection systems

👉 Similar to monitoring systems used in companies like Amazon, Netflix, and Google

---

## 🚀 Business Impact

* Prevents bad data from corrupting analytics
* Enables real-time performance monitoring
* Detects system bottlenecks early
* Improves system reliability and decision-making

---

## 🔮 Future Enhancements

* Kafka-based real-time streaming
* API-based ingestion layer
* Automated alerts (Email/Slack)
* Advanced query optimization engine

---

## 👨‍💻 Author

**Karthick Raja** ||
Data Analyst specializing in SQL, ETL pipelines, and performance analytics

---

## ⭐ Final Takeaway

This project demonstrates a **complete data pipeline**, not just SQL queries.

👉 Covers:

* Data generation
* Data cleaning
* Data storage
* Data analysis
* Performance monitoring

🔥 Shows how raw data is transformed into actionable insights through a structured system.
