-- 
drop table customers;
create table customers(cust_id number, name varchar2(50), interest varchar2(50),strength number);

insert into customers values(1, 'Phil', 'Kayaking',50);
insert into customers values(2, 'Meg', 'Baking',60);
insert into customers values(3, 'Arran', 'Building',100);
insert into customers values(4, 'James', 'Soft Kittens',12);
insert into customers values(5, 'Gav', 'Kayaking',60);
insert into customers values(6, 'EJ', 'Kayaking',1000);
insert into customers values(7, 'Nicola', 'Soft Kittens',14);
commit;

select name,interest,row_number() over(order by cust_id) as order_col
from customers;

select name,interest,row_number() over(partition by interest order by cust_id) as order_col
from customers;

select name, interest, strength, sum(strength) over (partition by interest order by cust_id) as sum_str
from customers

select name, interest, strength, sum(strength) over (partition by interest order by cust_id) as sum_str
     , lag(strength) over (partition by interest order by cust_id) as prev_str
     , lead(strength) over (partition by interest order by cust_id) as next_str
from customers


