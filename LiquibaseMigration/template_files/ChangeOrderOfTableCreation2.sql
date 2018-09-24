SET NOCOUNT ON;

; WITH base AS (
	select 
        parent_object_id = T.object_id
      , tableSchema = OBJECT_SCHEMA_NAME(T.object_id)
		, tableName = T.name
      , fk.referenced_object_id
      , refTableSchema = OBJECT_SCHEMA_NAME(fk.referenced_object_id)
		, refTableName = OBJECT_NAME(fk.referenced_object_id)
	FROM sys.tables T
   LEFT JOIN sys.foreign_keys as fk
      ON fk.parent_object_id = T.object_id
		
), CTE AS (
SELECT 
   base.parent_object_id
 , base.tableSchema
 , base.tableName
 , base.referenced_object_id
 , base.refTableSchema
 , base.refTableName
 , level = CAST(0 AS int)
FROM base
WHERE base.referenced_object_id IS NULL
OR base.referenced_object_id = base.parent_object_id
UNION ALL
SELECT 
   c.parent_object_id
 , c.tableSchema
 , c.tableName
 , c.referenced_object_id
 , c.refTableSchema
 , c.refTableName
 , level = p.level + 1
FROM base c
INNER JOIN CTE p
   ON c.referenced_object_id = p.parent_object_id
   AND c.referenced_object_id <> c.parent_object_id
), PART AS (
SELECT 
   CTE.tableSchema
 , CTE.tableName
 , CTE.level
 , rn = ROW_NUMBER() OVER (PARTITION BY CTE.parent_object_id ORDER BY CTE.level DESC)
FROM CTE
)
SELECT
	 objectName = tableSchema + '.' + tableName
   , tag = '    <include file="' + tableSchema + '.' + tableName + '.sql" relativeToChangelogFile="true" />'
FROM PART 
WHERE rn = 1
ORDER BY level
OPTION (MAXRECURSION 0)
