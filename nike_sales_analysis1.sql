/*Question #1: 
What are the top customers by the total amount of revenue (aggregate of the sales price)
for the Nike Official and Nike Vintage business units combined?

Include the customer id, the total revenue,
and the number of order items each customer has purchased. 

Only include orders that have not been cancelled or returned.*/

WITH total_items AS (
  -- Combine data from order_items and order_items_vintage, excluding cancelled/returned orders
  SELECT  
      o.user_id,
      oi.sale_price,
      oi.order_item_id
  FROM order_items AS oi
  JOIN orders AS o ON o.order_id = oi.order_id
  WHERE o.status NOT IN ('Cancelled', 'Returned')

  UNION ALL 

  -- Similar selection from order_items_vintage
  SELECT 
      o.user_id,
      oiv.sale_price,
      oiv.order_item_id
  FROM order_items_vintage AS oiv
  JOIN orders AS o ON o.order_id = oiv.order_id
  WHERE o.status NOT IN ('Cancelled', 'Returned')
)

-- Aggregate total revenue and count of distinct order items per user
SELECT 
    user_id,
    SUM(sale_price) AS total_revenue,  -- Total revenue per user
    COUNT(DISTINCT order_item_id)  -- Count of distinct order items
FROM total_items
GROUP BY 1
ORDER BY 2 DESC  -- Order by total revenue in descending order
;


---- OR


WITH total_items AS (
  -- Combine data from both order_items and order_items_vintage
  SELECT * FROM order_items
  UNION ALL 
  SELECT * FROM order_items_vintage
)

SELECT
    orders.user_id,  -- Get the user_id from the orders table
    SUM(items.sale_price) AS total_revenue,  -- Calculate total revenue per user
    COUNT(items.order_item_id) AS total_order  -- Count the total number of order items per user

FROM 
    total_items AS items
JOIN 
    orders AS orders ON items.order_id = orders.order_id  -- Join total_items with orders on order_id
  
WHERE 
    orders.status NOT IN ('Cancelled', 'Returned')  -- Exclude cancelled and returned orders
GROUP BY 
    1  -- Group by user_id
ORDER BY 
    2 DESC  -- Order by total revenue in descending order
  ;



/*Question #2: 
Combine the order item data from Nike Official and Nike Vintage,
and segment customers into three segments.
(1) Customers that only purchased a single product; 
(2) Customers that purchased more than 1 product; 
(3) “Missing Data” (if none of these conditions match)

How many customers and how much revenue (aggregate of the sales price) falls in each segment?

Only include orders that have not been cancelled or returned.
To make you think: what type of data could fall under the third bucket?*/

WITH combined AS (
  -- Combine order_items and order_items_vintage into one dataset
  SELECT * FROM order_items
  UNION ALL
  SELECT * FROM order_items_vintage
),

product_per_customer AS (
  -- Classify customers based on the number of distinct products they bought
  SELECT 
      CASE 
        WHEN COUNT(DISTINCT c.product_id) = 1 THEN 'One Time Customer'  -- Customer bought only 1 distinct product
        WHEN COUNT(DISTINCT c.product_id) > 1 THEN 'Recurring Customer'  -- Customer bought more than 1 distinct product
        ELSE 'Missing Data'  -- If no product data is available, label as 'Missing Data'
      END AS customer_segment,
      o.user_id,  -- Get the user ID
      SUM(c.sale_price) AS total_sale  -- Calculate the total sales for each customer

  FROM combined AS c
  LEFT JOIN orders AS o ON o.order_id = c.order_id  -- Join orders with combined data

  WHERE o.status NOT IN ('Cancelled', 'Returned')  -- Exclude cancelled and returned orders
  GROUP BY o.user_id
)

-- Final output: group by customer segment, count customers, and sum their total revenue
SELECT
    customer_segment,
    COUNT(user_id) AS total_customers,  -- Count the total number of customers in each segment
    ROUND(CAST(SUM(total_sale) AS numeric), 2) AS total_revenue  -- Sum the total sales and round to 2 decimal places

FROM product_per_customer
GROUP BY customer_segment
;


 ------ OR 



WITH total_order_items AS (
  -- Combine data from order_items and order_items_vintage
  SELECT * FROM order_items
  UNION ALL
  SELECT * FROM order_items_vintage
),

