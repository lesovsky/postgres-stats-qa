-- Show progress of running basebackup operations.
-- Min. required version: Postgres 13
SELECT
       a.pid,
       a.client_addr AS started_from,
       to_char(backend_start, 'YYYY-MM-DD HH24:MI:SS') AS started_at,
       date_trunc('seconds', clock_timestamp() - backend_start)::text AS duration,
       a.state,
       coalesce((a.wait_event_type ||'.'|| a.wait_event), 'f') AS waiting,
       p.phase,
       pg_size_pretty(p.backup_total) AS size_total,
       pg_size_pretty(p.backup_streamed) AS streamed,
       round(100 * p.backup_streamed / greatest(p.backup_total,1), 2)::text AS streamed_ratio,
       p.tablespaces_total||'/'|| p.tablespaces_streamed::text AS "tablespaces_total/streamed"
FROM pg_stat_progress_basebackup p
    INNER JOIN pg_stat_activity a ON p.pid = a.pid
ORDER BY clock_timestamp() - a.xact_start DESC