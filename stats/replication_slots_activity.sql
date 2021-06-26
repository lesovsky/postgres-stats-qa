-- Show activity of replication slots.
-- Min. required version: Postgres 10
SELECT
       r.client_addr,
       r.usename,
       s.database,
       r.application_name,
       s.slot_name,
       s.plugin,
       s.slot_type,
       s.temporary,
       s.active,
       pg_size_pretty(pg_current_wal_lsn() - s.restart_lsn) AS restart_distance,
       pg_size_pretty(pg_current_wal_lsn() - s.confirmed_flush_lsn) AS pending
FROM pg_replication_slots s
    LEFT JOIN pg_stat_replication r on (s.active_pid = r.pid)
ORDER BY pg_current_wal_lsn() - s.confirmed_flush_lsn DESC