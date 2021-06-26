-- Show databases overview
SELECT
       datname,
       numbackends,
       xact_rollback / nullif((xact_commit + xact_rollback),0) * 100 AS rollback_ratio,
       round(((100 * tup_inserted + tup_updated + tup_deleted) / (tup_inserted + tup_updated + tup_deleted + tup_returned + tup_fetched)::numeric),3) AS write_ratio,
       round(100 * blks_hit / (blks_hit + blks_read), 3) AS cache_hit_ratio,
       pg_size_pretty(pg_database_size(datname)) AS size,
       clock_timestamp() - stats_reset AS stats_age
FROM pg_stat_database
WHERE (tup_inserted + tup_updated + tup_deleted + tup_returned + tup_fetched) > 0
ORDER BY xact_commit DESC;