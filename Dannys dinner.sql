CREATE SCHEMA dannys_diner;
SET search_path = dannys_diner;

CREATE TABLE sales (
  "customer_id" VARCHAR(1),
  "order_date" DATE,
  "product_id" INTEGER
);

INSERT INTO sales
  ("customer_id", "order_date", "product_id")
VALUES
  ('A', '2021-01-01', '1'),
  ('A', '2021-01-01', '2'),
  ('A', '2021-01-07', '2'),
  ('A', '2021-01-10', '3'),
  ('A', '2021-01-11', '3'),
  ('A', '2021-01-11', '3'),
  ('B', '2021-01-01', '2'),
  ('B', '2021-01-02', '2'),
  ('B', '2021-01-04', '1'),
  ('B', '2021-01-11', '1'),
  ('B', '2021-01-16', '3'),
  ('B', '2021-02-01', '3'),
  ('C', '2021-01-01', '3'),
  ('C', '2021-01-01', '3'),
  ('C', '2021-01-07', '3');
 

CREATE TABLE menu (
  "product_id" INTEGER,
  "product_name" VARCHAR(5),
  "price" INTEGER
);

INSERT INTO menu
  ("product_id", "product_name", "price")
VALUES
  ('1', 'sushi', '10'),
  ('2', 'curry', '15'),
  ('3', 'ramen', '12');
  

CREATE TABLE members (
  "customer_id" VARCHAR(1),
  "join_date" DATE
);

INSERT INTO members
  ("customer_id", "join_date")
VALUES
  ('A', '2021-01-07'),
  ('B', '2021-01-09');
  
---1.What is the total amount each customer spent at the restaurant?
SELECT customer_id, sum(price) from sales
join menu 
using(product_id)
group by customer_id;


---2.How many days has each customer visited the restaurant?
Select customer_id, count(distinct(extract(day from order_date)))
from sales
group by customer_id;


---3.What was the first item from the menu purchased by each customer?
with my_cte as(select m.product_id,product_name,price,customer_id,order_date,s.product_id,
			  dense_rank() over (partition by(customer_id) order by order_date asc) as ranks
			  from sales as s
			  join menu as m
			  on m.product_id = s.product_id)
select customer_id, product_name from my_cte
where ranks=1
group by customer_id,product_name;

---4.What is the most purchased item on the menu and how many times was it purchased by all customers?
Select product_name, count(order_date) as times_purchsed from menu
join sales
using(product_id)
group by product_name
limit 1;

---5.Which item was the most popular for each customer?
select product_name, count(m.product_id) as order_times, customer_id 
from sales as s
join menu as m
on s.product_id=m.product_id 
group by product_name, customer_id
order by customer_id,order_times desc;

---6.Which item was purchased first by the customer after they became a member?
With cte as
(Select  S.customer_id,M.product_name, s.order_date, mem.join_date,
	Dense_rank() OVER (Partition by S.Customer_id Order by S.Order_date) as Ranks
From Sales S
Join Menu M
ON m.product_id = s.product_id
JOIN Members Mem
ON Mem.Customer_id = S.customer_id
Where S.order_date >= Mem.join_date  
)
Select *
From cte
Where Ranks = 1

---7.Which item was purchased just before the customer became a member?
With cte as
(Select  S.customer_id,M.product_name, s.order_date, mem.join_date,
	Dense_rank() OVER (Partition by S.Customer_id Order by S.Order_date) as Ranks
From Sales S
Join Menu M
ON m.product_id = s.product_id
JOIN Members Mem
ON Mem.Customer_id = S.customer_id
Where S.order_date < Mem.join_date  
)
Select *
From cte
where ranks = 1

---8.What is the total items and amount spent for each member before they became a member?
With cte as
(Select count(M.product_id) as total_item , sum(price) as amount_spent, Mem.customer_id
From Sales S
Join Menu M
ON m.product_id = s.product_id
JOIN Members Mem
ON Mem.Customer_id = S.customer_id
Where S.order_date < Mem.join_date
Group by Mem.Customer_id
)
Select *
From cte;
Select * from menu
---9.	If each $1 spent equates to 10 points and sushi has a 2x points multiplier 
--- how many points would each customer have?
WITH price_points AS
 (SELECT *, 
 CASE WHEN product_id = 1 THEN price * 20
 ELSE price * 10
  END AS points
 FROM menu)
SELECT s.customer_id, SUM(p.points) AS total_points
FROM price_points AS p
JOIN sales AS s
 ON p.product_id = s.product_id
GROUP BY s.customer_id

---10.	In the first week after a customer joins the program (including their join date) 
---they earn 2x points on all items, not just sushi 
--- how many points do customer A and B have at the end of January?
WITH points AS (SELECT *,
      CASE
        WHEN s.order_date - mem.join_date >= 0 and s.order_date - mem.join_date <= 6 THEN price * 10 * 2
		WHEN product_name = 'sushi' THEN price * 10 * 2
        ELSE price * 10
      END as bonus_points
FROM sales s
JOIN menu m
USING (product_id)
JOIN members mem
USING (customer_id)
WHERE EXTRACT(MONTH FROM order_date) = 1 AND EXTRACT(YEAR FROM order_date) = 2021)
SELECT customer_id, SUM(bonus_points) AS points_total FROM points
GROUP BY customer_id;



















