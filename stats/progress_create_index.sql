-- Show progress of CREATE INDEX commands.
-- Min. required version: Postgres 12
SELECT
       a.pid,
       date_trunc('seconds', clock_timestamp() - xact_start)::text AS xact_age,
       p.datname,
       p.relid::regclass AS relation,
       p.index_relid::regclass AS index,
       a.state,
       coalesce((a.wait_event_type ||'.'|| a.wait_event), 'f') AS waiting,
       p.phase,
       current_locker_pid AS locker_pid,
       lockers_total ||'/'|| lockers_done AS lockers,
       pg_size_pretty(p.blocks_total * (SELECT current_setting('block_size')::int)) AS size_total,
       round(100 * p.blocks_done / greatest(p.blocks_total, 1), 2)::text AS "size_done,%",
       p.tuples_total,
       round(100 * p.tuples_done / greatest(p.tuples_total, 1), 2)::text AS "tuples_done,%",
       p.partitions_total,
       round(100 * p.partitions_done / greatest(p.partitions_total, 1), 2)::text AS "parts_done,%",
       a.query
FROM pg_stat_progress_create_index p
    INNER JOIN pg_stat_activity a ON p.pid = a.pid
ORDER BY clock_timestamp() - a.xact_start DESC