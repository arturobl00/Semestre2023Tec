-- Monitoreo de rendimiento de consultas
SELECT TOP 10 qs.execution_count, 
    SUBSTRING(qt.text, (qs.statement_start_offset/2)+1, 
    ((CASE qs.statement_end_offset WHEN -1 THEN DATALENGTH(qt.text) 
    ELSE qs.statement_end_offset END - qs.statement_start_offset)/2) + 1) AS query_text,
    qs.total_logical_reads, qs.total_logical_writes,
    qs.total_worker_time, qs.total_elapsed_time
FROM sys.dm_exec_query_stats AS qs
CROSS APPLY sys.dm_exec_sql_text(qs.sql_handle) AS qt
ORDER BY qs.total_logical_reads DESC;

-- Monitoreo de bloqueos
SELECT blocking.session_id AS bloqueador, 
    blocking.wait_duration_ms, blocking.wait_type, blocking.resource_description,
    blocked.session_id AS bloqueado,
    sqltext.text AS consulta_bloqueador
FROM sys.dm_exec_requests AS blocking
JOIN sys.dm_exec_requests AS blocked
    ON blocking.blocking_session_id = blocked.session_id
CROSS APPLY sys.dm_exec_sql_text(blocking.sql_handle) AS sqltext;

-- Monitoreo de espacio en disco
EXEC sp_MSforeachdb 'USE [?]; 
    SELECT DB_NAME() AS [Base de datos], 
        name AS [Nombre de archivo], 
        size/128.0 AS [Tamaño (MB)], 
        size/128.0 - CAST(FILEPROPERTY(name, ''SpaceUsed'') AS INT)/128.0 AS [Espacio libre (MB)]
    FROM sys.database_files';

-- Monitoreo de uso de memoria
SELECT * FROM sys.dm_os_ring_buffers
WHERE ring_buffer_type = N'RING_BUFFER_RESOURCE_MONITOR';

-- Monitoreo de estadísticas de índices
SELECT OBJECT_NAME(s.object_id) AS [Tabla], 
    i.name AS [Índice], 
    s.auto_created, s.user_created, s.no_recompute,
    s.user_updates, s.last_user_update, s.user_seeks, s.user_scans, s.user_lookups
FROM sys.dm_db_index_usage_stats AS s
JOIN sys.indexes AS i 
    ON s.object_id = i.object_id AND s.index_id = i.index_id;
