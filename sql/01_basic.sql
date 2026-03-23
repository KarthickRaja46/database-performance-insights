USE performance_monitoring;

-- 1) Total requests
SELECT COUNT(*) AS total_requests
FROM vw_system_logs_clean;

-- 2) Average latency (seconds)
SELECT ROUND(AVG(exec_sec), 3) AS avg_latency_sec
FROM vw_system_logs_clean;

-- 3) Total error requests
SELECT COUNT(*) AS error_requests
FROM vw_system_logs_clean
WHERE is_error = 1;