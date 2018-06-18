IF OBJECT_ID('tempdb..#t') IS NOT NULL DROP TABLE #t

CREATE table #t
(
  name nvarchar(128),
  rows varchar(50),
  reserved varchar(50),
  data varchar(50),
  index_size varchar(50),
  unused varchar(50)
)

declare @id nvarchar(128)
declare c cursor for
select QUOTENAME(OBJECT_SCHEMA_NAME(id)) + '.' + QUOTENAME(name)  from sysobjects where xtype='U'

open c
fetch c into @id

while @@fetch_status = 0 begin

  insert into #t
  exec sp_spaceused @id

  fetch c into @id
end

close c
deallocate c

; WITH CTE AS (
   select *
    , CONVERT(int, LEFT(reserved, LEN(reserved) - 3)) AS reservedInt
    , CONVERT(int, LEFT(data, LEN(data) - 3)) AS dataInt
    , CONVERT(int, LEFT(index_size, LEN(index_size) - 3)) AS indexSizeInt
   from #t
)
SELECT *
 , CASE WHEN dataInt = 0 THEN 0 ELSE CONVERT(float, indexSizeInt) / CONVERT(float, dataInt) END AS indexDataRatio
FROM CTE
--WHERE name = 'TradeReportRepository'
ORDER BY 10 DESC

--DROP table #t


SELECT * FROM #t