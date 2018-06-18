ALTER DATABASE [<database_name, sysname, database_name>] 
SET ALLOW_SNAPSHOT_ISOLATION ON 
GO

ALTER DATABASE [<database_name, sysname, database_name>] 
SET READ_COMMITTED_SNAPSHOT ON 
GO

/*
In procedure that need to lock tables to perform update you need to set the following to avoid errors if blocking situations arise:

  SET TRANSACTION ISOLATION LEVEL READ COMMITTED; 

To verify snapshot isolation state look at sys.databases:

SELECT snapshot_isolation_state, snapshot_isolation_state_desc 
FROM sys.databases
WHERE name = '[<database_name, sysname, database_name>]'

*/