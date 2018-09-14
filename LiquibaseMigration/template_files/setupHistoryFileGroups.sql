--liquibase formatted sql

--changeSet chth:Initial-file-storage-1 endDelimiter:\nGO splitStatements:true stripComments:false runOnChange:true
CREATE TABLE dbo.debugLog (message nvarchar(MAX))
GO

DECLARE @databaseName varchar(50) = '@DATABASENAME@'
DECLARE @startDate date = '2012-12-01'
DECLARE @endDate date = GETDATE()
DECLARE @ddate date = @startDate;
   DECLARE @SQL nvarchar(MAX);
   DECLARE @filegroup varchar(100);

   --< Find path of data files >--
   DECLARE @path varchar(500) = '';
   DECLARE @physicalPath varchar(500);
   DECLARE @next int;
   DECLARE @c int

   SELECT @physicalPath = physical_name FROM sys.database_files WHERE type = 0
   PRINT @physicalPath

   SET @c = CHARINDEX('\', @physicalPath)
   SET @path = SUBSTRING(@physicalPath, 0, @c)

   WHILE @c > 0
   BEGIN
      SET @next = CHARINDEX('\', @physicalPath, @c + 1);
      --SET @next = CASE WHEN @next = 0 THEN LEN(@physicalPath) + 1 ELSE @next END

      IF @next > 0 SET @path = @path + '\' + SUBSTRING(@physicalPath, @c + 1, @next  - @c - 1)
   
      SET @c = @next
   END

   SET @path = @path + '\'

-- Special handling of creation of filegroups in HISTORY only. Add other databases if they use the same
-- monthly scheme.
   IF OBJECT_ID('tempdb..#filegroups') IS NOT NULL DROP TABLE #filegroups

   CREATE TABLE #filegroups (ddate date, filegroup varchar(30))

   WHILE (@ddate < @endDate)
   BEGIN
      INSERT INTO #filegroups (ddate, filegroup)
      VALUES (@ddate, 'Data' + CONVERT(varchar(6), @ddate, 112))

      SET @ddate = DATEADD(MM, 1, @ddate)
   end


   DECLARE C CURSOR FAST_FORWARD READ_ONLY FOR
   SELECT filegroup
   FROM #filegroups

   OPEN C
   FETCH NEXT FROM C INTO @filegroup
   WHILE @@FETCH_STATUS = 0
   BEGIN
      
      IF NOT EXISTS(SELECT 1 FROM sys.filegroups WHERE name = @filegroup)
      BEGIN
         SET @SQL = 'ALTER DATABASE ' + QUOTENAME(@databaseName) + ' ADD FILEGROUP ' + @filegroup
         INSERT INTO dbo.debugLog (message) VALUES (@SQL)
         EXEC sp_executesql @SQL
      END

      IF NOT EXISTS(
         SELECT 1 FROM sys.database_files f 
         INNER JOIN sys.filegroups fg ON fg.data_space_id = f.data_space_id
         WHERE fg.name = @filegroup
      )
      BEGIN
         SET @SQL = 'ALTER DATABASE ' + QUOTENAME(@databaseName) + ' ADD FILE (NAME = ''' + @databaseName +  '_' + @filegroup + ''', FILENAME = ''' + @path + '\' + @databaseName + '_' + @filegroup + '.mdf'', FILEGROWTH = 1024MB, SIZE = 5MB) TO FILEGROUP ' + @filegroup
		 INSERT INTO dbo.debugLog (message) VALUES (@SQL)
         EXEC sp_executesql @SQL
      END  
   

      FETCH NEXT FROM C INTO @filegroup
   END
   CLOSE C
   DEALLOCATE C
