DECLARE @reportDateColumn varchar(50) = '<partition_column, sysname, partition_column>'
DECLARE @schema varchar(50) = '<schema_name, sysname, schema_name>'
DECLARE @partitionScheme varchar(50) = '<partition_scheme, sysname, partition_scheme>'
DECLARE @indexSuffix varchar(50) = '<index_suffix, sysname, index_suffix>'

;WITH IDX AS (
   SELECT 
      i.object_id
    , OBJECT_NAME(i.object_id) AS objectName
    , i.name AS indexName
    , C.name AS clustered_column_name
   FROM sys.indexes i 
   INNER JOIN sys.index_columns IC ON i.index_id = IC.index_id AND ic.object_id = i.object_id
   INNER JOIN sys.columns C ON IC.column_id = C.column_id AND C.object_id = IC.object_id
   WHERE i.type_desc = 'CLUSTERED'
   AND OBJECT_NAME(i.object_id) NOT LIKE 'sys%'
   AND OBJECT_NAME(i.object_id) NOT LIKE 'LKP%'
   AND C.name = @reportDateColumn
), TAB AS (
   SELECT 
      T.OBJECT_ID
    , OBJECT_SCHEMA_NAME(T.object_id) AS schemaName
    , T.name AS tableName
    , C.name AS columnName
   FROM sys.columns C
   INNER JOIN sys.tables T ON C.object_id = T.object_id
   WHERE C.name = @reportDateColumn
), DATA AS (
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
SELECT *
, 'CREATE CLUSTERED INDEX cix_' + TAB.tableName + '_' + @indexSuffix + ' ON ' + TAB.schemaName + '.' + TAB.tableName + '(' + QUOTENAME(@reportDateColumn) + ') WITH (DATA_COMPRESSION = PAGE) ON ' + @partitionScheme + '(' + QUOTENAME(@reportDateColumn) + ');'
, 'CREATE CLUSTERED INDEX cix_' + TAB.tableName + '_' + @indexSuffix + ' ON ' + TAB.schemaName + '.' + TAB.tableName + '(' + QUOTENAME(@reportDateColumn) + ') WITH (DATA_COMPRESSION = PAGE) ON [PRIMARY];'
FROM TAB
LEFT JOIN IDX ON TAB.object_id = IDX.object_id
LEFT JOIN DATA ON TAB.object_id = DATA.object_id
WHERE IDX.object_id IS NULL
AND TAB.schemaName = @schema
AND DATA.Row_Count > 0

