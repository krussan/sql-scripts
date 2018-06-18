DECLARE @reportDateColumn varchar(50) = '<partition_column, sysname, partition_column>'
DECLARE @schema varchar(50) = '<schema_name, sysname, schema_name>'
DECLARE @partitionScheme varchar(50) = '<partition_scheme, sysname, partition_scheme>'

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
)
SELECT *
, 'CREATE CLUSTERED INDEX cix_' + TAB.tableName + '_' + @reportDateColumn + ' ON ' + TAB.schemaName + '.' + TAB.tableName + '(' + QUOTENAME(@reportDateColumn) + ') WITH (DATA_COMPRESSION = PAGE) ON ' + @partitionScheme + '(' + QUOTENAME(@reportDateColumn) + ');'
, 'CREATE CLUSTERED INDEX cix_' + TAB.tableName + '_' + @reportDateColumn + ' ON ' + TAB.schemaName + '.' + TAB.tableName + '(' + QUOTENAME(@reportDateColumn) + ') WITH (DATA_COMPRESSION = PAGE) ON [PRIMARY];'
FROM TAB
LEFT JOIN IDX ON TAB.object_id = IDX.object_id
WHERE IDX.object_id IS NULL
AND TAB.schemaName = @schema
