Select Firstname, Lastname, Case persontype 
when 'IN' then 'Individual Customer'
when 'EM' then 'Employee'
else 'Unknown Person' 
end TipodeContancto from person.person;

Select Firstname, Lastname, persontype
from person.person;