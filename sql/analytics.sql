USE performance_monitoring;

-- ============================================================================
-- BASIC METRICS - Simple counts and aggregations
-- ============================================================================

-- Basic: Total Requests
SELECT COUNT(*) AS total_requests
FROM system_logs;

-- Basic: Server Errors
SELECT COUNT(*) AS error_count_500
FROM system_logs
WHERE status = 500;

-- Basic: Request by Status
SELECT
    status,
    COUNT(*) AS request_count
FROM system_logs
GROUP BY status
ORDER BY request_count DESC;

-- Basic: Avg Latency
SELECT ROUND(AVG(execution_time) / 1000, 3) AS avg_execution_time_sec
FROM system_logs;

-- Basic: Success Rate
SELECT
    ROUND((SUM(CASE WHEN status = 200 THEN 1 ELSE 0 END) / NULLIF(COUNT(*), 0)) * 100, 2) AS success_rate_pct
FROM system_logs;

-- Basic: Slow Requests
SELECT COUNT(*) AS slow_request_count_over_1_sec
FROM system_logs
WHERE execution_time > 1000;

-- Basic: Daily Latency
SELECT
    DATE(`timestamp`) AS request_date,
    ROUND(AVG(execution_time) / 1000, 3) AS avg_execution_time_sec
FROM system_logs
GROUP BY request_date
ORDER BY request_date DESC;

-- Basic: Top Endpoints
SELECT
    endpoint,
    COUNT(*) AS request_count
FROM system_logs
GROUP BY endpoint
ORDER BY request_count DESC
LIMIT 10;

-- ============================================================================
-- ADVANCED METRICS - Efficiency scores, benchmarking, distributions
-- ============================================================================

-- Advanced: Latency Buckets
SELECT
    CASE
        WHEN execution_time <= 100 THEN 'EXCELLENT (<=100ms)'
        WHEN execution_time <= 250 THEN 'GOOD (100-250ms)'
        WHEN execution_time <= 500 THEN 'ACCEPTABLE (250-500ms)'
        WHEN execution_time <= 1000 THEN 'SLOW (500ms-1s)'
        ELSE 'CRITICAL (>1s)'
    END AS latency_bucket,
    COUNT(*) AS request_count,
    ROUND(COUNT(*) / NULLIF((SELECT COUNT(*) FROM system_logs), 0) * 100, 2) AS percentage_of_total_pct,
    ROUND(AVG(execution_time) / 1000, 3) AS avg_latency_sec
FROM system_logs
GROUP BY latency_bucket
ORDER BY
    CASE
        WHEN latency_bucket = 'EXCELLENT (<=100ms)' THEN 1
        WHEN latency_bucket = 'GOOD (100-250ms)' THEN 2
        WHEN latency_bucket = 'ACCEPTABLE (250-500ms)' THEN 3
        WHEN latency_bucket = 'SLOW (500ms-1s)' THEN 4
        ELSE 5
    END;

-- Advanced: Latency Summary
SELECT
    endpoint,
    ROUND(AVG(execution_time) / 1000, 3) AS avg_execution_time_sec,
    ROUND(MIN(execution_time) / 1000, 3) AS min_execution_time_sec,
    ROUND(MAX(execution_time) / 1000, 3) AS max_execution_time_sec
FROM system_logs
GROUP BY endpoint
ORDER BY avg_execution_time_sec DESC
LIMIT 10;

-- Advanced: Efficiency Score
SELECT
    endpoint,
    COUNT(*) AS total_requests,
    ROUND(AVG(execution_time) / 1000, 3) AS avg_latency_sec,
    ROUND(SUM(CASE WHEN status = 200 THEN 1 ELSE 0 END) / NULLIF(COUNT(*), 0) * 100, 2) AS success_pct,
    ROUND(
        (
            (SUM(CASE WHEN status = 200 THEN 1 ELSE 0 END) / NULLIF(COUNT(*), 0)) * 40
            + (1 - (SUM(CASE WHEN execution_time > 500 THEN 1 ELSE 0 END) / NULLIF(COUNT(*), 0))) * 35
            + (1 - (STDDEV_POP(execution_time) / NULLIF(AVG(execution_time), 0)) / 10) * 25
        ) * 100,
        2
    ) AS efficiency_score_pct
