DECLARE @schema sysname = 'dbo'
DECLARE @table sysname = 'table'
DECLARE @SQL nvarchar(MAX);
		SELECT COLUMN_NAME
		FROM INFORMATION_SCHEMA.COLUMNS
		WHERE TABLE_NAME = @table AND TABLE_SCHEMA = @schema

--Check for primary key
--Check for unique key
--Add if exists on primarykey/unique/all columns

--INSERT INTO dbo.tbl_seApplication (xxx,yyy) VALUES (xxx,yyy)
DECLARE @columnList nvarchar(MAX);

DECLARE C CURSOR FAST_FORWARD READ_ONLY FOR
SELECT columnList, insertList, TABLE_SCHEMA, TABLE_NAME
FROM INFORMATION_SCHEMA.TABLES T
CROSS APPLY (
	SELECT columnList = stuff(
		(SELECT N',' + quotename(COLUMN_NAME) as [text()] 
		FROM (
			SELECT ORDINAL_POSITION, COLUMN_NAME
			FROM INFORMATION_SCHEMA.COLUMNS
			WHERE TABLE_NAME = T.TABLE_NAME AND TABLE_SCHEMA = T.TABLE_SCHEMA
	) AS importColumns
	ORDER BY ORDINAL_POSITION
	FOR XML PATH('')),1,1,N'')
) CC
CROSS APPLY (
	SELECT insertList = stuff(
		(SELECT N' + '','' + ' + columnFunction as [text()] 
		FROM (
		SELECT columnFunction = 
			CASE 
				WHEN DATA_TYPE LIKE '%char%' OR DATA_TYPE LIKE '%date%' THEN 
					CASE WHEN IS_NULLABLE = 'YES' THEN 'COALESCE('''''''' + ' + QUOTENAME(COLUMN_NAME) + ' + '''''''', ''NULL'')'
					ELSE ''''''''' + ' + QUOTENAME(COLUMN_NAME) + ' + '''''''''
					END
				WHEN DATA_TYPE LIKE '%int%' OR DATA_TYPE = 'decimal' OR DATA_TYPE = 'numeric' OR DATA_TYPE = 'bit' THEN 
					CASE WHEN IS_NULLABLE='YES' THEN 'CONVERT(varchar(30), ' + QUOTENAME(COLUMN_NAME) + ')' 
					ELSE 'COALESCE(CONVERT(varchar(30), ' + QUOTENAME(COLUMN_NAME) + '), ''NULL'')' 
					END
				ELSE NULL 
			END

		 , ORDINAL_POSITION
		FROM INFORMATION_SCHEMA.COLUMNS
		WHERE TABLE_NAME = T.TABLE_NAME AND TABLE_SCHEMA = T.TABLE_SCHEMA
	) AS importColumns
	ORDER BY ORDINAL_POSITION
	FOR XML PATH('')),1,9,N'')
) CCI
WHERE T.TABLE_NAME LIKE @table AND T.TABLE_SCHEMA LIKE @schema
ORDER BY T.TABLE_SCHEMA, T.TABLE_NAME

OPEN C
FETCH NEXT FROM C INTO @columnList, @SQL, @schema, @table
WHILE @@FETCH_STATUS = 0
BEGIN
      
	  PRINT @columnList
	  PRINT @SQL
	  SET @SQL = 'SELECT ''INSERT INTO ' + QUOTENAME(@schema) + '.' + QUOTENAME(@table) + ' (' + @columnList + ') VALUES ('' + ' + @SQL  + N' + '')'' FROM ' + QUOTENAME(@schema) + '.' + QUOTENAME(@table);
	  PRINT @SQL
	
   EXEC sp_executesql @SQL

   FETCH NEXT FROM C INTO @columnList, @SQL, @schema, @table
END
CLOSE C
DEALLOCATE C

