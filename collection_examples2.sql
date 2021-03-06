-- shows the basics of creating a table with column based on varray
-- and selecting from that table

alter table customers drop column addresses;
drop table customers;
drop type addressList;

create type addressList as table of varchar2(50);
/

create table customers(cust_id number, name varchar2(50), interest varchar2(50),
                       addresses addressList) nested table addresses store as addresses_tab;
/

insert into customers values(1, 'Phil', 'Kayaking',addressList('1 The ginnel','Barkington Codsbury','Whimsy Woo'));
insert into customers values(2, 'Meg', 'Baking',null);
insert into customers values(3, 'Arran', 'Building',null);
insert into customers values(4, 'Nicola', 'Soft Kittens',null);
commit;
/

declare
  l_address addressList:=addressList('1 badger close','Scudington');
  type t_returned is table of varchar2(50);
  l_ret t_returned := t_returned();
begin
  update customers set addresses = l_address where cust_id=4;
  for rec in (select c.name, cc.column_value as addr from customers c, table(c.addresses) cc) loop
    dbms_output.put_line(rec.name || ' : ' || rec.addr);
  end loop;
end;  
/

