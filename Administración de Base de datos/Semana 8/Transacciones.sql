SELECT * FROM [dbo].[miTabla];
begin transaction
delete from miTabla;
update mitabla set edad = 40; 
Rollback transaction;
commit transaction;