USE performance_monitoring;

-- 1) Latency buckets 
SELECT
    CASE
        WHEN exec_sec <= 0.100 THEN 'Excellent'
        WHEN exec_sec <= 0.300 THEN 'Good'
        WHEN exec_sec <= 0.700 THEN 'Moderate'
        ELSE 'Slow'
    END AS latency_bucket,
    COUNT(*) AS request_count
FROM vw_system_logs_clean
GROUP BY latency_bucket
ORDER BY request_count DESC;

-- 2) Daily average latency and error rate
SELECT
    request_date,
    COUNT(*) AS total_requests,
    ROUND(AVG(exec_sec), 3) AS avg_latency_sec,
    ROUND(AVG(is_error) * 100, 2) AS error_rate_pct
FROM vw_system_logs_clean
GROUP BY request_date
ORDER BY request_date;

-- 3) Endpoint summary 
SELECT
    endpoint,
    COUNT(*) AS total_requests,
    ROUND(AVG(exec_sec), 3) AS avg_latency_sec,
    ROUND(MAX(exec_sec), 3) AS max_latency_sec,
    ROUND(AVG(is_error) * 100, 2) AS error_rate_pct,
    ROUND(AVG(is_sla_breach) * 100, 2) AS sla_breach_rate_pct
FROM vw_system_logs_clean
GROUP BY endpoint
HAVING COUNT(*) >= 10
ORDER BY total_requests DESC, avg_latency_sec DESC;

-- 4) Simple endpoint risk score 
SELECT
    endpoint,
    COUNT(*) AS total_requests,
    ROUND(AVG(exec_sec), 3) AS avg_latency_sec,
    ROUND(AVG(is_error) * 100, 2) AS error_rate_pct,
    ROUND(AVG(is_sla_breach) * 100, 2) AS sla_breach_rate_pct,
    ROUND(
        (AVG(is_error) * 100 * 0.50) +
        (AVG(is_sla_breach) * 100 * 0.35) +
        (LEAST(AVG(exec_sec) / 0.5, 2) * 100 * 0.15),
    2) AS endpoint_risk_score
FROM vw_system_logs_clean
GROUP BY endpoint
ORDER BY endpoint_risk_score DESC, total_requests DESC;

-- 5) Peak traffic hours
SELECT
    HOUR(`timestamp`) AS hour_of_day,
    COUNT(*) AS total_requests,
    ROUND(AVG(exec_sec), 3) AS avg_latency_sec,
    ROUND(AVG(is_error) * 100, 2) AS error_rate_pct
FROM vw_system_logs_clean
GROUP BY HOUR(`timestamp`)
ORDER BY total_requests DESC, hour_of_day;