FROM system_logs
GROUP BY endpoint
ORDER BY efficiency_score_pct DESC;

-- Advanced: Benchmarking
SELECT
    endpoint,
    ROUND(AVG(execution_time) / (SELECT AVG(execution_time) FROM system_logs) * 100, 2) AS latency_vs_avg_pct,
    ROUND(SUM(CASE WHEN status = 200 THEN 1 ELSE 0 END) / NULLIF(COUNT(*), 0) * 100, 2) AS success_rate_pct,
    CASE
        WHEN AVG(execution_time) > (SELECT AVG(execution_time) FROM system_logs) * 1.2 THEN 'SLOWER'
        WHEN AVG(execution_time) < (SELECT AVG(execution_time) FROM system_logs) * 0.8 THEN 'FASTER'
        ELSE 'ALIGNED'
    END AS performance_benchmark
FROM system_logs
GROUP BY endpoint
ORDER BY latency_vs_avg_pct DESC;

-- Advanced: Error Rates
SELECT
    endpoint,
    COUNT(*) AS total_requests,
    ROUND(SUM(CASE WHEN status = 500 THEN 1 ELSE 0 END) / NULLIF(COUNT(*), 0) * 100, 2) AS error_rate_500_pct,
    ROUND(SUM(CASE WHEN status = 404 THEN 1 ELSE 0 END) / NULLIF(COUNT(*), 0) * 100, 2) AS not_found_rate_404_pct
FROM system_logs
GROUP BY endpoint
ORDER BY error_rate_500_pct DESC;

-- Advanced: SLA Breaches
SELECT
    endpoint,
    COUNT(*) AS total_requests,
    ROUND(SUM(CASE WHEN execution_time > 500 THEN 1 ELSE 0 END) / NULLIF(COUNT(*), 0) * 100, 2) AS sla_breach_rate_pct,
    ROUND(AVG(CASE WHEN execution_time > 500 THEN execution_time ELSE NULL END) / 1000, 3) AS avg_breach_latency_sec
FROM system_logs
GROUP BY endpoint
ORDER BY sla_breach_rate_pct DESC;

-- Advanced: ETL Freshness
SELECT
    ROUND(TIMESTAMPDIFF(SECOND, MAX(load_time), NOW()) / 60, 2) AS minutes_since_last_load
FROM etl_metrics;

-- Advanced: Duplicates
SELECT
    endpoint,
    `timestamp`,
    COUNT(*) AS occurrence_count
FROM system_logs
GROUP BY endpoint, `timestamp`
HAVING COUNT(*) > 1
ORDER BY occurrence_count DESC
LIMIT 20;

-- Advanced: Rejected Dist
SELECT
    reason,
    COUNT(*) AS rejected_count,
    ROUND(COUNT(*) / NULLIF((SELECT COUNT(*) FROM rejected_logs), 0) * 100, 2) AS rejected_share_pct
FROM rejected_logs
GROUP BY reason
ORDER BY rejected_count DESC;

-- ============================================================================
-- PRIORITY METRICS - Business-level health scoring and decision-making
-- ============================================================================

