-- Show progress of COPY commands.
-- Min. required version: Postgres 14
SELECT
       a.pid,
       date_trunc('seconds', clock_timestamp() - xact_start)::text AS xact_age,
       p.datname,
       p.relid::regclass AS relation,
       a.state,
       coalesce((a.wait_event_type ||'.'|| a.wait_event), 'f') AS waiting,
       p.command,
       p.type,
       pg_size_pretty(pg_relation_size(p.relid)) AS size_total,
       pg_size_pretty(p.bytes_total) AS source_total,
       pg_size_pretty(p.bytes_processed) AS processed,
       round(100 * p.bytes_processed / nullif(p.bytes_total, 0), 2)::text AS processed_ratio,
       p.tuples_processed,
       p.tuples_excluded
FROM pg_stat_progress_copy p
    INNER JOIN pg_stat_activity a ON p.pid = a.pid
WHERE NOT EXISTS (SELECT 1 FROM pg_locks WHERE relation = p.relid AND mode = 'AccessExclusiveLock' AND granted)
ORDER BY clock_timestamp() - a.xact_start DESC