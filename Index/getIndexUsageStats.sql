DECLARE @SQL nvarchar(MAX);
DECLARE @dbName sysname = '<database_name, sysname, database_name>'
DECLARE @dbid int = DB_ID(@dbname)

SET @SQL = '
   SELECT  
                         dbname = DB_NAME(database_id) ,
                         schemaName = OBJECT_SCHEMA_NAME(ius.OBJECT_ID, database_id) ,
                         tablename = OBJECT_NAME(ius.object_id, database_id) ,
                         i.name ,
                         database_id ,
                         type_desc ,
                         is_primary_key
                         user_seeks ,
                         user_scans ,
                         user_lookups ,
                         user_updates ,
                         last_user_seek ,
                         last_user_scan ,
                         last_user_lookup ,
                         last_user_update ,
                         system_seeks ,
                         system_scans ,
                         system_lookups ,
                         system_updates ,
                         last_system_seek ,
                         last_system_scan ,
                         last_system_lookup ,
                         last_system_update
   FROM    ' + @dbName + '.sys.dm_db_index_usage_stats ius
           INNER JOIN ' + @dbName + '.sys.indexes i ON ius.OBJECT_ID = i.object_id
                                       AND ius.index_id = i.index_id
   WHERE   database_id = @dbid
'

EXEC sp_executesql @SQL, N'@dbid int', @dbid