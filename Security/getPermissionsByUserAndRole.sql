DECLARE @SQL nvarchar(MAX);

/*
Security Audit Report
1) List all access provisioned to a sql user or windows user/group directly 
2) List all access provisioned to a sql user or windows user/group through a database or application role
3) List all access provisioned to the public role

Columns Returned:
UserName        : SQL or Windows/Active Directory user cccount.  This could also be an Active Directory group.
UserType        : Value will be either ''SQL User'' or ''Windows User''.  This reflects the type of user defined for the 
                  SQL Server user account.
DatabaseUserName: Name of the associated user as defined in the database user account.  The database user may not be the
                  same as the server user.
Role            : The role name.  This will be null if the associated permissions to the object are defined at directly
                  on the user account, otherwise this will be the name of the role that the user is a member of.
PermissionType  : Type of permissions the user/role has on an object. Examples could include CONNECT, EXECUTE, SELECT
                  DELETE, INSERT, ALTER, CONTROL, TAKE OWNERSHIP, VIEW DEFINITION, etc.
                  This value may not be populated for all roles.  Some built in roles have implicit permission
                  definitions.
PermissionState : Reflects the state of the permission type, examples could include GRANT, DENY, etc.
                  This value may not be populated for all roles.  Some built in roles have implicit permission
                  definitions.
ObjectType      : Type of object the user/role is assigned permissions on.  Examples could include USER_TABLE, 
                  SQL_SCALAR_FUNCTION, SQL_INLINE_TABLE_VALUED_FUNCTION, SQL_STORED_PROCEDURE, VIEW, etc.   
                  This value may not be populated for all roles.  Some built in roles have implicit permission
                  definitions.          
ObjectName      : Name of the object that the user/role is assigned permissions on.  
                  This value may not be populated for all roles.  Some built in roles have implicit permission
                  definitions.
ColumnName      : Name of the column of the object that the user/role is assigned permissions on. This value
                  is only populated if the object is a table, view or a table value function.                 
*/

IF OBJECT_ID('tempdb..#permissions') IS NOT NULL DROP TABLE #permissions

CREATE TABLE #permissions (
   databaseName sysname NULL
 , queryType int NULL
 , userName sysname NULL
 , userType sysname NULL
 , databaseUserName sysname NULL
 , roleName sysname NULL
 , permissionType sysname NULL
 , permissionState sysname NULL
 , objectType sysname NULL
 , schemaName sysname NULL
 , objectName sysname NULL
 , columnName sysname NULL
)

DECLARE @dbname sysname

DECLARE C CURSOR FAST_FORWARD READ_ONLY FOR
SELECT name
FROM sys.databases
WHERE owner_sid <> 0x01

OPEN C
FETCH NEXT FROM C INTO @dbname
WHILE @@FETCH_STATUS = 0
BEGIN
	
--List all access provisioned to a sql user or windows user/group directly 
SET @SQL = '
INSERT INTO #permissions
SELECT  
    [Database] = ''' + @dbname + ''',
    queryType = 1,
    [UserName] = CASE princ.[type] 
                    WHEN ''S'' THEN princ.[name]
                    WHEN ''U'' THEN ulogin.[name] COLLATE Latin1_General_CI_AI
                 END,
    [UserType] = CASE princ.[type]
                    WHEN ''S'' THEN ''SQL User''
                    WHEN ''U'' THEN ''Windows User''
                 END,  
    [DatabaseUserName] = princ.[name],       
    [Role] = null,      
    [PermissionType] = perm.[permission_name],       
    [PermissionState] = perm.[state_desc],       
    [ObjectType] = CASE WHEN perm.class = 3 THEN perm.class_desc ELSE obj.type_desc END,
    [SchemaName] = CASE WHEN perm.class = 3 THEN SCHEMA_NAME(perm.major_id) ELSE OBJECT_SCHEMA_NAME(perm.major_id, DB_ID(''' + @dbname + ''')) END ,
    [ObjectName] = CASE WHEN perm.class = 3 THEN NULL ELSE OBJECT_NAME(perm.major_id, DB_ID(''' + @dbname + ''')) END,
    [ColumnName] = col.[name]
FROM    
    --database user
    ' + QUOTENAME(@dbname) + '.sys.database_principals princ  
LEFT JOIN
    --Login accounts
    ' + QUOTENAME(@dbname) + '.sys.login_token ulogin on princ.[sid] = ulogin.[sid]
LEFT JOIN        
    --Permissions
    ' + QUOTENAME(@dbname) + '.sys.database_permissions perm ON perm.[grantee_principal_id] = princ.[principal_id]
LEFT JOIN
    --Table columns
    ' + QUOTENAME(@dbname) + '.sys.columns col ON col.[object_id] = perm.major_id 
                    AND col.[column_id] = perm.[minor_id]
LEFT JOIN
   ' + QUOTENAME(@dbname) + '.sys.objects obj ON perm.[major_id] = obj.[object_id]
WHERE 
    princ.[type] in (''S'',''U'')'

PRINT @SQL
EXEC sp_executesql @SQL

