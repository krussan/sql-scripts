SET NOCOUNT ON
GO

SELECT fullName = OBJECT_SCHEMA_NAME(parent_object_id) + '.' + OBJECT_NAME(parent_object_id) FROM sys.check_constraints