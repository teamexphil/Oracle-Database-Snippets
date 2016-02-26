
drop table customers;
create table customers(cust_id number, name varchar2(50), interest varchar2(50));

insert into customers values(1, 'Phil', 'Kayaking');
insert into customers values(2, 'Meg', 'Baking');
insert into customers values(3, 'Arran', 'Building');
insert into customers values(4, 'Nicola', 'Soft Kittens');
commit;

-- Associative array, it's like a hash so you can use different types as the key value as well e.g. varchar2
declare
  type t_customer_names is table of varchar2(50) index by binary_integer;
  l_customer_names t_customer_names;
begin
  l_customer_names(1):='Phil';
  l_customer_names(2):='Carl';
  l_customer_names(3):='Arran';
  
  for i in 1..l_customer_names.last loop
    dbms_output.put_line('Customer name: ' || l_customer_names(i));
  end loop;  
end;
/

--Associative array - can use rowtype and bulk collect for fill the collection
declare
  cursor getCustomers is
  select cust_id,name,interest
  from customers;
  
  type t_customer is table of customers%rowtype;
  l_customers t_customer;
begin  
  open getCustomers;
  fetch getCustomers bulk collect into l_customers;
  close getCustomers;
  
  dbms_output.put_line('Customer count: ' || l_customers.count);
  
  for i in l_customers.first..l_customers.last loop
    dbms_output.put_line('Customer name and interest: ' || l_customers(i).name || ':' || l_customers(i).interest);
  end loop;   
end;
/

-- nested tables can be used to store in database tables as well. Sequential number as key
declare 
  type t_customer_address is table of varchar2(50);
  l_customer_address t_customer_address;
begin
  dbms_output.put_line('Address in nested tables...');
  l_customer_address := t_customer_address('21 Sid Street','Bognor West','Wales','UK');   
  for i in l_customer_address.first..l_customer_address.last loop
    dbms_output.put_line(l_customer_address(i));
  end loop;
end;
/
 
-- varrays holds a fixed number of records which can be extended at runtime . 
-- Sequential number as key. Can be used in sql/database tables but not as flexible as nested tables
declare 
  type t_customer_address is varray(10) of varchar2(50);
  l_customer_address t_customer_address := t_customer_address('21 Sid Street','Bognor West','Wales','UK');
begin  
  dbms_output.put_line('Address in varray...');
  for i in l_customer_address.first..l_customer_address.last loop
    dbms_output.put_line(l_customer_address(i));
  end loop;
  l_customer_address.extend; -- need to call extend to add additional data
  l_customer_address(5) := 'The World';
  dbms_output.put_line(l_customer_address(5));  
end;
/

