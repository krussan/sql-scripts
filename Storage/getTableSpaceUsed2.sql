;WITH DATA AS (
    SELECT 
        a2.object_id,
        a3.name AS SchemaName,
        a2.name AS TableName,
        a1.rows as Row_Count,
        (a1.reserved )* 8.0 / 1024 AS reserved_mb,
        a1.data * 8.0 / 1024 AS data_mb,
        (CASE WHEN (a1.used ) > a1.data THEN (a1.used ) - a1.data ELSE 0 END) * 8.0 / 1024 AS index_size_mb,
        (CASE WHEN (a1.reserved ) > a1.used THEN (a1.reserved ) - a1.used ELSE 0 END) * 8.0 / 1024 AS unused_mb

    FROM    (   SELECT
                ps.object_id,
                SUM ( CASE WHEN (ps.index_id < 2) THEN row_count    ELSE 0 END ) AS [rows],
                SUM (ps.reserved_page_count) AS reserved,
                SUM (CASE   WHEN (ps.index_id < 2) THEN (ps.in_row_data_page_count + ps.lob_used_page_count + ps.row_overflow_used_page_count)
                            ELSE (ps.lob_used_page_count + ps.row_overflow_used_page_count) END
                    ) AS data,
                SUM (ps.used_page_count) AS used
                FROM sys.dm_db_partition_stats ps
                GROUP BY ps.object_id
            ) AS a1

    INNER JOIN sys.all_objects a2  ON ( a1.object_id = a2.object_id )

    INNER JOIN sys.schemas a3 ON (a2.schema_id = a3.schema_id)

    WHERE a2.type <> N'S' and a2.type <> N'IT'   
), WR AS (
   SELECT *
     , indexDataRatio = CASE WHEN data_mb = 0 THEN 0 ELSE CONVERT(float, index_size_mb) / CONVERT(float, data_mb) END
   FROM DATA
)
SELECT 
   object_id
 , SchemaName
 , TableName
 , Row_Count = REPLACE(convert(varchar,convert(Money, Row_Count),1),'.00','') 
 , reserved_mb = REPLACE(convert(varchar,convert(Money, CONVERT(int, reserved_mb)),1),'.00','') 
 , total_mb = replace(convert(varchar,convert(Money, data_mb + WR.index_size_mb),1),'.00','') 
 , total_GB = replace(convert(varchar,convert(Money, data_mb / 1024 + WR.index_size_mb / 1024),1),'.00','') 
 , data_mb = replace(convert(varchar,convert(Money, data_mb),1),'.00','') 
 , data_GB = replace(convert(varchar,convert(Money, data_mb / 1024),1),'.00','') 
 , index_size_mb = replace(convert(varchar,convert(Money, WR.index_size_mb),1),'.00','') 
 , index_size_GB = replace(convert(varchar,convert(Money, WR.index_size_mb / 1024),1),'.00','') 
 , unused_mb
 , indexDataRatio
FROM WR
WHERE 1=1
--AND data_mb > 100
--AND indexDataRatio > 2
ORDER BY data_mb + WR.index_size_mb DESC

