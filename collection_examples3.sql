-- This covers returning data from a procedure using object and table types and the select table keyword

drop table customers;
create table customers(cust_id number, name varchar2(50), interest varchar2(50));

insert into customers values(1, 'Phil', 'Kayaking');
insert into customers values(2, 'Meg', 'Baking');
insert into customers values(3, 'Arran', 'Building');
insert into customers values(4, 'Nicola', 'Soft Kittens');
commit;

create or replace type cust_type as object(cust_id number, name varchar2(50), interest varchar2(50));
create or replace type cust_tab as table of cust_type;

create or replace function getCust return cust_tab as
  ret_val cust_tab;
begin
  select cust_type(cust_id,name,interest)
  bulk collect into ret_val
  from customers;
  
  return ret_val;
end;
/

select * from table(getCust);
