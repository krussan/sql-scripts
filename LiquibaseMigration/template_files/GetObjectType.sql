--:SETVAR collation SQL_Latin1_General_CP1_CI_AS

SET NOCOUNT ON;
GO

IF OBJECT_ID('tempdb..#cte') IS NOT NULL DROP TABLE #cte
IF OBJECT_ID('tempdb..#tbl') IS NOT NULL DROP TABLE #tbl
IF OBJECT_ID('tempdb..#par') IS NOT NULL DROP TABLE #par

   SELECT object_id = OBJECT_ID(SPECIFIC_SCHEMA + '.' + SPECIFIC_NAME)
   , params= PARAMETER_NAME + ' ' 
      + CASE 
         WHEN DATA_TYPE = 'table type' THEN 
            CASE WHEN USER_DEFINED_TYPE_CATALOG = DB_NAME() THEN '' 
            ELSE QUOTENAME(USER_DEFINED_TYPE_CATALOG) + '.'
            END + QUOTENAME(USER_DEFINED_TYPE_SCHEMA) + '.' + QUOTENAME(USER_DEFINED_TYPE_NAME)
			+ ' READONLY'
         ELSE DATA_TYPE
        END
      + CASE
         WHEN DATA_TYPE LIKE '%char%' AND CHARACTER_MAXIMUM_LENGTH = - 1 THEN '(MAX)'
         WHEN DATA_TYPE LIKE '%char%' THEN '(' + CONVERT(varchar(10), CHARACTER_MAXIMUM_LENGTH) + ')'
         WHEN DATA_TYPE IN ('decimal', 'numeric') THEN '(' + CONVERT(varchar(10), NUMERIC_PRECISION) + ',' + CONVERT(varchar(10),NUMERIC_SCALE) + ')'
         ELSE ''
        END
   INTO #cte
   FROM INFORMATION_SCHEMA.PARAMETERS
   WHERE 1=1
   AND ORDINAL_POSITION > 0

   SELECT object_id = OBJECT_ID(TABLE_SCHEMA + '.' + TABLE_NAME)
   , params = QUOTENAME(COLUMN_NAME) + ' ' + DATA_TYPE +
        CASE 
         WHEN DATA_TYPE LIKE '%char%' AND CHARACTER_MAXIMUM_LENGTH = - 1 THEN '(MAX)'
         WHEN DATA_TYPE LIKE '%char%' THEN '(' + CONVERT(varchar(10), CHARACTER_MAXIMUM_LENGTH) + ')'
         WHEN DATA_TYPE IN ('decimal', 'numeric') THEN '(' + CONVERT(varchar(10), NUMERIC_PRECISION) + ',' + CONVERT(varchar(10),NUMERIC_SCALE) + ')'
         ELSE ''
        END 
   INTO #tbl
   FROM INFORMATION_SCHEMA.ROUTINE_COLUMNS 

   SELECT
      schemaName = OBJECT_SCHEMA_NAME(object_id),
      objectName = name,
      fullName = CONVERT(nvarchar(100), OBJECT_SCHEMA_NAME(object_id) + '.' + name) COLLATE $(collation), 
      fullQuoted = CONVERT(nvarchar(100), QUOTENAME(OBJECT_SCHEMA_NAME(object_id)) + '.' + QUOTENAME(name)) COLLATE $(collation), 
      [type] = CONVERT(nvarchar(2), LTRIM(RTRIM([type]))) COLLATE $(collation),
      params = (
         SELECT params = STUFF(
	      (SELECT N',' + params as [text()] 
	      FROM (
	         SELECT params FROM #cte CTE
            WHERE CTE.object_id = O.object_id
         ) AS importColumns
         FOR XML PATH('')),1,1,N'')
      ),
      tblParams = (
         SELECT params = STUFF(
	      (SELECT N',' + params as [text()] 
	      FROM (
	         SELECT params FROM #tbl TBL
            WHERE TBL.object_id = O.object_id
         ) AS importColumns
         FOR XML PATH('')),1,1,N'')
      ) COLLATE $(collation)
   INTO #par
   FROM sys.objects O
   WHERE type IN ('FN', 'IF', 'P', 'TF', 'V')


SELECT PAR.schemaName
   , objectName
   , PAR.fullName
   , PAR.type  
   , PAR.params
   , creationScript = 
      N'IF OBJECT_ID(''' + fullName  + N''', ''' + PAR.type + N''') IS NULL EXEC(''' + 
      CONVERT(nvarchar(MAX), 
      CASE 
         WHEN [type] = 'IF' THEN 'CREATE FUNCTION ' + fullQuoted + '(' + COALESCE(params, '') + ') RETURNS TABLE AS RETURN (SELECT ret = 1)'
         WHEN [type] = 'P'  THEN 'CREATE PROCEDURE ' + fullQuoted + ' ' + COALESCE(params, '') + ' AS BEGIN SELECT ret = 1 END'
         WHEN [type] = 'FN' THEN 'CREATE FUNCTION ' + fullQuoted + '(' + COALESCE(params, '') + ') RETURNS int AS BEGIN RETURN 1 END'
         WHEN [type] = 'TF' THEN 'CREATE FUNCTION ' + fullQuoted + '(' + COALESCE(params, '') + ') RETURNS @tab TABLE (' + COALESCE(tblParams, '') + ') AS BEGIN RETURN END'
         WHEN [type] = 'V'  THEN 'CREATE VIEW ' + fullQuoted + ' AS SELECT initView = 1'
      END) + N''')'
   , regex = 
         CASE
            WHEN [type] = 'P' THEN '^\s*CREATE\s*PROC(EDURE)?'
            WHEN [type] = 'V' THEN '^\s*CREATE\s*VIEW'
            ELSE '^\s*CREATE\s*FUNCTION'
         END
   , folder=
         CASE
            WHEN [type] = 'P' THEN 'Stored procedures'
            WHEN [type] = 'V' THEN 'Views'
            ELSE 'Functions'
         END
   , replacement =
         CASE
            WHEN [type] = 'P' THEN 'ALTER PROCEDURE'
            WHEN [type] = 'V' THEN 'ALTER VIEW'
            ELSE 'ALTER FUNCTION'
         END
	, username = 
		 CASE
            WHEN [type] = 'P' THEN 'proc'
            WHEN [type] = 'V' THEN 'view'
            ELSE 'func'
         END
FROM #par PAR
--WHERE PAR.objectName = '_xp_assetcalcdeprec'