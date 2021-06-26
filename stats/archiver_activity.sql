-- Show WAL archiver activity.
SELECT
       clock_timestamp() AS now,
       archived_count,
       clock_timestamp() - last_archived_time AS since_last_success,
       failed_count,
       clock_timestamp() - last_failed_time AS since_last_fail,
       clock_timestamp() - stats_reset AS stats_age
FROM pg_stat_archiver