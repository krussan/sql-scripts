
; WITH CTE AS (
   SELECT    
      [SchemaName] = OBJECT_SCHEMA_NAME(T.object_id)
    , [TableName] = OBJECT_NAME(T.object_id)
    , last_user_update = COALESCE(ST.last_user_update, '1900-01-01')
    , last_user_seek = COALESCE(ST.last_user_seek, '1900-01-01')
    , last_user_scan = COALESCE(ST.last_user_scan, '1900-01-01')
    , last_user_lookup = COALESCE(ST.last_user_lookup, '1900-01-01')
   FROM    sys.tables T
   LEFT JOIN  sys.dm_db_index_usage_stats ST
      ON T.object_id = ST.object_id
      AND ST.database_id = DB_ID()
), PVT AS (
   SELECT pvt.SchemaName, pvt.TableName, last_accessed =  MAX(pvt.last_accessed)
   FROM CTE
   UNPIVOT (last_accessed FOR field IN (last_user_update, last_user_seek, last_user_scan, last_user_lookup)) pvt
   GROUP BY pvt.SchemaName, pvt.TableName
)
SELECT *
FROM PVT
ORDER BY PVT.last_accessed ASC