-- Priority: Health Score
SELECT
    COUNT(*) AS total_requests,
    ROUND(AVG(execution_time) / 1000, 3) AS avg_latency_sec,
    ROUND(SUM(CASE WHEN status = 500 THEN 1 ELSE 0 END) / NULLIF(COUNT(*), 0) * 100, 2) AS error_rate_pct,
    ROUND(SUM(CASE WHEN execution_time > 500 THEN 1 ELSE 0 END) / NULLIF(COUNT(*), 0) * 100, 2) AS sla_breach_rate_pct,
    ROUND(SUM(CASE WHEN status = 200 THEN 1 ELSE 0 END) / NULLIF(COUNT(*), 0) * 100, 2) AS success_rate_pct,
    ROUND(
        (SUM(CASE WHEN status = 200 THEN 1 ELSE 0 END) / NULLIF(COUNT(*), 0)) * 100,
        2
    ) AS success_contribution_pct,
    ROUND(
        (1 - (SUM(CASE WHEN status = 500 THEN 1 ELSE 0 END) / NULLIF(COUNT(*), 0))) * 100,
        2
    ) AS error_avoidance_contribution_pct,
    ROUND(
        (1 - (SUM(CASE WHEN execution_time > 500 THEN 1 ELSE 0 END) / NULLIF(COUNT(*), 0))) * 100,
        2
    ) AS latency_avoidance_contribution_pct,
    ROUND(
        (
            (SUM(CASE WHEN status = 200 THEN 1 ELSE 0 END) / NULLIF(COUNT(*), 0)) * 50
            + (1 - (SUM(CASE WHEN status = 500 THEN 1 ELSE 0 END) / NULLIF(COUNT(*), 0))) * 30
            + (1 - (SUM(CASE WHEN execution_time > 500 THEN 1 ELSE 0 END) / NULLIF(COUNT(*), 0))) * 20
        ),
        2
    ) AS performance_health_score_pct
FROM system_logs;

-- Priority: Risk Ranking
SELECT
    endpoint,
    COUNT(*) AS total_requests,
    ROUND(SUM(CASE WHEN status = 500 THEN 1 ELSE 0 END) / NULLIF(COUNT(*), 0) * 100, 2) AS failure_rate_pct,
    ROUND(SUM(CASE WHEN execution_time > 500 THEN 1 ELSE 0 END) / NULLIF(COUNT(*), 0) * 100, 2) AS sla_breach_rate_pct,
    ROUND(AVG(execution_time) / 1000, 3) AS avg_latency_sec,
    ROUND(
        (
            (SUM(CASE WHEN status = 500 THEN 1 ELSE 0 END) / NULLIF(COUNT(*), 0)) * 0.5
            + (SUM(CASE WHEN execution_time > 500 THEN 1 ELSE 0 END) / NULLIF(COUNT(*), 0)) * 0.3
            + LEAST(AVG(execution_time) / 5000, 1) * 0.2
        ) * 100,
        2
    ) AS priority_risk_score_pct
FROM system_logs
GROUP BY endpoint
ORDER BY priority_risk_score_pct DESC, failure_rate_pct DESC, total_requests DESC;

-- Priority: Rejected Priority
SELECT
    reason,
    COUNT(*) AS rejected_count,
    ROUND(COUNT(*) / NULLIF((SELECT COUNT(*) FROM rejected_logs), 0) * 100, 2) AS rejected_share_pct,
    CASE
        WHEN COUNT(*) >= 100 THEN 'CRITICAL'
        WHEN COUNT(*) >= 50 THEN 'HIGH'
        WHEN COUNT(*) >= 10 THEN 'MEDIUM'
        ELSE 'LOW'
    END AS rejection_priority
FROM rejected_logs
GROUP BY reason
ORDER BY rejected_count DESC, reason;

-- Priority: Rejected Trend
SELECT
    DATE(created_at) AS rejected_date,
    COUNT(*) AS rejected_count
FROM rejected_logs
GROUP BY rejected_date
ORDER BY rejected_date DESC;

