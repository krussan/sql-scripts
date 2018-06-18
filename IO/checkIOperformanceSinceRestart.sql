SELECT * FROM (
   SELECT 
      DB_NAME(MF.database_id) AS databasename
    , MF.physical_name
    , size_on_disk_bytes
    , num_of_reads
    , num_of_bytes_read
    , io_stall_read_ms
    , CONVERT(decimal(14,2), CONVERT(float, io_stall_read_ms) / CONVERT(float, num_of_reads)) AS avg_io_stall_read_ms
    , num_of_writes
    , num_of_bytes_written
    , io_stall_write_ms
    , CONVERT(decimal(14,2), CONVERT(float, io_stall_write_ms) / CONVERT(float, num_of_writes)) AS avg_io_stall_write_ms
    , io_stall
    , CONVERT(decimal(14, 2), CONVERT(float, io_stall) / CONVERT(float, ( num_of_reads + num_of_writes))) AS avg_io_stalls
    
   FROM sys.dm_io_virtual_file_stats(NULL,NULL) AS DIVFS
   JOIN sys.master_files AS MF
   ON MF.database_id = DIVFS.database_id
   AND MF.file_id = DIVFS.file_id
) A
ORDER BY avg_io_stall_read_ms DESC