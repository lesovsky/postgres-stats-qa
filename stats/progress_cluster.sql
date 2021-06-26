-- Show progress of CLUSTER and VACUUM FULL commands.
-- Min. required version: Postgres 12
SELECT
       a.pid,
       date_trunc('seconds', clock_timestamp() - xact_start)::text AS xact_age,
       p.datname,
       p.relid::regclass AS relation,
       p.cluster_index_relid::regclass AS index,
       a.state,
       coalesce((a.wait_event_type ||'.'|| a.wait_event), 'f') AS waiting,
       p.phase,
       pg_size_pretty(p.heap_blks_total * (SELECT current_setting('block_size')::int)) AS size_total,
       round(100 * p.heap_blks_scanned / greatest(p.heap_blks_total,1), 2)::text AS heap_scanned_ratio,
       coalesce(p.heap_tuples_scanned, 0) AS tuples_scanned,
       coalesce(p.heap_tuples_written, 0) AS tuples_written,
       a.query
FROM pg_stat_progress_cluster p
    INNER JOIN pg_stat_activity a ON p.pid = a.pid
ORDER BY clock_timestamp() - a.xact_start DESC