DECLARE @columnName varchar(50) = '<partition_column, sysname, partition_column>'
DECLARE @schemaName varchar(50) = '<schema_name, sysname, schema_name>'
DECLARE @partitionScheme varchar(50) = '<partition_scheme, sysname, partition_scheme>'

; WITH CTE AS (
   SELECT 
      i.object_id
    , OBJECT_SCHEMA_NAME(i.object_id) AS schemaName
    , OBJECT_NAME(i.object_id) AS objectName
    , i.name AS indexName
    , C.name AS clustered_column_name
   FROM sys.indexes i 
   INNER JOIN sys.index_columns IC ON i.index_id = IC.index_id AND ic.object_id = i.object_id
   INNER JOIN sys.columns C ON IC.column_id = C.column_id AND C.object_id = IC.object_id
   WHERE i.type_desc = 'CLUSTERED'
   AND OBJECT_NAME(i.object_id) NOT LIKE 'sys%'
   AND OBJECT_NAME(i.object_id) NOT LIKE 'LKP%'
)
SELECT *
 , 'DROP INDEX ' + indexname + ' ON ' + CTE.schemaName + '.' + CTE.objectName
 , 'CREATE CLUSTERED INDEX ' + indexName +  ' ON ' + CTE.schemaName + '.' + CTE.objectName + '(' + @columnName + ') ON ' + @partitionScheme + '(' + @columnName + ') WITH (DATA_COMPRESSION = PAGE)'
FROM CTE
WHERE CTE.schemaName = @schemaName
AND CTE.clustered_column_name <> @columnName