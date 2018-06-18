DECLARE @procSchema sysname = '<schema_name, sysname, schema_name>'
DECLARE @objName sysname = '<proc_name, sysname, proc_name>'
DECLARE @objType varchar(5)
DECLARE @SQL nvarchar(MAX);

SELECT @objType = type
FROM sys.objects
WHERE object_id = OBJECT_ID(@procSchema + '.' + @objName)

SELECT @SQL = 'DBCC FREEPROCCACHE (' + '0x' + cast('' as xml).value('xs:hexBinary(sql:column("plan_handle") )', 'varchar(max)') + ')'
--SELECT plan_handle, st.text
FROM sys.dm_exec_cached_plans 
CROSS APPLY sys.dm_exec_sql_text(plan_handle) AS st
WHERE text LIKE N'CREATE ' + CASE WHEN @objType IN ('FN', 'IF', 'TF') THEN 'FUNCTION' WHEN @objType IN ('P') THEN 'PROCEDURE' ELSE '%' END + ' \[' + @procSchema + '\].\[' + @objName + '\]%' ESCAPE '\';

PRINT @SQL
EXEC sp_executesql @SQL