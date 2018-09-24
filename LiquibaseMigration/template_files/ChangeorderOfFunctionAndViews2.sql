SET NOCOUNT ON;

DECLARE @type varchar(50) = '$(type)'

; WITH BASE AS (
   SELECT DISTINCT
       b.object_id
     , schemaName = OBJECT_SCHEMA_NAME(b.object_id)
     , objectName = b.name
     , refObjectID = a.depid
     , refSchemaName = OBJECT_SCHEMA_NAME(a.depid)
     , refObjectName = OBJECT_NAME(a.depid)
   FROM  sys.objects b
   LEFT OUTER JOIN sys.sysdepends a 
      ON a.id = b.object_id 
   --left outer JOIN sys.objects c ON a.depid = c.object_id AND c.type IN ('V') 
   -- , USE 'V' for views, 'FN' for functions, 'P' for procedures etc
   where (b.object_id <> a.depid) AND (
         (b.type_desc LIKE '%FUNCTION%' AND @type = 'FUNCTION')
      OR (b.type = 'V' AND @type = 'VIEW')
    )
), CTE AS (
   SELECT
       object_id
     , schemaName
     , objectName
     , refObjectID 
     , refSchemaName
     , refObjectName
     , [level] = CAST(0 AS int)
   FROM BASE
   UNION ALL
   SELECT
       c.object_id
     , c.schemaName
     , c.objectName
     , c.refObjectID 
     , c.refSchemaName
     , c.refObjectName
     , [level] = p.level + 1
   FROM BASE c
   INNER JOIN CTE p
      ON c.refObjectID = p.object_id
), PART AS (
   SELECT 
      CTE.schemaName
    , CTE.objectName
    , CTE.level
    , rn = ROW_NUMBER() OVER (PARTITION BY CTE.object_id ORDER BY level DESC)
   FROM CTE
)
SELECT objectName = PART.schemaName + '.' + PART.objectName
	, tag = '    <include file="'+ PART.schemaName + '.' + PART.objectName + '.sql" relativeToChangelogFile="true" />'
FROM PART
WHERE rn = 1
ORDER BY level
OPTION (MAXRECURSION 0)