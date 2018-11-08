  IF OBJECT_ID('dbo.DATABASEDEPLOYLOG') IS NULL
  CREATE TABLE dbo.DATABASEDEPLOYLOG (
  [Deploy.StartedAt] DATETIME2(0) NOT NULL
  , [Deploy.Action] VARCHAR(100)
  , [Deploy.ActionOccuredOn] DATETIME2 NOT NULL CONSTRAINT [Def_Deploy.ActionOccuredOn] DEFAULT (SYSDATETIME())
  , [Deploy.TriggeredFromPath] VARCHAR(4000)
  , [Deploy.TriggeredOnHostName] VARCHAR(100)
  , [Package.Version] VARCHAR(500)
  , [Package.BuildDate] DATETIME2(0)
  , [Package.Binary] VARBINARY(max)
  , [Database.Server] VARCHAR(500)
  , [Database.Name] VARCHAR(100)
  , [Database.Username] VARCHAR(100)
  , [Database.Version] VARCHAR(max)
  );

  IF '${project.version}' <> '1.0.0-snapshot'
	  IF EXISTS (
	   SELECT 1
	   FROM dbo.DATABASEDEPLOYLOG
	   WHERE [Package.Version] NOT LIKE '%.[0-9][0-9][0-9]'
	   AND [Package.Version] NOT LIKE '%.[0-9][0-9]'
	   AND CONVERT(int, SUBSTRING(REPLACE('${project.version}', 'dev-unstable-', ''), 1, CHARINDEX('.', REPLACE('${project.version}', 'dev-unstable-', '')) - 1))
		 < CONVERT(int, SUBSTRING(REPLACE([Package.Version], 'dev-unstable-', ''), 1, CHARINDEX('.', REPLACE([Package.Version], 'dev-unstable-', '')) - 1))
	  ) RAISERROR ('The version of this package is lower than the one already installed.', 18, 1)

	  INSERT INTO dbo.DATABASEDEPLOYLOG
	  ( [Deploy.StartedAt] ,
	  [Deploy.Action] ,
	  [Deploy.TriggeredFromPath] ,
	  [Deploy.TriggeredOnHostName] ,
	  [Package.Version] ,
	  --[Package.BuildDate] ,
	  --[Package.Binary] ,
	  [Database.Server] ,
	  [Database.Name] ,
	  [Database.Username] ,
	  [Database.Version]
	  )
	  VALUES  ( '${timestamp}' ,
	  'Started' ,
	  '${project.basedir}' ,
	  '${hostname}' ,
	  '${project.version}' ,
	  @@SERVERNAME ,
	  '${database.name}' ,
	  '${database.username}' ,
	  @@VERSION
	  );
