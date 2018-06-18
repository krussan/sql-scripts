--SELECT *
--FROM sys.tables

--SELECT I.rows
--FROM sys.objects O
--INNER JOIN sys.indexes I ON I.object_id = O.object_id

;WITH CTE AS (
   select
      schemaName = OBJECT_SCHEMA_NAME(object_id),
      tableName = OBJECT_NAME(object_id),
      row_count = SUM(row_count)
   from sys.dm_db_partition_stats
   where index_id < 2  -- heap or clustered index
   group by OBJECT_ID
)
SELECT *, replace(convert(varchar,convert(Money, row_count),1),'.00','') 
FROM CTE
WHERE row_count > 0
--AND tableName = 'vourowx'
ORDER BY CTE.row_count DESC