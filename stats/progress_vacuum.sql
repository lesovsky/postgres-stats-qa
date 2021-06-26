-- Show progress of running VACUUM operations.
-- Min. required version: Postgres 9.6
SELECT
       a.pid,
       date_trunc('seconds', clock_timestamp() - xact_start)::text AS xact_age,
       v.datname,
       v.relid::regclass AS "table",
       a.state,
       coalesce((a.wait_event_type ||'.'|| a.wait_event), 'f') AS waiting,
       v.phase,
       pg_size_pretty(v.heap_blks_total * (SELECT current_setting('block_size')::int)) AS size_total,
       round(100 * v.heap_blks_scanned / v.heap_blks_total, 2)::text AS scanned_ratio,
       round(100 * v.heap_blks_vacuumed / v.heap_blks_total, 2)::text AS vacuumed_ratio
FROM pg_stat_progress_vacuum v
    RIGHT JOIN pg_stat_activity a ON v.pid = a.pid
WHERE (a.query ~* '^autovacuum:' OR a.query ~* '^vacuum') AND a.pid != pg_backend_pid()
ORDER BY clock_timestamp() - a.xact_start DESC