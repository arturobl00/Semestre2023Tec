Select * from [HumanResources].[Employee];
Select top 20 loginid, JobTitle, HireDate from
[HumanResources].[Employee];
Select top 20 BusinessEntityID, loginid, JobTitle, HireDate from
[HumanResources].[Employee] Order by BusinessEntityID Desc;
Select * from [Person].[Person];
Select FirstName + ' ' + MiddleName + ' ' + LastName as FullName from
Person.Person;
Select FirstName + ' ' + MiddleName + ' ' + LastName as FullName from
Person.Person;
Select distinct PersonType from Person.Person;
Select * from HumanResources.Employee Where Gender = 'F' and
VacationHours > 30;