-- This requires you to have the database already deployed, maybe using Red Gate SQL Compare or similar.
-- Run this script and replace the Tables/master.xml content with the first column of this result

WITH base AS (
	select 
		tbl.name as [Table_Name]
		,SCHEMA_NAME(tbl.schema_id) AS Table_Schema
		,tbl2.name AS [ReferencedTable]
		,SCHEMA_NAME(tbl2.schema_id) AS [ReferencedTableSchema]
	from  
		sys.tables as tbl
	left join 
		sys.foreign_keys as cstr
		on cstr.parent_object_id=tbl.object_id
	left join 
		sys.foreign_key_columns as fk
		on fk.constraint_object_id=cstr.object_id
	left join 
		sys.columns as cfk
		on fk.parent_column_id = cfk.column_id
		and fk.parent_object_id = cfk.object_id
	left join 
		sys.columns as crk
		on fk.referenced_column_id = crk.column_id
		and fk.referenced_object_id = crk.object_id

	left JOIN 
		sys.tables AS tbl2
		ON fk.referenced_object_id = tbl2.object_id		
    )
,
more AS
(
    SELECT 
          [Table_name]
        , [Table_Schema]
        , [ReferencedTable]
		, [ReferencedTableSchema]
        , 0 AS [level]
        
    FROM 
        base
    WHERE 
        [ReferencedTable] IS NULL
		OR 
		(base.ReferencedTable = base.Table_Name AND base.ReferencedTableSchema = base.Table_Schema)
    
    UNION ALL
    
    SELECT 	      
          b.[Table_name]
        , b.[Table_Schema]
        , b.[ReferencedTable]
		, b.[ReferencedTableSchema]
        , m.[Level] + 1 AS [Level]
        
    FROM 
        base b
    INNER JOIN 
        more m
        ON    b.[ReferencedTable] = m.Table_Name 
        and  NOT (b.ReferencedTable = b.Table_Name AND b.ReferencedTableSchema = b.Table_Schema) -- Fix to handle tables that are referencing themselfs
		AND b.[ReferencedTableSchema] = m.Table_Schema
)
        
SELECT DISTINCT
    '    <include file="'+m.Table_Schema+'.'+m.Table_Name+'.sql" relativeToChangelogFile="true" />', m.level
FROM 
    more m
WHERE NOT EXISTS(SELECT 1 FROM more m2 WHERE m2.level > m.level AND m2.table_name = m.table_name AND m2.Table_Schema = m.Table_Schema)
ORDER BY 
    m.[level]
OPTION (MAXRECURSION 32767);