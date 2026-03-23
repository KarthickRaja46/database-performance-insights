USE performance_monitoring;

--Create tables and objects.
SOURCE sql/00_schema.sql;

--reset and reload sample data.
SOURCE sql/07_reset.sql;

--Build reusable view layer.
SOURCE sql/03_views.sql;

--Run KPI and dashboard outputs.
SOURCE sql/02_kpi.sql;
SOURCE sql/05_dashboard.sql;

--Operations checks and alerts.
SOURCE sql/future/00_ops.sql;
