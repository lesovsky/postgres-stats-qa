## Query Planning

- What is planner?
- How long queries are planned?
- What is the ratio of planning time to executing time?
- How to get plan of the query?

### What is planner?
After query has been received from an application, backend parses the query and run planner which creates plans. Each plan defines a way how to get and process the data. Depending on query complexity, plan might include many operations like scan tables or indexes, join other tables, sort or aggregate data, etc. Finally, planner chooses the most effective plan which will be used by executor. Queries performance directly depends on used plans. Poor or slow planning lead to performance degradation.


### How long queries are planned?
Extension `pg_stat_statements` provides statistics about queries. This statistics includes how much time queries were planned. By default, `pg_stat_statements` and tracking of queries planning is disabled, and it should be enabled separately.

Let's imagine that `pg_stat_statements` and `track_planning` are enabled, we can answer on question what queries planning longer than others:
```
# SELECT total_exec_time, total_plan_time, total_plan_time + total_exec_time AS total, query FROM pg_stat_statements ORDER BY 2 DESC LIMIT 3;
  total_exec_time   |  total_plan_time   |       total        |                                query                                
--------------------+--------------------+--------------------+---------------------------------------------------------------------
  4344.848898999999 | 1321.8663440000028 | 5666.7152430000015 | UPDATE pgbench_accounts SET abalance = abalance + $1 WHERE aid = $2
 384.12074800000096 |  917.0010800000014 | 1301.1218280000023 | SELECT abalance FROM pgbench_accounts WHERE aid = $1
 11413.904984000008 |  888.3042599999985 | 12302.209244000007 | UPDATE pgbench_tellers SET tbalance = tbalance + $1 WHERE tid = $2
```

Tip: use `round()` or `date_trunc()` functions to humanize numeric values, e.g. `11413.904984000008` vs. `00:00:11.414`?

Note: `pg_stat_statements` also provides aggregated min, max, mean, stddev values for planning and executing time.

### What is the ratio of planning time to executing time?
Query planning should be the fast operation. If planning takes too long, it is worth to know about that and dig why is this. Reason of this may vary: poor or stale statistics, suboptimal query, lack of resources, etc.

Using `pg_stat_statements` we can compare planning and total times and calculate ratio of how much time queries are planned. Comparing values, ratios are better than raw values especially if values are like millions or greater.
```
# SELECT total_exec_time, total_plan_time, total_plan_time / (total_plan_time + total_exec_time) * 100 AS ratio, query FROM pg_stat_statements WHERE calls > 1000 ORDER BY 3 DESC LIMIT 3;
```

Tip: use `round()` or `date_trunc()` functions to humanize numeric values, e.g. `70.47772624102035` vs. `70.48`?

### How to get plan of the query?
Investigating issues of query performance, the one important thing is getting its plan. `EXPLAIN` is the main tool for this. Explain utility has a few options, the most useful of them are `ANALYZE` and `BUFFERS` - try use them by default.

Note, `ANALYZE` option tells Postgres to make a real execution of query. Be careful with `ANALYZE` option when doing it with data modifying queries, like UPDATE or DELETE. Such queries could be wrapped into transactions with `ROLLBACK` in the end.

```
# explain (analyze, buffers) SELECT  rd_matching_id, user_rd_inet FROM task_stats_main WHERE task_unit_id IS NOT NULL AND external_source_id IS NULL AND created_at >= '2021-06-28 04:00:00' ORDER BY created_at desc LIMIT 50;
                                                                                          QUERY PLAN                                                                                          
----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
 Limit  (cost=0.71..4.26 rows=50 width=23) (actual time=4.844..5.043 rows=50 loops=1)
   Buffers: shared hit=1233
   ->  Append  (cost=0.71..271912.97 rows=3832924 width=23) (actual time=4.843..5.036 rows=50 loops=1)
         Buffers: shared hit=1233
         ->  Index Scan Backward using task_stats_2021_07_created_at_idx on task_stats_2021_07  (cost=0.14..1.36 rows=1 width=48) (actual time=0.004..0.005 rows=0 loops=1)
               Index Cond: (created_at >= '2021-06-28 04:00:00'::timestamp without time zone)
               Filter: ((task_unit_id IS NOT NULL) AND (external_source_id IS NULL))
               Buffers: shared hit=2
         ->  Index Scan Backward using task_stats_2021_06_created_at_idx on task_stats_2021_06  (cost=0.57..252746.99 rows=3832923 width=23) (actual time=4.838..5.023 rows=50 loops=1)
               Index Cond: (created_at >= '2021-06-28 04:00:00'::timestamp without time zone)
               Filter: ((task_unit_id IS NOT NULL) AND (external_source_id IS NULL))
               Rows Removed by Filter: 7582
               Buffers: shared hit=1231
 Planning Time: 0.465 ms
 Execution Time: 5.073 ms
```

Using `ANALYZE` and `BUFFERS` options, `EXPLAIN` executes query and shows a lot of useful information:
- actual time of executing each node,
- summary planning and executing time,
- buffers usage - how much data found in the buffer, and read from disk or page cache,
- indexes usage - how many rows were filtered.