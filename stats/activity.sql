-- Show transactional activity longer than 100ms.
-- Min. required version: Postgres 10
SELECT
       pid,
       backend_type,
       client_addr,
       usename,
       datname,
       application_name,
       state,
       wait_event_type ||'.'|| wait_event AS waiting,
       now() - coalesce(xact_start, query_start) AS age,
       query
FROM pg_stat_activity
WHERE (
   (clock_timestamp() - xact_start > '00:00:00.1') OR
   (clock_timestamp() - query_start > '00:00:00.1' AND state = 'idle in transaction (aborted)')
   ) AND pid != pg_backend_pid()
ORDER BY now() - coalesce(xact_start, query_start) DESC;