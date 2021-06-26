-- Getting information about connected clients and used SSL settings.
SELECT
       client_addr,
       usename,
       datname,
       count(*)
FROM pg_stat_activity
WHERE datname IS NOT NULL GROUP BY 1, 2, 3 ORDER BY 4 DESC;