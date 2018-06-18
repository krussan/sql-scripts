SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
GO

SELECT 
   spid
 , blockedBy = blocked
 , cmd
 , userName = loginame
 , lastwaittype
 , S.last_worker_time
 , S.last_logical_reads
 , S.last_logical_writes
 , S.last_elapsed_time
 , CONVERT(xml, '<?query --' + CHAR(13) + REPLACE(REPLACE(TT.text, '>', '&gt;'), '<', '&lt;') + CHAR(13) + ' --?>')
FROM master.sys.sysprocesses P WITH (NOLOCK, READUNCOMMITTED)
CROSS APPLY sys.dm_exec_sql_text(sql_handle) TT 
LEFT JOIN sys.dm_exec_query_stats S WITH (NOLOCK, READUNCOMMITTED)
   ON S.sql_handle = P.sql_handle
WHERE P.loginame <> 'sytemuser'
AND cmd <> 'AWAITING COMMAND'
AND spid <> @@SPID
ORDER BY S.last_logical_reads DESC