USE DannysDinner
--Getting all the dataset
SELECT *
FROM members

SELECT *
FROM menu

SELECT *
FROM sales

--What is the total amount each customer spent at the restaurant
SELECT s.customer_id, SUM(m.price) AS total_amount
FROM sales s
JOIN menu m
ON s.product_id = m.product_id
GROUP BY s.customer_id

--How many days has each customer visited the restaurants
SELECT s.customer_id, COUNT(DISTINCT s.order_date) AS DaysVisited
FROM sales s
GROUP BY s.customer_id

--What was the first item from the menu purchased by each customer?
WITH customer_first_purchase AS (
	SELECT s.customer_id, MIN(s.order_date) AS firstPurchasedate
	FROM sales s
	GROUP BY s.customer_id
)
SELECT cfp.customer_id, cfp.firstPurchasedate, m.product_name
FROM customer_first_purchase cfp
JOIN sales s ON s.customer_id = cfp.customer_id
AND cfp.firstPurchasedate = s.order_date
JOIN menu m ON m.product_id = s.product_id;


--What is the most purchased item on the menu and how many times was it purchased by all customers?

SELECT TOP 1 m.product_name, COUNT(*) AS total_purchased
FROM sales s
JOIN menu m ON s.product_id = m.product_id
GROUP BY m.product_name
ORDER BY total_purchased DESC

--Which item was the most popular for each customer?
WITH customer_popularity AS (
    SELECT 
        s.customer_id,
        m.product_name,
        COUNT(*) AS purchase_count,
        ROW_NUMBER() OVER (PARTITION BY s.customer_id ORDER BY COUNT(*) DESC) AS rank
    FROM 
        sales s
    JOIN 
        menu m ON s.product_id = m.product_id
    GROUP BY 
        s.customer_id, m.product_name
)
SELECT cp.customer_id, cp.product_name, cp.purchase_count
FROM customer_popularity cp
WHERE rank = 1;


--Which item was purchased first by the customer after they became a member?
WITH first_purchase_after_membership AS (
  SELECT s.customer_id, Min(s.order_date) AS first_purchase_date
  FROM sales s
  JOIN members mb ON s.customer_id = mb.customer_id
  WHERE s.order_date >= mb.join_date
  GROUP BY s.customer_id
)
SELECT fpam.customer_id, m.product_name
FROM first_purchase_after_membership fpam
JOIN sales s ON s.customer_id = fpam.customer_id
AND fpam.first_purchase_date = s.order_date
JOIN menu m ON s.product_id = m.product_id;

--Which item was purchased just before the customer became a member?
--Which item was purchased just before the customer became a member?
WITH last_purchase_before_membership AS (
  SELECT S.customer_id, MAX(s.order_date) AS last_purchased_date
  FROM sales s
  JOIN members mb ON s.customer_id = mb.customer_id
  WHERE s.order_date < mb.join_date
  GROUP BY s.customer_id
)
SELECT lpbm.customer_id, m.product_name
FROM last_purchase_before_membership lpbm
JOIN sales s ON lpbm.customer_id = s.customer_id
AND lpbm.last_purchased_date = s.order_date
JOIN menu m ON s.product_id = m.product_id;

--What is the total items and amount spent for each member before they became a member?
SELECT s.customer_id, COUNT(*) AS total_items, SUM(m.price) AS total_spent
FROM sales s
JOIN menu m ON s.product_id = m.product_id
JOIN members mb ON s.customer_id = mb.customer_id
WHERE s.order_date < mb.join_date
GROUP BY s.customer_id

--If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?
SELECT s.customer_id, SUM(
	CASE
		WHEN m.product_name = 'sushi' THEN m.price*20
		ELSE m.price*10 END) AS total_points
FROM sales s
JOIN menu m ON s.product_id = m.product_id
GROUP BY s.customer_id

--In the first week after a customer joins the program (including their join date) they earn 2x points on all items, not just sushi - how many points do customer A and B have at the end of January?
SELECT s.customer_id, SUM(
    CASE
        WHEN s.order_date BETWEEN mb.join_date AND DATEADD(day, 7, mb.join_date)
        THEN m.price * 20
        WHEN m.product_name = 'sushi' THEN m.price * 20
        ELSE m.price * 10
    END) AS total_points
FROM sales s
JOIN menu m ON s.product_id = m.product_id
LEFT JOIN members mb ON s.customer_id = mb.customer_id
WHERE s.customer_id IN ('A', 'B') AND s.order_date <= '2021-01-31'
GROUP BY s.customer_id;