SET @SQL ='
INSERT INTO #permissions
SELECT  
    [Database] = ''' + @dbname + ''',
    queryType = 2,
    [UserName] = CASE memberprinc.[type] 
                    WHEN ''S'' THEN memberprinc.[name]
                    WHEN ''U'' THEN ulogin.[name] COLLATE Latin1_General_CI_AI
                 END,
    [UserType] = CASE memberprinc.[type]
                    WHEN ''S'' THEN ''SQL User''
                    WHEN ''U'' THEN ''Windows User''
                 END, 
    [DatabaseUserName] = memberprinc.[name],   
    [Role] = roleprinc.[name],      
    [PermissionType] = perm.[permission_name],       
    [PermissionState] = perm.[state_desc],       
    [ObjectType] = CASE WHEN perm.class = 3 THEN perm.class_desc ELSE obj.type_desc END,
    [SchemaName] = CASE WHEN perm.class = 3 THEN SCHEMA_NAME(perm.major_id) ELSE OBJECT_SCHEMA_NAME(perm.major_id, DB_ID(''' + @dbname + ''')) END ,
    [ObjectName] = CASE WHEN perm.class = 3 THEN NULL ELSE OBJECT_NAME(perm.major_id, DB_ID(''' + @dbname + ''')) END,
    [ColumnName] = col.[name]
FROM    
    --Role/member associations
    ' + QUOTENAME(@dbname) + '.sys.database_role_members members
INNER JOIN
    --Roles
    ' + QUOTENAME(@dbname) + '.sys.database_principals roleprinc ON roleprinc.[principal_id] = members.[role_principal_id]
INNER JOIN
    --Role members (database users)
    ' + QUOTENAME(@dbname) + '.sys.database_principals memberprinc ON memberprinc.[principal_id] = members.[member_principal_id]
LEFT JOIN
    --Login accounts
    ' + QUOTENAME(@dbname) + '.sys.login_token ulogin ON memberprinc.[sid] = ulogin.[sid]
LEFT JOIN        
    --Permissions
    ' + QUOTENAME(@dbname) + '.sys.database_permissions perm ON perm.[grantee_principal_id] = roleprinc.[principal_id]
LEFT JOIN
    --Table columns
    ' + QUOTENAME(@dbname) + '.sys.columns col ON col.[object_id] = perm.major_id 
                    AND col.[column_id] = perm.[minor_id]
LEFT JOIN
    ' + QUOTENAME(@dbname) + '.sys.objects obj ON perm.[major_id] = obj.[object_id]'

   PRINT @SQL
EXEC sp_executesql @SQL

--List all access provisioned to the public role, which everyone gets by default
SET @SQL = '
INSERT INTO #permissions
SELECT  
    [Database] = ''' + @dbname + ''',
    queryType = 3,
    [UserName] = ''{All Users}'',
    [UserType] = ''{All Users}'', 
    [DatabaseUserName] = ''{All Users}'',       
    [Role] = roleprinc.[name],      
    [PermissionType] = perm.[permission_name],       
    [PermissionState] = perm.[state_desc],       
    [ObjectType] = CASE WHEN perm.class = 3 THEN perm.class_desc ELSE obj.type_desc END,
    [SchemaName] = CASE WHEN perm.class = 3 THEN SCHEMA_NAME(perm.major_id) ELSE OBJECT_SCHEMA_NAME(perm.major_id, DB_ID(''' + @dbname + ''')) END ,
    [ObjectName] = CASE WHEN perm.class = 3 THEN NULL ELSE OBJECT_NAME(perm.major_id, DB_ID(''' + @dbname + ''')) END,
    [ColumnName] = col.[name]
FROM    
    --Roles
    ' + QUOTENAME(@dbname) + '.sys.database_principals roleprinc
LEFT JOIN        
    --Role permissions
    ' + QUOTENAME(@dbname) + '.sys.database_permissions perm ON perm.[grantee_principal_id] = roleprinc.[principal_id]
LEFT JOIN
    --Table columns
    ' + QUOTENAME(@dbname) + '.sys.columns col on col.[object_id] = perm.major_id 
                    AND col.[column_id] = perm.[minor_id]                   
JOIN 
    --All objects   
    ' + QUOTENAME(@dbname) + '.sys.objects obj ON obj.[object_id] = perm.[major_id]
WHERE
    --Only roles
    roleprinc.[type] = ''R'' AND
    --Only public role
    roleprinc.[name] = ''public'' AND
    --Only objects of ours, not the MS objects
    obj.is_ms_shipped = 0'

EXEC sp_executesql @SQL


   FETCH NEXT FROM C INTO @dbname
END
CLOSE C
DEALLOCATE C



--List all access provisioned to a sql user or windows user/group through a database or application role
DECLARE @userName sysname = '<user_name, sysname, user_name>'
 
SELECT *
FROM #permissions
WHERE @username IN (username,  databaseUserName)
ORDER BY
   databaseName,
    userName,
    objectName,
    columnName,
    permissionType,
    permissionState,
    objectType

