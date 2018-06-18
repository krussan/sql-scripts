IF OBJECT_ID('tempdb..#temp') IS NOT NULL DROP TABLE #temp

; WITH CTE AS (
   SELECT 
      DB_NAME(st.dbid) AS databaseName,
      OBJECT_SCHEMA_NAME(st.objectid, st.dbid) AS schemaName,
      OBJECT_NAME(st.objectid, st.dbid) AS objectname,
      last_worker_time,
      DEQS.last_execution_time,
      last_logical_reads,
      last_logical_writes,
      DEQS.execution_count,
      CONVERT(xml, '<?query --' + CHAR(13) + REPLACE(REPLACE(st.text, '>', '&gt;'), '<', '&lt;') + CHAR(13) + ' --?>') AS [SQL Text],
      plan_handle,
      DEQP.query_plan
   FROM sys.dm_exec_query_stats AS DEQS WITH (NOLOCK, READUNCOMMITTED)
   CROSS APPLY sys.dm_exec_sql_text(DEQS.plan_handle) st 
   OUTER APPLY sys.dm_exec_query_plan(DEQS.plan_handle) AS DEQP
)
SELECT TOP 40 *
FROM CTE
WHERE (1=1)
AND databaseName = '<database_name, sysname, database_name>'
--AND schemaName = '<schema_name, sysname, schema_name>'
--AND CTE.objectname LIKE 'split%'
--AND objectName IS NOT NULL
ORDER BY CTE.last_logical_reads DESC

--SELECT query_plan FROM sys.dm_exec_query_plan(0x05000500218AA43F4041F1AD150000000000000000000000)

