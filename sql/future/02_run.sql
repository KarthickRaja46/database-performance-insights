USE performance_monitoring;

-- ============================================================================
-- MYSQL CLI / MYSQL SHELL RUNNER (FUTURE LAYER)
-- ============================================================================
-- This file uses SOURCE, a mysql-client command (not server-side SQL).

-- Step 1: Core setup.
SOURCE sql/00_schema.sql;

-- Step 2: Optional reset and reload.
SOURCE sql/07_reset.sql;

-- Step 3: Reusable view layer.
SOURCE sql/03_views.sql;

-- Step 4: KPI and dashboard output.
SOURCE sql/02_kpi.sql;
SOURCE sql/05_dashboard.sql;

-- Step 5 (optional): Operations checks.
SOURCE sql/future/00_ops.sql;
