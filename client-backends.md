## Client backends

- [What is client backend?](#what-is-client-backend)
- [How many clients connected to the server?](#how-many-clients-connected-to-the-server)
- [How many clients connected to the database?](#how-many-clients-connected-to-the-database)
- [How many clients connected remotely?](#how-many-clients-connected-remotely)
- [What states of connected clients?](#what-states-of-connected-clients)
- [Do the connected clients use SSL?](#do-the-connected-clients-use-ssl)
- [How much time spent by sessions?](#how-much-time-spent-by-sessions)
- [How many sessions were established and terminated?](#how-many-sessions-were-established-and-terminated)
- [How much memory is used by backend?](#how-much-memory-is-used-by-backend)

### What is client backend?
Postgres handles each client connection in a dedicated process called `backend`. This is something like a communication channel between client application and database. Application establishes connection with Postgres and new backend is created for the connection. Next, application sends queries over connection, the backend receives and executes queries and sends results back to the application.

You may think that all client backends is simply clients connected to the database server.

### How many clients connected to the server?
You can get the answer on this question using at least two ways:

The first way is sum all `numbackends` of `pg_stat_database` view.
```
SELECT sum(numbackends) FROM pg_stat_database;
```

This is the simple and exact way to count number of connected clients.

There is also `pg_stat_activity` could be used. This view contains extended information about activity, and we have to add extra condition.

```
SELECT count(*) FROM pg_stat_activity WHERE backend_type IN ('client backend','autovacuum worker');
```

In this case we have to count autovacuum workers because they also establish database connections and should be considered as clients.

### How many clients connected to the database?
It is easy to answer on this question when we already answered on previous one. We just need to extend query and add extra condition related to database name.

In case of `pg_stat_database`, we also don't need to sum.
```
SELECT datname, numbackends FROM pg_stat_database WHERE datname = 'pgbench';
```

With `pg_stat_activity`, extend the query and specify additional `datname` condition:
```
SELECT datname, count(*) FROM pg_stat_activity WHERE backend_type IN ('client backend','autovacuum worker') AND datname = 'pgbench';
```

### How many clients connected remotely?
Clients could be connected from the same host where the database server is running - these are local clients. Other clients connected over network are remote clients.
Sometimes DBA need to understand how many and from which hosts clients are connected. It may be needed to identify the most crowd hosts which established too many connections.

For getting this information, we could use `pg_stat_activity` only.
```
SELECT client_addr, count(*) FROM pg_stat_activity WHERE client_addr IS NOT NULL AND client_addr != '127.0.0.1' GROUP BY 1 ORDER BY 2 DESC;
```

In this example, all connections established from `localhost` or through `UNIX sockets` are excluded.

Let's take a look on another example - here is we added fields with user and database names, to get the detailed picture about connections distribution. We also remove conditions related to connections locality.
```
SELECT client_addr, usename, datname, count(*) FROM pg_stat_activity GROUP BY 1,2,3 ORDER BY 4 DESC;
```

### What states of connected clients?
When clients are connected to the database server they might be in several states:
- `idle` - means the client backend does nothing and waiting for commands (or queries) from client;
- `active` - means the client backend is doing some work, e.g. executing query, committing transaction, sending result and so on.
- `idle in transaction` - means the client application has been opened a transaction and do nothing - this is unwanted state and should be avoided.
- `idle in transaction (aborted)` - means transaction has been failed due to an error inside a transaction - this is also unwanted.
- `fastpath function call` - means the client backend is executing a fast-path function. The fast-path interface is obsolete, and quite exotic these days.
- `disabled` - means Postgres server is configured with disabled track_activities, which is not recommended.

As you can see there are at least two unwanted states, and it's desirable to know states of our connected clients. Use `state` from `pg_stat_activity`.
```
SELECT state, count(*) FROM pg_stat_activity WHERE state IS NOT NULL GROUP BY 1 ORDER BY 2 DESC;
```

In this example, we exclude activity with NULL states, because the most of background daemons don't update their states (except WAL senders and autovacuum workers).

### Do the connected clients use SSL?
For secure communication between client and database server Postgres provides SSL connections. This especially important when database server is compelled to work in insecure or untrusted environment.

Our assistant here is `pg_stat_ssl` in addition to already known `pg_stat_activity`.

```
SELECT
    s.pid,
    a.backend_type,
    a.client_addr,
    a.usename,
    a.datname,
    s.ssl,
    s.version
FROM pg_stat_ssl s, pg_stat_activity a
WHERE s.pid = a.pid AND a.datname IS NOT NULL
ORDER BY a.backend_start DESC;
```

This is quite verbose query - it describes in details client backends and connection requisites like address, user, database and SSL settings. Take a look on `ssl` field. This is a boolean field identifies, SSL is used or not. 

### How much time spent by sessions?
Session is period of time when client was connected to a database server. During sessions, clients do their work - send queries, receive results and again. With states of client backends, Postgres also tracks the time spent in sessions. These counters are combined in `pg_stat_database`.

Take a look on the following example:
```
SELECT datname, session_time, session_time - (active_time + idle_in_transaction_time) AS idle_time, active_time, idle_in_transaction_time FROM pg_stat_database ORDER BY 2 DESC LIMIT 1;
    datname     | session_time  |     idle_time      | active_time  | idle_in_transaction_time 
----------------+---------------+--------------------+--------------+--------------------------
 pgbench        | 768137444.027 |       748638381.75 |  9994931.493 |              9504130.784
```

The output values are in milliseconds. Here is we have per-database sessions statistics. As you may know the `idle in transaction` state is harmful and unwanted and `idle_in_transaction_time` is the most interesting here. Using `idle_in_transaction_time` we could understand how much time wasted in transaction - this gives the point which applications should be optimized to avoid idle during transactions.

Tip: use `date_trunc` function to convert milliseconds to human-readable time, e.g. `date_trunc('seconds', session_time * '1 millisecond'::interval)` 

Note: the session statistics have been introduced in Postgres 14 released in autumn of 2021.

### How many sessions were established and terminated?
This ia another answer which could be provided by session statistics. The usual workflow of the most of the applications is connecting to the databases at startup, create required number of sessions and work until application restart or shutdown. During shutdown, an application should disconnect from database server gracefully. In real world we have errors of different kind, in applications, networking, database, etc. Due to these errors, established sessions could be closed and application have to re-establish it. It's important to track sessions and react when they are not closed gracefully.

Take a look on the following query:
```
SELECT datname, sessions, sessions - (numbackends + sessions_abandoned + sessions_fatal + sessions_killed) AS session_ok, sessions_abandoned, sessions_fatal, sessions_killed FROM pg_stat_database ORDER BY sessions DESC LIMIT 1;
 datname | sessions | session_ok | sessions_abandoned | sessions_fatal | sessions_killed 
---------+----------+------------+--------------------+----------------+-----------------
 pgbench |  1308758 |    1308746 |                  3 |              8 |               0
```

This example shows a perfect picture, we have a too few sessions were finished incorrectly.

Tip: use ratios for counters with big numbers.

### How much memory is used by backend?
It is a simple question, which has a complex answer. Usually people trying to answer on this question using `top` utility and similar. Unfortunately due to many factors this way is deceptive and misleading. For further details checkout the [post](https://blog.anarazel.de/2020/10/07/measuring-the-memory-overhead-of-a-postgres-connection/) written by Andres Freund.

Fortunately from Postgres point of view we could answer on this using `pg_backend_memory_contexts`.
```
select sum(total_bytes) as total, sum(free_bytes) as free, sum(used_bytes) as used from pg_backend_memory_contexts;
  total  |  free  |  used   
---------+--------+---------
 1861872 | 684728 | 1177144
```

Tip: use `pg_size_pretty()` function to print human-readable size.

For getting information about other process use `pg_log_backend_memory_contexts` function which prints memory usage in database server log.