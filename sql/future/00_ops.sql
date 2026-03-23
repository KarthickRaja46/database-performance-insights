USE performance_monitoring;

-- =============================================================================
-- OPERATIONS CHECKS (INTERMEDIATE AND EASY TO READ)
-- =============================================================================

-- Create alerts table if it does not exist.
CREATE TABLE IF NOT EXISTS alerts (
    alert_id BIGINT AUTO_INCREMENT PRIMARY KEY,
    endpoint VARCHAR(255),
    metric_name VARCHAR(100),
    metric_value DECIMAL(10,2),
    severity VARCHAR(20),
    alert_time TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- -----------------------------------------------------------------------------
-- SYSTEM HEALTH CHECK PROCEDURE
-- Thresholds:
-- 1) error_rate_pct > 5
-- 2) avg_latency_sec > 1
-- 3) sla_breach_rate_pct > 10
-- Time window: last 60 minutes
-- Severity:
-- HIGH: Immediate action required
-- MEDIUM: Monitor closely
-- INFO: Informational
-- -----------------------------------------------------------------------------
DROP PROCEDURE IF EXISTS sp_system_health_check;

DELIMITER $$

CREATE PROCEDURE sp_system_health_check()
BEGIN
    DECLARE v_total_requests BIGINT DEFAULT 0;
    DECLARE v_error_rate_pct DECIMAL(10,2) DEFAULT 0.00;
    DECLARE v_avg_latency_sec DECIMAL(10,3) DEFAULT 0.000;
    DECLARE v_sla_breach_rate_pct DECIMAL(10,2) DEFAULT 0.00;

    SELECT
        COUNT(*) AS total_requests,
        COALESCE(ROUND(AVG(is_error) * 100, 2), 0),
        COALESCE(ROUND(AVG(exec_sec), 3), 0),
        COALESCE(ROUND(AVG(is_sla_breach) * 100, 2), 0)
    INTO
        v_total_requests,
        v_error_rate_pct,
        v_avg_latency_sec,
        v_sla_breach_rate_pct
    FROM vw_system_logs_clean
    WHERE `timestamp` >= NOW() - INTERVAL 60 MINUTE;

    IF v_total_requests = 0 THEN
        INSERT INTO alerts (endpoint, metric_name, metric_value, severity)
        SELECT NULL, 'no_traffic_last_60m', 0, 'INFO'
        WHERE NOT EXISTS (
            SELECT 1
            FROM alerts
            WHERE metric_name = 'no_traffic_last_60m'
              AND alert_time >= NOW() - INTERVAL 10 MINUTE
        );
    ELSE
        IF v_error_rate_pct > 5 THEN
            INSERT INTO alerts (endpoint, metric_name, metric_value, severity)
            SELECT NULL, 'error_rate_pct', v_error_rate_pct, 'HIGH'
            WHERE NOT EXISTS (
                SELECT 1
                FROM alerts
                WHERE metric_name = 'error_rate_pct'
                  AND alert_time >= NOW() - INTERVAL 10 MINUTE
            );
        END IF;

        IF v_avg_latency_sec > 1 THEN
            INSERT INTO alerts (endpoint, metric_name, metric_value, severity)
            SELECT NULL, 'avg_latency_sec', v_avg_latency_sec, 'HIGH'
            WHERE NOT EXISTS (
                SELECT 1
                FROM alerts
                WHERE metric_name = 'avg_latency_sec'
                  AND alert_time >= NOW() - INTERVAL 10 MINUTE
            );
        END IF;

        IF v_sla_breach_rate_pct > 10 THEN
            INSERT INTO alerts (endpoint, metric_name, metric_value, severity)
            SELECT NULL, 'sla_breach_rate_pct', v_sla_breach_rate_pct, 'MEDIUM'
            WHERE NOT EXISTS (
                SELECT 1
                FROM alerts
                WHERE metric_name = 'sla_breach_rate_pct'
                  AND alert_time >= NOW() - INTERVAL 10 MINUTE
            );
        END IF;
    END IF;
END $$

DELIMITER ;

-- Run this manually when needed:
-- CALL sp_system_health_check();

-- -----------------------------------------------------------------------------
-- PIPELINE STATUS CHECK
-- Use this in scheduler jobs (every 5-10 minutes).
-- -----------------------------------------------------------------------------
SELECT
    MAX(load_time) AS last_etl_run_time,
    TIMESTAMPDIFF(MINUTE, MAX(load_time), NOW()) AS etl_delay_minutes,
    CASE
        WHEN MAX(load_time) IS NULL THEN 'NO_RUN_HISTORY'
        WHEN TIMESTAMPDIFF(MINUTE, MAX(load_time), NOW()) <= 15 THEN 'HEALTHY'
        WHEN TIMESTAMPDIFF(MINUTE, MAX(load_time), NOW()) <= 60 THEN 'DELAYED'
        ELSE 'CRITICAL_DELAY'
    END AS pipeline_status
FROM etl_metrics;

-- Optional event scheduler approach:
-- SET GLOBAL event_scheduler = ON;
-- CREATE EVENT IF NOT EXISTS ev_system_health_check
-- ON SCHEDULE EVERY 5 MINUTE
-- DO CALL sp_system_health_check();

-- =============================================================================
-- FLOW SUMMARY
-- Logs -> ETL -> cleaned view -> analytics -> dashboard -> alerts.
-- =============================================================================
