-- Show backends which are blocked and blocker PIDs. Output doesn't include extended information about blocker PIDs.
-- Min. required version: Postgres 9.6
SELECT
       pid,
       now() - state_change AS waiting_age,
       array_length(pg_blocking_pids(pid), 1) AS n_blockers,
       pg_blocking_pids(pid) AS blocked_by,
       state, wait_event_type, wait_event
FROM pg_stat_activity
WHERE array_length(pg_blocking_pids(pid), 1) > 0
ORDER BY waiting_age DESC NULLS LAST;