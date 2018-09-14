SET NOCOUNT ON;

; WITH base AS (
   SELECT A.assembly_id, name, AR.referenced_assembly_id
   FROM sys.assemblies A
   LEFT JOIN sys.assembly_references AR ON AR.assembly_id = A.assembly_id
   WHERE A.is_user_defined = 1
), CTE AS (
   SELECT 
      base.assembly_id
    , base.name
    , level = CAST(0 AS int)
   FROM base
   WHERE base.referenced_assembly_id IS NULL
   UNION ALL
   SELECT 
      c.assembly_id
    , c.name
    , level = p.level + 1
   FROM base c
   INNER JOIN CTE p
      ON c.referenced_assembly_id = p.assembly_id

), PART AS (
   SELECT 
      assembly_id
    , name
    , level
    , rn = ROW_NUMBER() OVER (PARTITION BY CTE.assembly_id ORDER BY CTE.level DESC)
   FROM CTE
)
SELECT '    <include file="' + name + '.sql" relativeToChangelogFile="true" />'
FROM PART
WHERE rn = 1
ORDER BY level
OPTION (MAXRECURSION 0)