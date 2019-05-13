declare @sql nvarchar(max);

-- Get a list of all the indexes to exclude columnstore indexes
IF OBJECT_ID('tempdb..#indexes') IS NOT NULL DROP TABLE #indexes
create table #indexes (databaseId int, object_id int, type tinyint, type_desc varchar(100))

set @sql = 'insert into #indexes exec sp_msforeachdb ''select DB_ID(''''?''''), object_id, type, type_desc from [?].sys.indexes'''

exec (@sql)

; WITH CTE AS (
      SELECT 
      databaseName = DB_NAME(mid.database_id),
      schemaName = OBJECT_SCHEMA_NAME(mid.object_id, mid.database_id),
      objectName = OBJECT_NAME(mid.object_id, mid.database_id),
         mid.equality_columns,
         mid.inequality_columns,
         mid.included_columns,
         migs.unique_compiles,
         migs.user_seeks,
         migs.user_scans,
         migs.last_user_seek,
         migs.avg_user_impact,
         --user_scans,
         avg_total_user_cost,
         avg_total_user_cost * avg_user_impact * (user_seeks + user_scans) AS [weight]
      FROM
         sys.dm_db_missing_index_group_stats AS migs
         INNER JOIN sys.dm_db_missing_index_groups AS mig
            ON (migs.group_handle = mig.index_group_handle)
         INNER JOIN sys.dm_db_missing_index_details AS mid
            ON (mig.index_handle = mid.index_handle)

	--
	where not exists (
		select 1 from #indexes I
		where mid.database_id = I.databaseId
			and mid.object_id = I.object_id
			and I.type = 5
	)
)
SELECT *
, weight_del = replace(convert(varchar,convert(Money, CTE.weight),1),'.00','') 
               
FROM CTE
WHERE 1=1
--AND CTE.databaseName = '<database_name, sysname, database_name>'
AND CTE.avg_user_impact > 80
--AND CTE.objectName = '<object_name, sysname, object_name>'
--ORDER BY CTE.weight DESC
ORDER BY CTE.weight DESC
 
 --DBCC DROPCLEANBUFFERS
 --DBCC FREEPROCCACHE
