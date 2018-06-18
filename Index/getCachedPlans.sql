; WITH CTE AS (
   SELECT 
     databaseName = DB_NAME(T.dbid)
   , schemaName = OBJECT_SCHEMA_NAME(T.objectid, T.dbid)
   , objectname = OBJECT_NAME(T.objectid, T.dbid)
   , objtype
   , qp.query_plan
   , CP.usecounts
   , cp.cacheobjtype
   , cp.size_in_bytes
   , T.text
  FROM sys.dm_exec_cached_plans AS CP
  CROSS APPLY sys.dm_exec_sql_text( plan_handle)AS T
  CROSS APPLY sys.dm_exec_query_plan( plan_handle)AS QP
  WHERE cp.cacheobjtype = 'Compiled Plan'
)
SELECT *
FROM CTE
WHERE databaseName = '<database, sysname, database>'
AND schemaName = '<schema, sysname, schema>'
AND objectname = '<object_name, sysname, object_name>'

