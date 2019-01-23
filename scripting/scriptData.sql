set nocount on
go

DECLARE @schema sysname = parsename('$(DataTable)', 2)
DECLARE @table sysname = parsename('$(DataTable)', 1)
declare @generateLiquibaseHeader bit = $(GenerateLiquibaseHeader)
declare @username sysname = '$(UserName)'
declare @hasIdentity bit;

DECLARE @SQL nvarchar(MAX);

--SELECT @schema + '.' + @table, OBJECT_ID(@schema + '.' + @table)
--Check for primary key
--Check for unique key
--Add if exists on primarykey/unique/all columns

--INSERT INTO dbo.tbl_seApplication (xxx,yyy) VALUES (xxx,yyy)

/*
SELECT *
FROM sys.key_constraints
WHERE (type = 'UQ' OR type = 'PK')
AND parent_object_id = OBJECT_ID(@schema + '.' + @table)
--AND OBJECT_ID(@schema + '.' + @table) IS NOT NULL

SELECT *
FROM sys.index_columns
WHERE object_id = OBJECT_ID(@schema + '.' + @table)

SELECT *
FROM sys.indexes
WHERE object_id = OBJECT_ID(@schema + '.' + @table)

*/

IF OBJECT_ID('tempdb..#tmp') IS NOT NULL DROP TABLE #tmp

DECLARE @columnList nvarchar(MAX);
SELECT columnList, insertList, TABLE_SCHEMA, TABLE_NAME, hasIdentity
into #tmp
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
				WHEN DATA_TYPE LIKE '%char%' OR DATA_TYPE LIKE '%date%' OR DATA_TYPE LIKE '%time%' THEN 
					CASE WHEN IS_NULLABLE = 'YES' THEN 'COALESCE('''''''' + REPLACE(' + QUOTENAME(COLUMN_NAME) + ', '''''''', '''''''''''') + '''''''', ''NULL'')'
					ELSE ''''''''' + REPLACE(' + QUOTENAME(COLUMN_NAME) + ', '''''''', '''''''''''') + '''''''''
					END
				WHEN DATA_TYPE LIKE '%int%' OR DATA_TYPE = 'decimal' OR DATA_TYPE = 'numeric' OR DATA_TYPE = 'bit' THEN 
					CASE WHEN IS_NULLABLE='YES' THEN 'COALESCE(CONVERT(varchar(30), ' + QUOTENAME(COLUMN_NAME) + '), ''NULL'')' 
					ELSE 'CONVERT(varchar(30), ' + QUOTENAME(COLUMN_NAME) + ')' 
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
cross apply (
	select hasIdentity = case when exists (select is_identity
	from sys.columns
	where object_id = object_id(T.TABLE_SCHEMA + '.' + T.TABLE_NAME)
	and is_identity = 1) then 1 else 0 end
) HID
WHERE T.TABLE_NAME LIKE @table AND T.TABLE_SCHEMA LIKE @schema
	and T.TABLE_TYPE = 'BASE TABLE'
ORDER BY T.TABLE_SCHEMA, T.TABLE_NAME

DECLARE C CURSOR FAST_FORWARD READ_ONLY FOR
select columnList, insertList, TABLE_SCHEMA, TABLE_NAME, hasIdentity
from #tmp

DECLARE @cmd nvarchar(MAX);

OPEN C
FETCH NEXT FROM C INTO @columnList, @SQL, @schema, @table, @hasIdentity
WHILE @@FETCH_STATUS = 0
BEGIN

   if @generateLiquibaseHeader = 1
   BEGIN
	  set @cmd ='--liquibase formatted sql

--changeSet ' + @username + ':Initial-' + @schema + '-' + REPLACE(REPLACE(@table, '.', '-'), '_', '-') + '-0 endDelimiter:\nGO splitStatements:true stripComments:false runOnChange:false'
	  print @cmd
	  
   end

   if @hasIdentity = 1 
   begin
	  set @cmd = 'SET IDENTITY_INSERT ' + quotename(@schema) + '.' + quotename(@table) + ' ON;'
	  print @cmd
   end
   
   SET @SQL = 'SELECT ''INSERT INTO ' + QUOTENAME(@schema) + '.' + QUOTENAME(@table) + ' (' + @columnList + ') VALUES ('' + ' + @SQL  + N' + '')'' FROM ' + QUOTENAME(@schema) + '.' + QUOTENAME(@table);

   --print @sql
   EXEC sp_executesql @SQL

   if @hasIdentity = 1 
   begin
	  set @cmd = 'SET IDENTITY_INSERT ' + quotename(@schema) + '.' + quotename(@table) + ' OFF;'
	  print @cmd
   end

   FETCH NEXT FROM C INTO @columnList, @SQL, @schema, @table, @hasIdentity
END
CLOSE C
DEALLOCATE C

