SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED 
DECLARE @IndexName AS NVARCHAR(128) = '<index_name, sysname, index_name>';

-- Make sure the name passed is appropriately quoted 
SET @IndexName = QUOTENAME(@IndexName); 

-- Dig into the plan cache and find all plans using this index 
;WITH XMLNAMESPACES 
   (DEFAULT 'http://schemas.microsoft.com/sqlserver/2004/07/showplan')    
SELECT TOP 10
     databaseName = DB_NAME(qp.dbid)
   , schemaName = OBJECT_SCHEMA_NAME(qp.objectid, qp.dbid)
   , objectname = OBJECT_NAME(qp.objectid, qp.dbid)
   , objtype
   , SQL_Text = stmt.value('(@StatementText)[1]', 'varchar(max)')
   , DatabaseName = obj.value('(@Database)[1]', 'varchar(128)') 
   , SchemaName = obj.value('(@Schema)[1]', 'varchar(128)')
   , TableName = obj.value('(@Table)[1]', 'varchar(128)')
   , IndexName = obj.value('(@Index)[1]', 'varchar(128)')
   , IndexKind = obj.value('(@IndexKind)[1]', 'varchar(128)')
   , cp.plan_handle
   , query_plan
FROM sys.dm_exec_cached_plans AS cp 
CROSS APPLY sys.dm_exec_query_plan(plan_handle) AS qp 
CROSS APPLY query_plan.nodes('/ShowPlanXML/BatchSequence/Batch/Statements/StmtSimple') AS batch(stmt) 
CROSS APPLY stmt.nodes('.//IndexScan/Object[@Index=sql:variable("@IndexName")]') AS idx(obj) 
OPTION(MAXDOP 1, RECOMPILE);