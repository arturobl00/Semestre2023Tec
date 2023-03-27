/****** Script for SelectTopNRows command from SSMS  ******/
SELECT TOP (1000) [id]
      ,[nombre]
      ,[edad]
  FROM [pruebas].[dbo].[miTabla] Order by id;

  SELECT TOP (1000) [id]
      ,[nombre]
      ,[edad]
  FROM [pruebas].[dbo].[miTabla];

  insert into miTabla (nombre, edad) values ('Jorge', 19);

  delete from miTabla where id = 3;

  delete from miTabla where id > 2 and id < 7;
