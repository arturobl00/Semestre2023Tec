-- Monitoreo de uso de CPU y memoria
SHOW GLOBAL STATUS LIKE 'Threads_connected';
SHOW GLOBAL STATUS LIKE 'Threads_running';
SHOW GLOBAL STATUS LIKE 'Innodb_buffer_pool_wait_free';
SHOW GLOBAL VARIABLES LIKE 'innodb_buffer_pool_size';
SHOW GLOBAL VARIABLES LIKE 'max_connections';

-- Monitoreo de espacio en disco
SELECT table_schema AS 'Base de datos', 
       ROUND(SUM(data_length + index_length) / 1024 / 1024, 2) AS 'Tamaño (MB)' 
FROM information_schema.tables 
GROUP BY table_schema;

-- Monitoreo de bloqueos y transacciones
SHOW ENGINE INNODB STATUS;

-- Monitoreo de rendimiento de consultas
SELECT * 
FROM information_schema.query_performance 
WHERE total_latency > 0;

-- Monitoreo de espacio de registro de transacciones
SHOW GLOBAL VARIABLES LIKE 'innodb_log_file_size';
SHOW GLOBAL STATUS LIKE 'Innodb_log_waits';
SHOW GLOBAL STATUS LIKE 'Innodb_os_log_written';
