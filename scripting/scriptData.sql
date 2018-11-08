DECLARE @schema sysname = 'dbo'
DECLARE @table sysname = 'tblData'
DECLARE @SQL nvarchar(MAX);


--Check for primary key
--Check for unique key
--Add if exists on primarykey/unique/all columns

--INSERT INTO dbo.tbl_seApplication (xxx,yyy) VALUES (xxx,yyy)
DECLARE @columnName varchar(100);

DECLARE C CURSOR FAST_FORWARD READ_ONLY FOR
-- SELECT INSERT INTO tbl_seDirective (columnList) VALUES (
SELECT 'SELECT ' + columnList + ' FROM ' + QUOTENAME(TABLE_SCHEMA) + '.' + QUOTENAME(TABLE_NAME)
FROM INFORMATION_SCHEMA.TABLES T
CROSS APPLY (
	SELECT columnList = stuff(
		(SELECT N',' + quotename(COLUMN_NAME) as [text()] 
		FROM (
		SELECT *
		FROM INFORMATION_SCHEMA.COLUMNS
		WHERE TABLE_NAME = T.TABLE_NAME AND TABLE_SCHEMA = T.TABLE_SCHEMA
	) AS importColumns
	FOR XML PATH('')),1,1,N'')
) CC
WHERE T.TABLE_NAME LIKE @table AND T.TABLE_SCHEMA LIKE @schema

OPEN C
FETCH NEXT FROM C INTO @SQL
WHILE @@FETCH_STATUS = 0
BEGIN
   EXEC sp_executesql @SQL
   FETCH NEXT FROM C INTO @SQL
END
CLOSE C
DEALLOCATE C