-- Priority: Perfect Health
SELECT
    endpoint,
    COUNT(*) AS total_requests,
    ROUND(SUM(CASE WHEN status = 200 THEN 1 ELSE 0 END) / NULLIF(COUNT(*), 0) * 100, 2) AS success_rate_pct,
    ROUND(SUM(CASE WHEN status = 500 THEN 1 ELSE 0 END) / NULLIF(COUNT(*), 0) * 100, 2) AS error_rate_pct,
    ROUND(SUM(CASE WHEN execution_time > 500 THEN 1 ELSE 0 END) / NULLIF(COUNT(*), 0) * 100, 2) AS sla_breach_rate_pct,
    ROUND(AVG(execution_time) / 1000, 3) AS avg_latency_sec,
    ROUND(
        (
            (SUM(CASE WHEN status = 200 THEN 1 ELSE 0 END) / NULLIF(COUNT(*), 0)) * 50
            + (1 - (SUM(CASE WHEN status = 500 THEN 1 ELSE 0 END) / NULLIF(COUNT(*), 0))) * 30
            + (1 - (SUM(CASE WHEN execution_time > 500 THEN 1 ELSE 0 END) / NULLIF(COUNT(*), 0))) * 20
        ),
        2
    ) AS health_score_pct
FROM system_logs
GROUP BY endpoint
HAVING
    ROUND(SUM(CASE WHEN status = 200 THEN 1 ELSE 0 END) / NULLIF(COUNT(*), 0) * 100, 2) = 100.00
    AND ROUND(SUM(CASE WHEN status = 500 THEN 1 ELSE 0 END) / NULLIF(COUNT(*), 0) * 100, 2) = 0.00
    AND ROUND(SUM(CASE WHEN execution_time > 500 THEN 1 ELSE 0 END) / NULLIF(COUNT(*), 0) * 100, 2) = 0.00
ORDER BY total_requests DESC;

-- Priority: Perfect System
SELECT
    'PERFECT' AS health_status,
    COUNT(*) AS perfect_requests,
    ROUND(COUNT(*) / NULLIF((SELECT COUNT(*) FROM system_logs), 0) * 100, 2) AS perfect_percentage_pct,
    ROUND(SUM(CASE WHEN status = 200 THEN 1 ELSE 0 END) / NULLIF(COUNT(*), 0) * 100, 2) AS success_rate_pct,
    ROUND(SUM(CASE WHEN status = 500 THEN 1 ELSE 0 END) / NULLIF(COUNT(*), 0) * 100, 2) AS error_rate_pct,
    ROUND(SUM(CASE WHEN execution_time > 500 THEN 1 ELSE 0 END) / NULLIF(COUNT(*), 0) * 100, 2) AS sla_breach_rate_pct,
    ROUND(AVG(execution_time) / 1000, 3) AS avg_latency_sec,
    100.00 AS perfect_health_score_pct
FROM system_logs
WHERE status = 200 AND execution_time <= 500;

-- ============================================================================
-- EXPANDED METRICS - Additional needed operational queries
-- ============================================================================

-- Extra: Total Rejected
SELECT COUNT(*) AS total_rejected_count
FROM rejected_logs;

-- Extra: Total Alerts
SELECT COUNT(*) AS total_alert_count
FROM alerts;

-- Extra: Slow Query Ratio
SELECT
    COUNT(*) AS total_requests,
    SUM(CASE WHEN execution_time > 1000 THEN 1 ELSE 0 END) AS slow_request_count,
    ROUND(SUM(CASE WHEN execution_time > 1000 THEN 1 ELSE 0 END) / NULLIF(COUNT(*), 0) * 100, 2) AS slow_request_ratio_pct
FROM system_logs;

-- Extra: P95 Latency
WITH ranked AS (
    SELECT
        execution_time,
        CUME_DIST() OVER (ORDER BY execution_time) AS cume_dist_value
    FROM system_logs
)
SELECT
    ROUND(MIN(CASE WHEN cume_dist_value >= 0.95 THEN execution_time END) / 1000, 3) AS p95_latency_sec
FROM ranked;

