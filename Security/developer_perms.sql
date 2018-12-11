EXEC sp_MSforeachdb N'IF EXISTS
(
SELECT 1 FROM sys.databases WHERE name = ''?''
AND Is_read_only <> 1 AND owner_sid <> 0x01
)
BEGIN
EXEC (''Use [?]; GRANT Showplan TO [developerrole]'')
END';
GO

GRANT VIEW ANY DEFINITION TO [developerrole]
GO

GRANT VIEW SERVER STATE TO [developerrole]
GO
