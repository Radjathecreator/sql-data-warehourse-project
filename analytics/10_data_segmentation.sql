/*
===============================================================================
Data Segmentation Analysis
===============================================================================
Purpose:
    - To group data into meaningful categories for targeted insights.
    - For customer segmentation, product categorization, or regional analysis.

SQL Functions Used:
    - CASE: Defines custom segmentation logic.
    - GROUP BY: Groups data into segments.
===============================================================================
*/

/*Segment products into cost ranges and 
count how many products fall into each segment*/
WITH product_segment AS
(
    SELECT 
        product_key,
        product_name,
        cost,
        CASE 
            WHEN cost < 100 THEN 'Below 100'
            WHEN cost BETWEEN 100 AND 500 THEN '100 to 500'
            WHEN cost BETWEEN 500 AND 1000 THEN '500 to 1000'
            ELSE 'Above 1000'
        END cost_category
    FROM gold.dim_products
)
SELECT 
    cost_category,
    COUNT(cost_category) AS category_count
FROM product_segment
GROUP BY cost_category
ORDER BY category_count DESC

/*Group customers into three segments based on their spending behavior:
	- VIP: Customers with at least 12 months of history and spending more than €5,000.
	- Regular: Customers with at least 12 months of history but spending €5,000 or less.
	- New: Customers with a lifespan less than 12 months.
And find the total number of customers by each group
*/
WITH cte_category AS(
    SELECT
        s.customer_key,
        CONCAT(c.first_name,' ',c.last_name) name,
        MIN(s.order_date) AS first_order,
        MAX(s.order_date) AS last_order,
        DATEDIFF(month, MIN(s.order_date), MAX(s.order_date)) AS date_diff,
        SUM(sales_amount) AS sales,
        CASE 
            WHEN DATEDIFF(month, MIN(s.order_date), MAX(s.order_date)) >= 12 AND SUM(sales_amount) > 5000 THEN 'VIP'
            WHEN DATEDIFF(month, MIN(s.order_date), MAX(s.order_date)) >= 12 AND SUM(sales_amount) <= 5000 THEN 'Regular'
            ELSE 'New'
        END customer_category
    FROM gold.fact_sales s
    LEFT JOIN gold.dim_customers c
    ON s.customer_key = c.customer_key
    WHERE s.order_date IS NOT NULL
    GROUP BY s.customer_key, CONCAT(c.first_name,' ',c.last_name)
)
SELECT
    customer_category,
    COUNT(customer_key) AS customer_count
FROM cte_category
GROUP BY customer_category;
