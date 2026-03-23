USE performance_monitoring;

-- =============================================================================
-- INTERMEDIATE PROOF QUERIES (EASY TO PRESENT)
-- =============================================================================

-- -----------------------------------------------------------------------------
-- A) PERFORMANCE CHECKS
-- Goal: show speed and load behavior in simple terms.
-- -----------------------------------------------------------------------------

-- A1. Daily traffic and average latency for the last 7 days.
SELECT
    DATE(`timestamp`) AS request_date,
    COUNT(*) AS total_requests,
    ROUND(AVG(execution_time) / 1000.0, 3) AS avg_latency_sec
FROM system_logs
WHERE `timestamp` >= NOW() - INTERVAL 7 DAY
GROUP BY DATE(`timestamp`)
ORDER BY request_date;

-- A2. Top 10 busy endpoints with average and max latency.
SELECT
    endpoint,
    COUNT(*) AS total_requests,
    ROUND(AVG(execution_time) / 1000.0, 3) AS avg_latency_sec,
    ROUND(MAX(execution_time) / 1000.0, 3) AS max_latency_sec
FROM system_logs
GROUP BY endpoint
ORDER BY total_requests DESC
LIMIT 10;

-- A3. Hourly traffic pattern for quick capacity planning.
SELECT
    HOUR(`timestamp`) AS hour_of_day,
    COUNT(*) AS total_requests,
    ROUND(AVG(execution_time) / 1000.0, 3) AS avg_latency_sec
FROM system_logs
GROUP BY HOUR(`timestamp`)
ORDER BY total_requests DESC, hour_of_day;

-- -----------------------------------------------------------------------------
-- B) DATA QUALITY CHECKS
-- Rules:
-- 1) status IN (200, 404, 500)
-- 2) execution_time > 0
-- 3) endpoint is not null/blank
-- -----------------------------------------------------------------------------

-- B1. Rule-violation summary in trusted table.
SELECT
    COUNT(*) AS total_rows_checked,
    SUM(CASE WHEN status NOT IN (200, 404, 500) THEN 1 ELSE 0 END) AS invalid_status_rows,
    SUM(CASE WHEN execution_time <= 0 THEN 1 ELSE 0 END) AS invalid_execution_time_rows,
    SUM(CASE WHEN endpoint IS NULL OR TRIM(endpoint) = '' THEN 1 ELSE 0 END) AS invalid_endpoint_rows
FROM system_logs;

-- B2. Rejected reason distribution.
SELECT
    reason,
    COUNT(*) AS rejected_count,
    ROUND(COUNT(*) * 100.0 / NULLIF((SELECT COUNT(*) FROM rejected_logs), 0), 2) AS rejected_share_pct
FROM rejected_logs
GROUP BY reason
ORDER BY rejected_count DESC;

-- B3. ETL rejected rows vs rejected_logs count.
SELECT
    COALESCE(SUM(rejected_rows), 0) AS etl_reported_rejected_rows,
    (SELECT COUNT(*) FROM rejected_logs) AS rejected_logs_rows,
    COALESCE(SUM(rejected_rows), 0) - (SELECT COUNT(*) FROM rejected_logs) AS rejection_count_gap
FROM etl_metrics;

-- -----------------------------------------------------------------------------
-- C) BUSINESS IMPACT
-- Goal: connect performance issues to user impact.
-- -----------------------------------------------------------------------------

-- C1. Slow endpoints.
SELECT
    endpoint,
    COUNT(*) AS total_requests,
    ROUND(AVG(exec_sec), 3) AS avg_latency_sec,
    ROUND(MAX(exec_sec), 3) AS max_latency_sec,
    ROUND(AVG(is_sla_breach) * 100, 2) AS sla_breach_rate_pct
FROM vw_system_logs_clean
GROUP BY endpoint
HAVING COUNT(*) >= 10
ORDER BY avg_latency_sec DESC, sla_breach_rate_pct DESC
LIMIT 10;

-- C2. High-error endpoints.
SELECT
    endpoint,
    COUNT(*) AS total_requests,
    ROUND(AVG(is_error) * 100, 2) AS error_rate_pct,
    ROUND(AVG(exec_sec), 3) AS avg_latency_sec
FROM vw_system_logs_clean
GROUP BY endpoint
HAVING COUNT(*) >= 10
ORDER BY error_rate_pct DESC, total_requests DESC
LIMIT 10;

-- C3. Minutes with heavy load (simple threshold).
SELECT
    minute_bucket,
    COUNT(*) AS requests_per_minute,
    ROUND(AVG(exec_sec), 3) AS avg_latency_sec,
    ROUND(AVG(is_error) * 100, 2) AS error_rate_pct
FROM vw_system_logs_clean
GROUP BY minute_bucket
HAVING COUNT(*) >= 20
ORDER BY minute_bucket DESC
LIMIT 120;
