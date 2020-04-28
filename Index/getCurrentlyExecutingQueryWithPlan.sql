SELECT
   sder.session_id AS [SPID],
   sder.sql_handle as [SQL_Handle],
   sder.plan_handle as [PLAN_Handle],
   sdes.login_name AS [Login],   
   sd.name AS [DBName],
   sder.start_time AS [Start Time],
   sder.status AS [Status],
   sder.command AS [Command],
   CONVERT(xml, '<?query --' + CHAR(13) + REPLACE(REPLACE(sdet.text, '>', '&gt;'), '<', '&lt;') + CHAR(13) + ' --?>') AS [SQL Text],
   sder.percent_complete AS [Pct Cmplt],
   sder.estimated_completion_time AS [Est Cmplt Time],
   sder.wait_type AS [Wait],
   sder.wait_time AS [Wait Time],
   sder.wait_time / 60000 AS [Wait Time min],
   sder.last_wait_type AS [Last Wait],
   sder.cpu_time AS [CPU Time],
   sder.cpu_time / 60000 AS [CPU Time min],   
   sder.total_elapsed_time AS [Total Elpsd Time],
   sder.total_elapsed_time / 60000 AS [Total Elpsd Time min],
   sder.reads AS [Reads],
   sder.writes AS [Writes],
   sder.logical_reads AS [Logical Reads],
   DEQP.query_plan,
   STAT.query_plan as live_query_plan
FROM sys.dm_exec_requests sder WITH (NOLOCK, READUNCOMMITTED)
CROSS APPLY sys.dm_exec_sql_text(sql_handle) AS sdet  
JOIN sys.dm_exec_sessions sdes WITH (NOLOCK, READUNCOMMITTED) on sder.session_id = sdes.session_id
JOIN sys.databases sd  WITH (NOLOCK, READUNCOMMITTED) ON sder.database_id = sd.database_id
OUTER APPLY sys.dm_exec_query_plan(sder.plan_handle) AS DEQP
outer apply sys.dm_exec_query_statistics_xml(sder.session_id) STAT
WHERE
sder.session_id <> @@SPID and sder.session_id > 50
GO



