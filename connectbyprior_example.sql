-- basic connect by prior example and cte equivalent
drop table family;
create table family(person_id number, name varchar2(50), parent_id number);

insert into family values(1,'Robin',2);
insert into family values(2,'GG',null);
insert into family values(3,'Meg',1);
insert into family values(4,'Eleanor',3);
insert into family values(5,'Benny',3);


select lpad(' ',(level-1)*5) || name
from family
connect by prior person_id = parent_id
start with parent_id is null

with fam(person_id, name) AS 
           (select person_id, name 
              from family
              where parent_id is null
            union all
            select child.person_id, child.name 
              from family child, fam
              where child.parent_id = fam.person_id)
select name from fam;
