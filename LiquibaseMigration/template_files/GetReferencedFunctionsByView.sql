SET NOCOUNT ON;
GO

SELECT DISTINCT
   schemaName = OBJECT_SCHEMA_NAME(RF.object_id)
 , objectName = RF.name
 , fullName = OBJECT_SCHEMA_NAME(RF.object_id) + '.' + RF.name
FROM sys.sql_expression_dependencies D
INNER JOIN sys.objects O  ON D.referencing_id = O.object_id
INNER JOIN sys.objects RF ON D.referenced_id = RF.object_id
WHERE 1=1
AND O.type = 'V'
AND RF.type IN ('FN', 'IF', 'P', 'TF', 'FS', 'FT', 'AF') 