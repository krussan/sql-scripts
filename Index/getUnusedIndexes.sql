; WITH CTE AS (
   SELECT
      DB_NAME() AS databaseName,
      OBJECT_SCHEMA_NAME(i.object_id) AS SchemaName,
      OBJECT_NAME(i.object_id) AS TableName,
      i.name AS IndexName,
      i.type_desc AS IndexType, 
      i.is_primary_key,  
      iu.user_seeks,
      iu.user_scans,
      iu.user_lookups,
      iu.user_updates,
      iu.last_user_seek,
      iu.last_user_scan,
      iu.last_user_update,
      iu.system_scans,
      iu.last_system_scan,
      SUM(s.[used_page_count]) * 8 AS IndexSizeKB
   FROM
      sys.indexes i
      LEFT JOIN sys.dm_db_index_usage_stats iu
         ON i.object_id = iu.object_id
            AND i.Index_id = iu.index_id
            AND database_id = DB_ID() 
      LEFT JOIN sys.dm_db_partition_stats AS s 
            ON s.[object_id] = i.[object_id]
       AND s.[index_id] = i.[index_id]
   WHERE
      i.name IS NOT NULL
      AND i.is_primary_key=0
      AND i.is_unique=0
      AND OBJECT_SCHEMA_NAME(i.object_id) <>'sys'
	   AND COALESCE(user_seeks, 0) + COALESCE(user_scans, 0) + COALESCE(user_lookups, 0) = 0
   GROUP BY
      i.object_id,
      i.name,
      i.type_desc, 
      i.is_primary_key,  
      iu.user_seeks,
      iu.user_scans,
      iu.user_lookups,
      iu.user_updates,
      iu.last_user_seek,
      iu.last_user_scan,
      iu.last_user_update,
      iu.system_scans,
      iu.last_system_scan
)
SELECT *
, IndexSizeKB_del = REPLACE(convert(varchar,convert(Money, CTE.IndexSizeKB),1),'.00','') 
, dropSQL = 'DROP INDEX ' + QUOTENAME(IndexName) + ' ON ' + QUOTENAME(CTE.SchemaName) + '.' + QUOTENAME(CTE.TableName)
FROM CTE
WHERE 1=1
AND CTE.TableName NOT LIKE 'TYPE_CHANGED%'
AND CTE.TableName NOT LIKE 'OLD%'
AND CTE.TableName NOT LIKE '%OLD'
AND IndexType <> 'CLUSTERED'
AND IndexType <> 'XML'
ORDER BY
   CTE.IndexSizeKB DESC