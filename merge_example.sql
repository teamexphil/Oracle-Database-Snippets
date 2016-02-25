drop table customers;

create table customers(cust_id number, name varchar2(50), interest varchar2(50));

insert into customers values(1, 'Phil', 'Kayaking');
insert into customers values(2, 'Meg', 'Baking');
insert into customers values(3, 'Arran', 'Building');
insert into customers values(4, 'Nicola', 'Soft Kittens');

merge into customers c
  using (select 1 as cust_id, 'Phil' as name, 'Baby Jake' as interest from dual) new_c
  on (new_c.cust_id =  c.cust_id)
  when matched then update set c.interest = new_c.interest
  when not matched then insert (c.cust_id,c.name,c.interest) values (new_c.cust_id,new_c.name,new_c.interest);
  
commit;
