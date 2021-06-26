# SQL queries for PostgreSQL activity statistics. 

Here is you can find useful SQL queries for observing PostgreSQL.

## Content

### Activity
- [summary activity](stats/activity_summary.sql) - summary activity grouped by connected client address, user and database (pg_stat_activity).
- [activity](stats/activity.sql) - show activity longer than 100ms (pg_stat_activity).
- [functions activity](stats/functions_activity.sql) - show functions execution statistics (pg_stat_user_functions).
- [SSL connected clients](stats/ssl_connected_clients.sql) - connected clients and used SSL settings (pg_stat_ssl, pg_stat_activity).

### Locks and Waitings
- [blocked pids](stats/blocked_activity_brief.sql) - brief information about blocked PIDs (pg_stat_activity, pg_blocking_pids).
- [locks tree](stats/locktree.sql) - show blocked and blocking activity in a tree format (pg_locks, pg_stat_activity).
- [locking activity](stats/locking_activity.sql) - show blocked and blocking activity in row format (pg_locks, pg_stat_activity).

### Progress
- [progress of vacuum](stats/progress_vacuum.sql) - show progress of vacuum commands (pg_stat_progress_vacuum, pg_stat_activity).
- [progress of analyze](stats/progress_analyze.sql) - show progress of ANALYZE commands (pg_stat_progress_analyze, pg_stat_activity).
- [progress of CREATE INDEX](stats/progress_create_index.sql) - show progress of CREATE INDEX commands (pg_stat_progress_create_index, pg_stat_activity).
- [progress of CLUSTER and VACUUM FULL](stats/progress_cluster.sql) - show progress of CLUSTER and VACUUM FULL commands (pg_stat_progress_cluster, pg_stat_activity).
- [progress of base backups](stats/progress_basebackup.sql) - show progress of running basebackup commands (pg_stat_progress_basebackup, pg_stat_activity).
- [progress of COPY](stats/progress_copy.sql) - show progress of COPY commands (pg_stat_progress_copy, pg_stat_activity).

### Replication
- [replication activity](stats/replication_activity.sql) - show connected standbys activity and replication lag (pg_stat_replication).
- [replication slots activity](stats/replication_slots_activity.sql) - show activity in replication slots (pg_replication_slots, pg_stat_replication).

### WAL
- [acrhiver activity](stats/archiver_activity.sql) - show WAL archiver activity (pg_stat_archiver).

### Background services
- [bgwriter/checkpointer summary](stats/bgwriter_summary.sql) - show summary statistics about background writer and checkpointer (pg_stat_bgwriter).
- [tables need vacuum](stats/show_autovacuum_needed.sql) - show tables which have to be vacuumed or analyzed (pg_class, pg_stat_user_tables).

### Sizes
- [top tables by size](stats/top_tables_by_size.sql) - show top 20 tables by size (pg_class, pg_*_size, etc...).
- [pg_catalog size](stats/pg_catalog_size.sql) - show top 10 tables by size from pg_catalog (pg_stat_sys_tables, pg_total_relation_size).

### Databases
- [databases overview](stats/databases_common.sql) - show databases overview: rollback ratio, cache hit ratio, etc... (pg_stat_databases).
- [cache hit ratio](stats/cache_hit_ratio.sql) - show overall cache hit ratio (pg_stat_database).

