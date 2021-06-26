-- Getting information about connected clients and used SSL settings.
-- Min. required version: Postgres 10
SELECT
    s.pid,
    a.backend_type,
    a.client_addr,
    now() - backend_start as connected,
    a.usename,
    a.datname,
    a.application_name,
    s.ssl,
    s.version,
    s.cipher,
    s.bits
FROM pg_stat_ssl s, pg_stat_activity a
WHERE s.pid = a.pid AND a.datname IS NOT NULL
ORDER BY connected DESC;
