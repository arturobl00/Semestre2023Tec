/*Comando para mostrar la estructura de una tabla*/
/*En SQL Server manejamos procesos almacenados*/
/*Que se ejecutan con exec*/
exec sp_columns DimDate;
/*Mostrar Bases de datos del sistema*/
exec sp_databases;
/*Mostrar tablas de Base de datos*/
exec sp_tables;

/*Consultas en Tablas*/
/*Consulta General de una tabla*/
Select * from DimEmployee;
/*Consulta por campos*/
Select EmployeeKey, FirstName, Title from DimEmployee; 
/*Consulta por campo personalizado "AS"*/
Select EmployeeKey as "Numero", FirstName as "Nombre",
Title as "Descripcion" from DimEmployee;
/*Consultar por Orden Acendente*/
Select EmployeeKey, FirstName,
Title from DimEmployee Order by FirstName;
/*Consultar por Orden Decendente*/
Select EmployeeKey, FirstName,
Title from DimEmployee Order by FirstName DESC;
/*Consultar Valores Unicos*/
Select DISTINCT FirstName, Title from DimEmployee;

