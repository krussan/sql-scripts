INSERT INTO dbo.DATABASEDEPLOYLOG
  ( [Deploy.StartedAt] ,
  [Deploy.Action] ,
  [Deploy.TriggeredFromPath] ,
  [Deploy.TriggeredOnHostName] ,
  [Package.Version] ,
  [Database.Server] ,
  [Database.Name] ,
  [Database.Username] ,
  [Database.Version]
  )
  VALUES  ( '${timestamp}' ,
  'Completed' ,
  '${project.basedir}' ,
  '${hostname}' ,
  '${project.version}' ,
  @@SERVERNAME ,
  '${database.name}' ,
  '${database.username}' ,
  @@VERSION
  )