-- Extra: P99 Latency
WITH ranked AS (
    SELECT
        execution_time,
        CUME_DIST() OVER (ORDER BY execution_time) AS cume_dist_value
    FROM system_logs
)
SELECT
    ROUND(MIN(CASE WHEN cume_dist_value >= 0.99 THEN execution_time END) / 1000, 3) AS p99_latency_sec
FROM ranked;

-- Extra: Endpoint P95
WITH endpoint_ranked AS (
    SELECT
        endpoint,
        execution_time,
        CUME_DIST() OVER (PARTITION BY endpoint ORDER BY execution_time) AS cume_dist_value
    FROM system_logs
)
SELECT
    endpoint,
    ROUND(MIN(CASE WHEN cume_dist_value >= 0.95 THEN execution_time END) / 1000, 3) AS p95_latency_sec
FROM endpoint_ranked
GROUP BY endpoint
ORDER BY p95_latency_sec DESC
LIMIT 10;

-- Extra: Throughput Per Minute
SELECT
    DATE_FORMAT(`timestamp`, '%Y-%m-%d %H:%i:00') AS minute_bucket,
    COUNT(*) AS request_count
FROM system_logs
GROUP BY minute_bucket
ORDER BY minute_bucket DESC
LIMIT 60;

-- Extra: Hourly Error Rate
SELECT
    HOUR(`timestamp`) AS hour_of_day,
    COUNT(*) AS total_requests,
    SUM(CASE WHEN status = 500 THEN 1 ELSE 0 END) AS error_count_500,
    ROUND(SUM(CASE WHEN status = 500 THEN 1 ELSE 0 END) / NULLIF(COUNT(*), 0) * 100, 2) AS error_rate_pct
FROM system_logs
GROUP BY hour_of_day
ORDER BY hour_of_day;

-- Extra: Daily Status Trend
SELECT
    DATE(`timestamp`) AS request_date,
    status,
    COUNT(*) AS request_count
FROM system_logs
GROUP BY request_date, status
ORDER BY request_date DESC, status;

-- Extra: ETL Run Quality
SELECT
    run_id,
    source_type,
    total_rows,
    inserted_rows,
    rejected_rows,
    ROUND(inserted_rows / NULLIF(total_rows, 0) * 100, 2) AS inserted_ratio_pct,
    ROUND(rejected_rows / NULLIF(total_rows, 0) * 100, 2) AS rejected_ratio_pct,
    load_time
FROM etl_metrics
ORDER BY load_time DESC
LIMIT 20;

-- Extra: Alert Severity Dist
SELECT
    severity,
    COUNT(*) AS alert_count,
    ROUND(COUNT(*) / NULLIF((SELECT COUNT(*) FROM alerts), 0) * 100, 2) AS alert_share_pct
FROM alerts
GROUP BY severity
ORDER BY alert_count DESC;

-- Extra: Top Risky IPs
SELECT
    ip,
    COUNT(*) AS total_requests,
    SUM(CASE WHEN status = 500 THEN 1 ELSE 0 END) AS error_count_500,
    ROUND(SUM(CASE WHEN status = 500 THEN 1 ELSE 0 END) / NULLIF(COUNT(*), 0) * 100, 2) AS error_rate_pct,
    ROUND(SUM(CASE WHEN execution_time > 500 THEN 1 ELSE 0 END) / NULLIF(COUNT(*), 0) * 100, 2) AS sla_breach_rate_pct
FROM system_logs
GROUP BY ip
HAVING COUNT(*) >= 10
ORDER BY error_rate_pct DESC, sla_breach_rate_pct DESC, total_requests DESC
LIMIT 20;

-- Extra: Rejected by Source
SELECT
    source_type,
    COUNT(*) AS rejected_count,
    ROUND(COUNT(*) / NULLIF((SELECT COUNT(*) FROM rejected_logs), 0) * 100, 2) AS rejected_share_pct
FROM rejected_logs
GROUP BY source_type
ORDER BY rejected_count DESC;

-- ============================================================================
-- END OF ANALYTICS QUERIES
-- ============================================================================
