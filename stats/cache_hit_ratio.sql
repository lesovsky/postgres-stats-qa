-- Show overall cache hit ratio.
SELECT round(100 * sum(blks_hit) / sum(blks_hit + blks_read), 3) AS cache_hit_ratio FROM pg_stat_database