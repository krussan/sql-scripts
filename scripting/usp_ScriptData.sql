set nocount on
go

declare @database sysname= 'DW_0_Admin'
DECLARE @schema sysname = 'Meta'
DECLARE @table sysname = 'm_filetype'
declare @hasIdentity bit;

DECLARE @SQL nvarchar(MAX);

IF OBJECT_ID('tempdb..#tmp') IS NOT NULL DROP TABLE #tmp
IF OBJECT_ID('tempdb..#output') IS NOT NULL DROP TABLE #output

DECLARE @columnList nvarchar(MAX);

create table #tmp (columnList nvarchar(max), insertList nvarchar(max), tableSchema sysname, tableName sysname, hasIdentity bit)

set @SQL = '
insert into #tmp (columnList, insertList, tableSchema, tableName, hasIdentity)
SELECT columnList, insertList, TABLE_SCHEMA, TABLE_NAME, hasIdentity
FROM ' + quotename(@database) + N'.INFORMATION_SCHEMA.TABLES T
CROSS APPLY (
	SELECT columnList = stuff(
		(SELECT N'','' + quotename(COLUMN_NAME) as [text()] 
		FROM (
			SELECT ORDINAL_POSITION, COLUMN_NAME
			FROM ' + quotename(@database) + N'.INFORMATION_SCHEMA.COLUMNS
			WHERE TABLE_NAME = T.TABLE_NAME AND TABLE_SCHEMA = T.TABLE_SCHEMA
	) AS importColumns
	ORDER BY ORDINAL_POSITION
	FOR XML PATH('''')),1,1,N'''')
) CC
CROSS APPLY (
	SELECT insertList = stuff(
		(SELECT N'' + '''','''' + '' + columnFunction as [text()] 
		FROM (
		SELECT columnFunction = 
			CASE 
				WHEN DATA_TYPE LIKE ''%char%'' OR DATA_TYPE LIKE ''%date%'' OR DATA_TYPE LIKE ''%time%'' THEN 
					CASE WHEN IS_NULLABLE = ''YES'' THEN ''COALESCE('''''''''''''''' + REPLACE('' + QUOTENAME(COLUMN_NAME) + '', '''''''''''''''', '''''''''''''''''''''''') + '''''''''''''''', ''''NULL'''')''
					ELSE '''''''''''''''''' + REPLACE('' + QUOTENAME(COLUMN_NAME) + '', '''''''''''''''', '''''''''''''''''''''''') + ''''''''''''''''''
					END
				WHEN DATA_TYPE LIKE ''%int%'' OR DATA_TYPE = ''decimal'' OR DATA_TYPE = ''numeric'' OR DATA_TYPE = ''bit'' THEN 
					CASE WHEN IS_NULLABLE=''YES'' THEN ''COALESCE(CONVERT(varchar(30), '' + QUOTENAME(COLUMN_NAME) + ''), ''''NULL'''')''
					ELSE ''CONVERT(varchar(30), '' + QUOTENAME(COLUMN_NAME) + '')'' 
					END
				ELSE NULL 
			END

		 , ORDINAL_POSITION
		FROM ' + quotename(@database) + N'.INFORMATION_SCHEMA.COLUMNS
		WHERE TABLE_NAME = T.TABLE_NAME AND TABLE_SCHEMA = T.TABLE_SCHEMA
	) AS importColumns
	ORDER BY ORDINAL_POSITION
	FOR XML PATH('''')),1,9,N'''')
) CCI
cross apply (
	select hasIdentity = case when exists (select is_identity
	from ' + quotename(@database) + N'.sys.columns
	where object_id = object_id(T.TABLE_SCHEMA + ''.'' + T.TABLE_NAME)
	and is_identity = 1) then 1 else 0 end
) HID
WHERE T.TABLE_NAME LIKE @table AND T.TABLE_SCHEMA LIKE @schema
	and T.TABLE_TYPE = ''BASE TABLE''
ORDER BY T.TABLE_SCHEMA, T.TABLE_NAME'

--print @sql
exec sp_executesql @sql, N'@schema sysname, @table sysname', @schema, @table


create table #output (row int identity(1,1) primary key clustered, cmd nvarchar(max))


--select *
--from #tmp

DECLARE C CURSOR FAST_FORWARD READ_ONLY FOR
select columnList, insertList, tableSchema, tableName, hasIdentity
from #tmp

DECLARE @cmd nvarchar(MAX);

OPEN C
FETCH NEXT FROM C INTO @columnList, @SQL, @schema, @table, @hasIdentity
WHILE @@FETCH_STATUS = 0
BEGIN

	
   if @hasIdentity = 1 
   begin
	  insert into #output values ('SET IDENTITY_INSERT ' + quotename(@database) + '.' + quotename(@schema) + '.' + quotename(@table) + ' ON;')
   end
   
   SET @SQL = 'INSERT INTO #output SELECT ''INSERT INTO ' + quotename(@database) + '.' + QUOTENAME(@schema) + '.' + QUOTENAME(@table) + ' (' + @columnList + ') VALUES ('' + ' + @SQL  + N' + '')'' FROM ' + QUOTENAME(@schema) + '.' + QUOTENAME(@table);

   --print @sql
   EXEC sp_executesql @SQL

   if @hasIdentity = 1 
   begin
	insert into #output values ('SET IDENTITY_INSERT ' + quotename(@database) + '.' + quotename(@schema) + '.' + quotename(@table) + ' OFF;')
   end

   FETCH NEXT FROM C INTO @columnList, @SQL, @schema, @table, @hasIdentity
END
CLOSE C
DEALLOCATE C



select cmd
from #output