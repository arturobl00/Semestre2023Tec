<<<<<<< HEAD
/*28/02/2023*/
/*Selecciona todo los campos de la tabla HumanResources.Employee*/
Select * from HumanResources.Employee;
Select * from [HumanResources].[Employee];
/*Selecciona solo los campos Loginid, JobTitle, HireDate*/
Select Loginid, JobTitle, HireDate from 
HumanResources.Employee;
/*Selecciona solo los primeros 20 registros*/
Select top 20 loginid, JobTitle, HireDate from [HumanResources].[Employee]
/*Selecciona todos los campos de la tabla Person.Person*/
Select * from Person.Person
/*Selecciona solo el Primer nombre y Apellido de la tabla Person.Person*/
Select FirstName, LastName from person.Person
/*Concatena dos campos y nombralos como Fullname*/
Select FirstName + ' ' + LastName as Fullname from person.Person
/*Muestra todo los campos para buscar donde usar distinc*/
Select * from Person.Person
/*Muestra los registros unicos de persontype*/
Select distinct PersonType from Person.Person;
/*Muestra EmailPromotion unicos ordenados por numero de emails*/
Select distinct EmailPromotion, PersonType from 
Person.Person order by EmailPromotion;
/*Muestra los registros de la tabla HumanResources.Employee*/
Select * from HumanResources.Employee;
/*Mustra los Registros de la tabla HumanResources.Employee que Sean
Mujeres Solteras*/
Select * from HumanResources.Employee Where MaritalStatus = 'S'
and Gender = 'F';
/*Seleccionar que empleados han tenido 30 horas de vacaciones*/
Select * from HumanResources.Employee
where VacationHours = 30;
/*Seleccionar que empleados han tenido menos de 30 horas de vacaciones*/
Select * from HumanResources.Employee
where VacationHours < 30;




=======
/*28/02/2023*/
/*Selecciona todo los campos de la tabla HumanResources.Employee*/
Select * from HumanResources.Employee;
Select * from [HumanResources].[Employee];
/*Selecciona solo los campos Loginid, JobTitle, HireDate*/
Select Loginid, JobTitle, HireDate from 
HumanResources.Employee;
/*Selecciona solo los primeros 20 registros*/
Select top 20 loginid, JobTitle, HireDate from [HumanResources].[Employee]
/*Selecciona todos los campos de la tabla Person.Person*/
Select * from Person.Person
/*Selecciona solo el Primer nombre y Apellido de la tabla Person.Person*/
Select FirstName, LastName from person.Person
/*Concatena dos campos y nombralos como Fullname*/
Select FirstName + ' ' + LastName as Fullname from person.Person
/*Muestra todo los campos para buscar donde usar distinc*/
Select * from Person.Person
/*Muestra los registros unicos de persontype*/
Select distinct PersonType from Person.Person;
/*Muestra EmailPromotion unicos ordenados por numero de emails*/
Select distinct EmailPromotion, PersonType from 
Person.Person order by EmailPromotion;
/*Muestra los registros de la tabla HumanResources.Employee*/
Select * from HumanResources.Employee;
/*Mustra los Registros de la tabla HumanResources.Employee que Sean
Mujeres Solteras*/
Select * from HumanResources.Employee Where MaritalStatus = 'S'
and Gender = 'F';
/*Seleccionar que empleados han tenido 30 horas de vacaciones*/
Select * from HumanResources.Employee
where VacationHours = 30;
/*Seleccionar que empleados han tenido menos de 30 horas de vacaciones*/
Select * from HumanResources.Employee
where VacationHours < 30;




>>>>>>> 72a4f800affe3cc9b018b000919e63433ac8a9fb
