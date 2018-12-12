SET NOCOUNT ON
GO

DECLARE @SQL varchar(MAX)

IF OBJECT_ID('tempdb..#stmt') IS NOT NULL DROP TABLE #stmt

CREATE TABLE #stmt (ID int IDENTITY(1, 1), stmt VARCHAR(MAX))

INSERT INTO #stmt (stmt)
SELECT 'EXEC sp_droprolemember ''' + R.name + ''', ''' + P.name + ''''
FROM sys.database_role_members M
INNER JOIN sys.database_principals R ON M.role_principal_id = R.principal_id
INNER JOIN sys.database_principals P ON M.member_principal_id = P.principal_id
WHERE R.is_fixed_role = 0   


INSERT INTO #stmt (stmt)
SELECT 'DROP ROLE ' + QUOTENAME(name)
FROM sys.database_principals
WHERE type_desc = 'DATABASE_ROLE'
AND is_fixed_role = 0 AND name <> 'public'

INSERT INTO #stmt (stmt)
SELECT 'DROP APPLICATION ROLE ' + QUOTENAME(name) 
FROM sys.database_principals
WHERE type_desc = 'APPLICATION_ROLE'

INSERT INTO #stmt (stmt)
SELECT 'DROP SYNONYM ' + QUOTENAME(OBJECT_SCHEMA_NAME(O.object_id)) + '.' + QUOTENAME(O.name)
FROM sys.synonyms O

INSERT INTO #stmt (stmt)
SELECT 'ALTER TABLE ' + QUOTENAME(OBJECT_SCHEMA_NAME(O.object_id)) + '.' + QUOTENAME(O.name)
 + ' DROP CONSTRAINT ' + QUOTENAME(FK.name)
FROM sys.foreign_keys FK
INNER JOIN sys.objects O ON FK.parent_object_id = O.object_id
INNER JOIN sys.objects R ON FK.referenced_object_id = R.object_id


INSERT INTO #stmt (stmt)
SELECT 'DROP VIEW ' + QUOTENAME(TABLE_SCHEMA) + '.' + QUOTENAME(TABLE_NAME)
FROM INFORMATION_SCHEMA.TABLES
WHERE TABLE_TYPE = 'VIEW'

INSERT INTO #stmt (stmt)
SELECT 'DROP TABLE ' + QUOTENAME(TABLE_SCHEMA) + '.' + QUOTENAME(TABLE_NAME)
FROM INFORMATION_SCHEMA.TABLES
WHERE TABLE_TYPE = 'BASE TABLE'

INSERT INTO #stmt (stmt)
SELECT 'DROP ' + ROUTINE_TYPE + ' ' + QUOTENAME(ROUTINE_SCHEMA) + '.' + QUOTENAME(ROUTINE_NAME)
FROM INFORMATION_SCHEMA.ROUTINES

INSERT INTO #stmt (stmt)
SELECT 'DROP TYPE ' + QUOTENAME(SCHEMA_NAME(schema_id)) + '.' + QUOTENAME(name) FROM sys.types
WHERE is_user_defined = 1

INSERT INTO #stmt (stmt)
SELECT 'DROP SCHEMA ' + QUOTENAME(SCHEMA_NAME) 
FROM INFORMATION_SCHEMA.SCHEMATA
WHERE SCHEMA_NAME NOT IN (
'db_owner'
,'db_accessadmin'
,'db_securityadmin'
,'db_ddladmin'
,'db_backupoperator'
,'db_datareader'
,'db_datawriter'
,'db_denydatareader'
,'db_denydatawriter'
,'dbo'
,'guest'
,'INFORMATION_SCHEMA'
,'sys')

INSERT INTO #stmt (stmt)
SELECT 'DROP PARTITION SCHEME ' + QUOTENAME(name) FROM sys.partition_schemes

INSERT INTO #stmt (stmt)
SELECT 'DROP PARTITION FUNCTION ' + QUOTENAME(name) FROM sys.partition_functions

SELECT * FROM #stmt ORDER BY ID ASC

DECLARE C CURSOR FAST_FORWARD LOCAL READ_ONLY
FOR SELECT stmt FROM #stmt ORDER BY ID ASC

OPEN C
WHILE (1=1)
BEGIN
   FETCH NEXT FROM C INTO @SQL
   IF @@FETCH_STATUS <> 0 BREAK
   
   EXEC (@SQL)
END

CLOSE C
DEALLOCATE C