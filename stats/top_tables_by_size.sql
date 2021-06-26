-- Show top 20 tables by size.
select
        coalesce(t.spcname, 'pg_default') as tablespace,
        n.nspname ||'.'||c.relname as "table",
        (select count(*) from pg_index i where i.indrelid=c.oid) AS index_count,
        pg_size_pretty(pg_relation_size(c.oid, 'main')) AS main_size,
        pg_size_pretty(pg_relation_size(c.oid, 'fsm')) AS fsm_size,
        pg_size_pretty(pg_relation_size(c.oid, 'vm')) AS vm_size,
        pg_size_pretty(pg_relation_size(c.oid, 'init')) AS init_size,
        pg_size_pretty(pg_indexes_size(c.oid)) AS indexes_size,
        pg_size_pretty(pg_relation_size(c.reltoastrelid)) AS toast_size,
        pg_size_pretty(pg_total_relation_size(c.oid)) AS total_size
FROM pg_class c
JOIN pg_namespace n ON c.relnamespace = n.oid
    LEFT JOIN pg_tablespace t ON c.reltablespace = t.oid
WHERE c.relkind in ('r', 'm') AND NOT EXISTS (SELECT 1 FROM pg_locks WHERE relation = c.oid AND mode = 'AccessExclusiveLock' AND granted)
ORDER BY pg_total_relation_size(c.oid) DESC LIMIT 20;