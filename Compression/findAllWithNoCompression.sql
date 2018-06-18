IF OBJECT_ID('tempdb..#temp') IS NOT NULL DROP TABLE #temp
IF OBJECT_ID('tempdb..#result') IS NOT NULL DROP TABLE #result

CREATE TABLE #result (name sysname, [rows] int, reserved varchar(50), data varchar(50), index_size varchar(50), unused varchar(50))
DECLARE @cmd nvarchar(MAX);
  
SELECT schemaName = OBJECT_SCHEMA_NAME(P.object_id)
, objectName = OBJECT_NAME(P.object_id)
, rows = SUM(rows)
, I.name
, spaceUsedCmd = 'EXEC sp_spaceused @objname = ''[' + OBJECT_SCHEMA_NAME(P.object_id) + '].[' + OBJECT_NAME(P.object_id) + ']'''
, fillTableCmd = 'INSERT INTO #result(name, [rows], reserved, data, index_size, unused) EXEC sp_spaceused @objname = ''[' + OBJECT_SCHEMA_NAME(P.object_id) + '].[' + OBJECT_NAME(P.object_id) + ']'''
, alterIndexCmd = 'ALTER INDEX [' + I.name + '] ON [' + OBJECT_SCHEMA_NAME(P.object_id) + '].[' + OBJECT_NAME(P.object_id) + '] REBUILD PARTITION = ALL WITH (DATA_COMPRESSION = PAGE)'
INTO #temp
FROM sys.partitions AS P
INNER JOIN sys.tables T ON P.object_id = T.object_id 
INNER JOIN sys.indexes AS I ON I.object_id = P.object_id AND I.index_id = P.index_id
WHERE 1=1
--AND rows > 10000
AND data_compression <> 2
--AND P.index_id > 0
--AND I.is_primary_key = 1
AND I.type = 1 -- CLUSTERED
--AND (OBJECT_NAME(P.object_id) LIKE 'TYPE_CHANGED%'
--   OR OBJECT_NAME(P.object_id) LIKE 'OLDDATA%')

GROUP BY P.object_id, I.name

ORDER BY rows DESC

SELECT * FROM #temp

--DECLARE C CURSOR LOCAL READ_ONLY FAST_FORWARD FOR
--SELECT fillTableCmd FROM #temp

--OPEN C
--FETCH NEXT FROM C INTO @cmd
--WHILE (@@FETCH_STATUS = 0)
--BEGIN

--   EXEC sp_executesql @cmd
--   FETCH NEXT FROM C INTO @cmd
--END
--CLOSE C
--DEALLOCATE C

--; WITH CTE AS (
--   SELECT name, size = CONVERT(int, REPLACE(reserved, ' KB', '')), readableSize = REPLACE(convert(varchar,convert(Money, CONVERT(int, REPLACE(reserved, ' KB', '') )),1),'.00','')  
--   FROM #result
--)
--SELECT SUM(size), REPLACE(convert(varchar,convert(Money, SUM(size)),1),'.00','')  
--FROM CTE --SUM(size), REPLACE(convert(varchar,convert(Money, SUM(size)),1),'.00','')   FROM CTE
--ORDER BY size DESC