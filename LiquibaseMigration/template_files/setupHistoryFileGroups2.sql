--liquibase formatted sql

--changeSet chth:Initial-file-storage-manual-1 endDelimiter:\nGO splitStatements:true stripComments:false runOnChange:false
ALTER DATABASE [@DATABASENAME@] ADD FILEGROUP Data201212
ALTER DATABASE [@DATABASENAME@] ADD FILEGROUP Data201301
ALTER DATABASE [@DATABASENAME@] ADD FILEGROUP Data201302
ALTER DATABASE [@DATABASENAME@] ADD FILEGROUP Data201303
ALTER DATABASE [@DATABASENAME@] ADD FILEGROUP Data201304
ALTER DATABASE [@DATABASENAME@] ADD FILEGROUP Data201305
ALTER DATABASE [@DATABASENAME@] ADD FILEGROUP Data201306
ALTER DATABASE [@DATABASENAME@] ADD FILEGROUP Data201307
ALTER DATABASE [@DATABASENAME@] ADD FILEGROUP Data201308
ALTER DATABASE [@DATABASENAME@] ADD FILEGROUP Data201309
ALTER DATABASE [@DATABASENAME@] ADD FILEGROUP Data201310
ALTER DATABASE [@DATABASENAME@] ADD FILEGROUP Data201311
ALTER DATABASE [@DATABASENAME@] ADD FILEGROUP Data201312
ALTER DATABASE [@DATABASENAME@] ADD FILEGROUP Data201401
ALTER DATABASE [@DATABASENAME@] ADD FILEGROUP Data201402
ALTER DATABASE [@DATABASENAME@] ADD FILEGROUP Data201403
ALTER DATABASE [@DATABASENAME@] ADD FILEGROUP Data201404
ALTER DATABASE [@DATABASENAME@] ADD FILEGROUP Data201405
ALTER DATABASE [@DATABASENAME@] ADD FILEGROUP Data201406
ALTER DATABASE [@DATABASENAME@] ADD FILEGROUP Data201407
ALTER DATABASE [@DATABASENAME@] ADD FILEGROUP Data201408
ALTER DATABASE [@DATABASENAME@] ADD FILEGROUP Data201409
ALTER DATABASE [@DATABASENAME@] ADD FILEGROUP Data201410
ALTER DATABASE [@DATABASENAME@] ADD FILEGROUP Data201411
ALTER DATABASE [@DATABASENAME@] ADD FILEGROUP Data201412
ALTER DATABASE [@DATABASENAME@] ADD FILEGROUP Data201501
ALTER DATABASE [@DATABASENAME@] ADD FILEGROUP Data201502
ALTER DATABASE [@DATABASENAME@] ADD FILEGROUP Data201503
ALTER DATABASE [@DATABASENAME@] ADD FILEGROUP Data201504
ALTER DATABASE [@DATABASENAME@] ADD FILEGROUP Data201505
ALTER DATABASE [@DATABASENAME@] ADD FILEGROUP Data201506
ALTER DATABASE [@DATABASENAME@] ADD FILEGROUP Data201507