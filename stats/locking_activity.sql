-- Show blocked and blocking activity. Recommended to use expanded output.
-- Min. required version: Postgres 9.6
SELECT
       COALESCE(l1.relation::regclass::text,l1.locktype) AS locked_item,
       w.wait_event_type AS waiting_ev_type, w.wait_event AS waiting_ev, w.query AS waiting_query,
       l1.mode AS waiting_mode,
       (select now() - xact_start AS waiting_xact_duration FROM pg_stat_activity WHERE pid = w.pid),
       (select now() - query_start AS waiting_query_duration FROM pg_stat_activity WHERE pid = w.pid),
       w.pid AS waiting_pid, w.usename AS waiting_user, w.state AS waiting_state,
       l.wait_event_type AS locking_ev_type, l.wait_event_type AS locking_ev, l.query AS locking_query, l2.mode AS locking_mode,
       (select now() - xact_start AS locking_xact_duration FROM pg_stat_activity WHERE pid = l.pid),
       (select now() - query_start AS locking_query_duration FROM pg_stat_activity WHERE pid = l.pid),
       l.pid AS locking_pid, l.usename AS locking_user, l.state AS locking_state
FROM pg_stat_activity w
JOIN pg_locks l1 ON w.pid = l1.pid AND NOT l1.granted
JOIN pg_locks l2 ON (l1.transactionid = l2.transactionid AND l1.pid != l2.pid)
                        OR (l1.database = l2.database AND l1.relation = l2.relation AND l1.pid != l2.pid)
JOIN pg_stat_activity l ON l2.pid = l.pid
WHERE w.wait_event IS NOT NULL AND w.wait_event_type IS NOT NULL
ORDER BY l.query_start, w.query_start;