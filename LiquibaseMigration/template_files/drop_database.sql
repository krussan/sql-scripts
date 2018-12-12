ALTER DATABASE $(databasename) SET SINGLE_USER
GO

DROP DATABASE $(databasename)
GO

CREATE DATABASE $(databasename)
ON  PRIMARY 
( NAME = N'$(databasename)', FILENAME = N'$(datapath)$(databasename).mdf' , SIZE = 5MB , MAXSIZE = UNLIMITED, FILEGROWTH = 5MB )
 LOG ON 
( NAME = N'$(databasename)_log', FILENAME = N'$(logpath)$(databasename).LDF' , SIZE = 5MB , MAXSIZE = 2048GB , FILEGROWTH = 10%)
GO

