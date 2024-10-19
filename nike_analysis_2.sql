/*Question #1: 
Create a rolling sum that rolls up the number of order items
for each product name for the Nike Official business ordered by product name.

Include the order items where the product name is available.*/

SELECT
    COALESCE(p.product_name, 'Total Orders') AS product_name,  -- Replace NULL product names (from ROLLUP) with 'Total Orders'
    COUNT(oi.order_item_id) AS count_order_item  -- Count the total number of order items per product

FROM 
    order_items AS oi
JOIN 
    products AS p ON oi.product_id = p.product_id  -- Join order_items with products on product_id

GROUP BY 
    ROLLUP(p.product_name)  -- Group by product_name, with an additional row for the total using ROLLUP
ORDER BY 
    1  -- Order by product_name
;



/*Question #2: 
What is the order item completion rate
(number of completed order items divided by total number of order items) 
for each of the products (across Nike Official and Nike Vintage) by product name? 

To confirm which product deliveries have been completed (delivered and not returned),
you can filter for the delivered date to be NOT NULL and the returned date to be NULL.

Show the products only where the product name is available and 
show the products with highest completion rate first in the table.*/

WITH combined AS (
  -- Combine data from order_items and order_items_vintage
  SELECT * FROM order_items
  UNION ALL
  SELECT * FROM order_items_vintage
)

SELECT
    p.product_name,  -- Select product name
    COUNT(c.order_item_id) FILTER (WHERE o.status = 'Complete')::FLOAT /  -- Count completed order items
    COUNT(c.order_item_id)::FLOAT AS completion_rate  -- Divide by total order items to calculate completion rate

FROM 
    combined AS c
JOIN 
    orders AS o ON o.order_id = c.order_id  -- Join with orders to get order status
JOIN 
    products AS p ON p.product_id = c.product_id  -- Join with products to get product names

GROUP BY 
    p.product_name  -- Group by product name
ORDER BY 
    2 DESC  -- Order by completion rate in descending order
;



--- OR


WITH combined AS (
  -- Combine data from order_items and order_items_vintage
  SELECT * FROM order_items
  UNION ALL
  SELECT * FROM order_items_vintage
)

SELECT
    p.product_name,  -- Select product name
    COUNT(c.order_item_id) FILTER (WHERE c.delivered_at IS NOT NULL AND c.returned_at IS NULL)::FLOAT /  -- Count orders that are delivered and not returned
    COUNT(c.order_item_id)::FLOAT AS completion_rate  -- Divide by total order items to calculate completion rate

FROM 
    combined AS c
JOIN 
    products AS p ON p.product_id = c.product_id  -- Join with products to get product names

GROUP BY 
    p.product_name  -- Group by product name
ORDER BY 
    2 DESC -- Order by completion rate in descending order
  ;


/*Question #3: 
Your manager heard a rumour that there is a difference in order item completion rates per age group. 
Can you look into this?

To confirm which product deliveries have been completed (delivered and not returned), 
you can filter for the delivered date to be not NULL and the returned date to be NULL.

What the order item completion rate (number of completed order items divided by total number of order items) 
by age group?*/

WITH combined AS (
  -- Combine data from order_items and order_items_vintage
  SELECT * FROM order_items
  UNION ALL
  SELECT * FROM order_items_vintage
)

SELECT
    COALESCE(cust.age_group, 'unknown') AS age_group,  -- Replace null age groups with 'unknown'
    COUNT(comb.order_item_id) FILTER (WHERE comb.delivered_at IS NOT NULL AND comb.returned_at IS NULL)::FLOAT /  
    COUNT(comb.order_item_id)::FLOAT AS completion_rate  -- Calculate the completion rate (delivered and not returned)

FROM 
    combined AS comb
LEFT JOIN 
    customers AS cust ON cust.customer_id = comb.user_id  -- Join customers to get the age group

GROUP BY 
    1  -- Group by age group (first column)
ORDER BY 
    1  -- Order by age group alphabetically
;

/*Question #4: 
Calculate the order item completion rate on two levels of granularity: 
(1) The completion rate by age group;
(2) The completion rate by age group and product name.

Create a table that includes the following columns: age group, order item completion rate 
by age group, product name, and order item completion rate by age group and product name.

Only include customers for who the age group is available.*/

WITH completion_rate_ba_age AS (
  -- Calculate the completion rate (delivered and not returned) for each age group
  SELECT
      cust.age_group,  -- Customer age group
      COUNT(oi.order_item_id) FILTER (WHERE oi.delivered_at IS NOT NULL AND oi.returned_at IS NULL)::FLOAT AS complete_orders,  -- Count completed orders
      COUNT(oi.order_item_id)::FLOAT AS total_orders,  -- Total number of orders
      COUNT(oi.order_item_id) FILTER (WHERE oi.delivered_at IS NOT NULL AND oi.returned_at IS NULL)::FLOAT /
      COUNT(oi.order_item_id)::FLOAT AS completion_rate_by_age  -- Calculate completion rate by age group

  FROM order_items AS oi
  JOIN customers AS cust ON cust.customer_id = oi.user_id  -- Join customers to get age group
  GROUP BY 1
  ORDER BY 1
),

completion_rate_by_age_and_prduct AS (
  -- Calculate completion rate by age group and product
  SELECT
      cust.age_group,  -- Customer age group
      p.product_name,  -- Product name
      COUNT(oi.order_item_id) FILTER (WHERE oi.delivered_at IS NOT NULL AND oi.returned_at IS NULL)::FLOAT /
      COUNT(oi.order_item_id)::FLOAT AS completion_rate_by_age_and_product  -- Calculate completion rate for age group and product

  FROM order_items AS oi
  JOIN customers AS cust ON cust.customer_id = oi.user_id  -- Join customers to get age group
  JOIN products AS p ON p.product_id = oi.product_id  -- Join products to get product names
  GROUP BY 1, 2  -- Group by both age group and product
  ORDER BY 1
)

-- Final query to combine completion rates by age group and product
SELECT 
    cra.age_group,  -- Age group
    cra.completion_rate_by_age,  -- Completion rate by age group
    crap.product_name,  -- Product name
    crap.completion_rate_by_age_and_product  -- Completion rate by age group and product

FROM completion_rate_by_age_and_prduct AS crap
JOIN completion_rate_ba_age AS cra ON cra.age_group = crap.age_group  -- Join on age group to combine data
;