customer_summary AS (
  -- Summarize customer data: total revenue and classify customers based on product diversity
  SELECT 
      orders.user_id,  -- Get the user ID
      SUM(items.sale_price) AS total_revenue,  -- Calculate total revenue per user
      CASE 
          WHEN COUNT(DISTINCT items.product_id) = 1 THEN 'One Time Customer'  -- Customer bought only 1 distinct product
          WHEN COUNT(DISTINCT items.product_id) > 1 THEN 'Recurring Customer'  -- Customer bought more than 1 distinct product
          ELSE 'Missing Data'  -- No product data available
      END AS customer_segment  -- Classify customers into segments

  FROM total_order_items items
  LEFT JOIN orders ON items.order_id = orders.order_id  -- Join orders with total_order_items
  WHERE orders.status NOT IN ('Returned', 'Cancelled')  -- Exclude returned and cancelled orders

  GROUP BY orders.user_id  -- Group by user_id for customer summary
)

-- Final query: count customers and sum total revenue by customer segment
SELECT 
    customer_segment,
    COUNT(DISTINCT user_id) AS total_customers,  -- Count distinct users per customer segment
    ROUND(CAST(SUM(total_revenue) AS numeric), 2) AS total_revenue  -- Sum total revenue per segment and round to 2 decimal places

FROM customer_summary
GROUP BY customer_segment
;



/*Question #3: 
The Nike Official leadership team is keen to understand what % of the total revenue per state 
is coming from the Nike Official business.

Create list that shows the total revenue (aggregate of the sales price) per state,
the revenue generated from Nike Official, and the % of the Nike Official revenue 
compared to the total revenue for every state.

Only include orders that have not been cancelled or returned and 
order the table to show the state with the highest amount of revenue first, 
even is there is no information available about the state.*/


WITH combined AS (
  -- Combine data from order_items and order_items_vintage
  SELECT * FROM order_items
  UNION ALL 
  SELECT * FROM order_items_vintage
)

SELECT  
    COALESCE(cust.state, 'Missing Data') AS state,  -- Handle missing customer state data
    ROUND(CAST(SUM(comb.sale_price) AS numeric), 2) AS total_revenue,  -- Total revenue from combined data
    ROUND(CAST(SUM(oi.sale_price) AS numeric), 2) AS total_revenue_Nike_official,  -- Total revenue from official Nike sales
    ROUND(CAST(100.0 * SUM(oi.sale_price) / SUM(comb.sale_price) AS numeric), 2) || '%' AS rev_perc_Nike_official  -- Percentage of Nike official revenue
    
FROM 
    combined AS comb
JOIN 
    orders AS o ON o.order_id = comb.order_id  -- Join orders with combined items
LEFT JOIN 
    order_items AS oi ON oi.order_item_id = comb.order_item_id  -- Join official Nike order items
LEFT JOIN 
    customers AS cust ON cust.customer_id = o.user_id  -- Join customers to get customer state

WHERE 
    o.status NOT IN ('Cancelled', 'Returned')  -- Exclude cancelled and returned orders

GROUP BY 
    1  -- Group by customer state
ORDER BY 
    2 DESC  -- Order by total revenue in descending order
  ;


--FULL JOIN for the customer table would provide the correct answer as well--


/*Question #4: 
Create an overview of the orders by state. 
Summarize for each customer the number of orders that have status of Complete, or Cancelled 
(Returned or Cancelled).

Exclude all orders that are still in progress (Processing or Shipped) and 
only include orders for customers that have a state available.*/

WITH subtable AS (
  -- Select all orders excluding 'Processing' and 'Shipped' statuses
  SELECT * 
  FROM orders
  WHERE status NOT IN ('Processing', 'Shipped')
)

SELECT
    cust.state,  -- Select customer state
    COUNT(DISTINCT sub.order_id) AS total_orders,  -- Count total distinct orders per state
    COUNT(DISTINCT sub.order_id) FILTER (WHERE sub.status = 'Complete') AS total_complete,  -- Count total completed orders
    COUNT(DISTINCT sub.order_id) FILTER (WHERE sub.status IN ('Cancelled', 'Returned')) AS total_cancelled  -- Count total cancelled or returned orders
    
FROM 
    subtable AS sub
LEFT JOIN 
    customers AS cust ON cust.customer_id = sub.user_id  -- Join orders with customers to get state info

WHERE 
    cust.state IS NOT NULL  -- Only include records where customer state is not null
GROUP BY 
    1  -- Group by customer state
;
