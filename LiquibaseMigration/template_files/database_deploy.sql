--liquibase formatted sql

--changeSet chth:Initial-@DATABASENAME@-1 endDelimiter:\nGO splitStatements:true stripComments:false runOnChange:false
ALTER DATABASE [@DATABASENAME@]
SET TRUSTWORTHY ON;
GO

ALTER DATABASE [@DATABASENAME@]
SET DB_CHAINING ON;
GO
