-- Show replication activity: connected standby and replication lag in bytes/seconds.
-- Min. required version: Postgres 10
SELECT
       client_addr,
       usename,
       application_name,
       state,
       sync_state,
       pg_size_pretty(pg_current_wal_lsn() - sent_lsn) AS pending,
       pg_size_pretty(sent_lsn - write_lsn) as write_lag_bytes,
       pg_size_pretty(write_lsn - flush_lsn) as flush_lag_bytes,
       pg_size_pretty(flush_lsn - replay_lsn) as replay_lag_bytes,
       pg_size_pretty(pg_current_wal_lsn() - replay_lsn) as total_lag_bytes,
       write_lag,
       flush_lag,
       replay_lag
FROM pg_stat_replication
ORDER BY pg_current_wal_lsn() - replay_lsn DESC;