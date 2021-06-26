-- Show progress of ANALYZE commands.
-- Min. required version: Postgres 13
SELECT
       a.pid,
       date_trunc('seconds', clock_timestamp() - xact_start)::text AS xact_age,
       p.datname,
       p.relid::regclass AS "table",
       a.state,
       coalesce((a.wait_event_type ||'.'|| a.wait_event), 'f') AS waiting,
       p.phase,
       pg_size_pretty(p.sample_blks_total * (SELECT current_setting('block_size')::int)) AS sample_size,
       round(100 * p.sample_blks_scanned / greatest(p.sample_blks_total,1), 2)::text AS scanned_ratio,
       p.ext_stats_total ||'/'|| p.ext_stats_computed::text AS "ext_total/done",
       p.child_tables_total||'/'|| round(100 * p.child_tables_done / greatest(p.child_tables_total, 1), 2)::text AS "child_total/done,%",
       current_child_table_relid::regclass AS child_in_progress
FROM pg_stat_progress_analyze p
    INNER JOIN pg_stat_activity a ON p.pid = a.pid
ORDER BY clock_timestamp() - a.xact_start DESC