:SETVAR LinkedServerName A950NDX
:SETVAR Server localhost
EXEC master.dbo.sp_addlinkedserver @server = N'$(LinkedServerName)', @srvproduct=N'MSSQL', @provider=N'SQLNCLI', @provstr=N'PROVIDER=SQLOLEDB;SERVER=$(Server)'
EXEC master.dbo.sp_addlinkedsrvlogin @rmtsrvname=N'$(LinkedServerName)',@useself=N'True',@locallogin=NULL,@rmtuser=NULL,@rmtpassword=NULL
GO