Select * from Production.Product;

/*Mostrar aquellos productos que tengas un identificador CA*/
Select Name, ProductNumber from Production.Product 
where ProductNumber Like 'CA%';

/*Funciones con Operaciones Count, AVG y Sum*/
Select COUNT(ListPrice) from Production.Product
where ListPrice < 10
Select MAX(ListPrice) from Production.Product;
Select MIN(ListPrice) from Production.Product;
Select AVG(ListPrice) from Production.Product;

