DECLARE @database_name sysname = '<database_name, sysname, database_name>'
DECLARE @max_fragmentation_percentage decimal(14, 2) = 15.0
DECLARE @min_density_percentage decimal(14,2) = 90.0
DECLARE @min_index_pages int = 8

		SELECT
   		OBJECT_SCHEMA_NAME([dm_db_index_physical_stats].[object_id], DB_ID(@database_name)) AS schemaName,  
		   OBJECT_NAME([dm_db_index_physical_stats].[object_id], DB_ID(@database_name)) AS objectName,
			[dm_db_index_physical_stats].[index_id],
			[dm_db_index_physical_stats].[object_id],
			index_type = [dm_db_index_physical_stats].[index_type_desc],
			[dm_db_index_physical_stats].[alloc_unit_type_desc],
			partition_number = CAST([dm_db_index_physical_stats].[partition_number] AS varchar(10)),
			[dm_db_index_physical_stats].[avg_record_size_in_bytes],
			current_index_depth = [dm_db_index_physical_stats].[index_depth],
			current_index_level = [dm_db_index_physical_stats].[index_level],
			current_fragment_count = [dm_db_index_physical_stats].[fragment_count],
			current_page_count = [dm_db_index_physical_stats].[page_count],
			current_density_percentage = [dm_db_index_physical_stats].[avg_page_space_used_in_percent],
			current_fragmentation_percentage = [dm_db_index_physical_stats].[avg_fragmentation_in_percent]
		FROM [sys].[dm_db_index_physical_stats](DB_ID(@database_name), NULL, NULL, NULL, 'SAMPLED') AS dm_db_index_physical_stats 
		WHERE 
			( 
				[dm_db_index_physical_stats].[avg_fragmentation_in_percent] >= @max_fragmentation_percentage 
				OR [dm_db_index_physical_stats].[avg_page_space_used_in_percent] < @min_density_percentage
			)
			AND [dm_db_index_physical_stats].[page_count] > 8
			AND [dm_db_index_physical_stats].[page_count] > @min_index_pages
			AND [dm_db_index_physical_stats].[index_id] > 0
			AND ISNULL([dm_db_index_physical_stats].[alloc_unit_type_desc], '') <> 'LOB_DATA'
