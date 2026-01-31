create database Ecommerce_dataset;
use Ecommerce_dataset

-----Explore all objects in database
SELECT * FROM INFORMATION_SCHEMA.TABLES

-----Explore columns in database
SELECT * FROM INFORMATION_SCHEMA.COLUMNS

/*
===============================================================================
Database Exploration
===============================================================================
Purpose:
    - To explore the structure of the database, including the list of tables and their schemas.
    - To inspect the columns and metadata for specific tables.

Table Used:
    - INFORMATION_SCHEMA.TABLES
    - INFORMATION_SCHEMA.COLUMNS
===============================================================================
*/

-- Retrieve a list of all tables in the database
SELECT 
    TABLE_CATALOG, 
    TABLE_SCHEMA, 
    TABLE_NAME, 
    TABLE_TYPE
FROM INFORMATION_SCHEMA.TABLES;

-- Retrieve all columns for the main table
SELECT 
    TABLE_NAME,
    COLUMN_NAME, 
    DATA_TYPE, 
    IS_NULLABLE
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME IN (
    'customers','geolocation','leads_closed','leads_qualified','order_items',
    'order_payments','order_reviews','orders','product_category_name_translation',
    'products','sellers');



/*
===============================================================================
Dimensions Exploration
===============================================================================
Purpose:
    - To explore the structure of dimension tables.
	
SQL Functions Used:
    - DISTINCT
    - ORDER BY
===============================================================================
*/
--Customers--
SELECT
    COUNT(*) AS Total_customers,
    COUNT(DISTINCT customer_city) AS Total_cities,
    COUNT(DISTINCT customer_state) AS Total_states
FROM dbo.customers

SELECT 
    customer_city,
    customer_state,
    COUNT(*) AS No_of_customers
FROM dbo.customers
GROUP BY customer_city,customer_state
ORDER BY No_of_customers DESC

--Sellers--
SELECT
    COUNT(*) AS Total_sellers,
    COUNT(DISTINCT seller_city) AS Total_cities,
    COUNT(DISTINCT seller_state) AS Total_states
FROM dbo.sellers

SELECT 
    seller_city,
    seller_state,
    COUNT(*) AS No_of_sellers
FROM dbo.sellers
GROUP BY seller_city,seller_state
ORDER BY No_of_sellers DESC

--Products--
SELECT
    p.product_category_name AS category,
    COUNT(DISTINCT oi.order_id) AS total_orders,
    SUM(oi.price) AS total_revenue,
    AVG(oi.price) AS avg_price
FROM dbo.products p
JOIN dbo.order_items oi
    ON p.product_id = oi.product_id
GROUP BY p.product_category_name
ORDER BY total_revenue DESC;

/*
===============================================================================
Date Range Exploration 
===============================================================================
Purpose:
    - To determine the temporal boundaries of key data points.
    - To understand the range of historical data.

SQL Functions Used:
    - MIN(), MAX(), DATEDIFF()
===============================================================================
*/

-- Determine the first and last order date and the total duration in months
SELECT 
    MIN(order_purchase_timestamp) AS first_order,
    MAX(order_purchase_timestamp) AS last_order,
    DATEDIFF(MONTH, MIN(order_purchase_timestamp), MAX(order_purchase_timestamp)) AS duration
FROM dbo.orders

-- Orders per year
select * from orders
SELECT
    COUNT(order_id) as total_orders,
    YEAR(order_purchase_timestamp) AS order_year
FROM orders
GROUP BY YEAR(order_purchase_timestamp)

/*
===============================================================================
Measures Exploration (Key Metrics)
===============================================================================
Purpose:
    - To calculate aggregated metrics (e.g., totals, averages) for quick insights.
    - To identify overall trends or spot anomalies.

SQL Functions Used:
    - COUNT(), SUM(), AVG()
===============================================================================
*/
select * from dbo.order_items
-- Find total orders
SELECT COUNT( DISTINCT order_id) AS total_orders FROM dbo.orders

-- Total revenue per order
SELECT oi.order_id,SUM(op.payment_installments * oi.price) AS Total_revenue
FROM order_items oi
LEFT JOIN order_payments op
ON oi.order_id=op.order_id
GROUP BY oi.order_id

--Total net revenue
with order_revenue as (
    SELECT oi.order_id,SUM(op.payment_installments * oi.price) AS Total_revenue
    FROM order_items oi
    LEFT JOIN order_payments op
    ON oi.order_id=op.order_id
    GROUP BY oi.order_id
)
SELECT (SUM(ore.Total_revenue) - SUM(op.payment_value)) AS net_revenue 
FROM order_revenue ore
LEFT JOIN order_payments op
ON ore.order_id = op.order_id


-- Find the average selling price
SELECT AVG(price) AS avg_price FROM order_items

-- Find the total number of products
SELECT COUNT(DISTINCT product_id) AS total_products FROM products

-- Find the total number of customers
SELECT COUNT(DISTINCT customer_id) AS total_customers FROM customers;



/*
===============================================================================
Magnitude Analysis
===============================================================================
Purpose:
    - To quantify data and group results by specific dimensions.
    - For understanding data distribution across categories.

SQL Functions Used:
    - Aggregate Functions: SUM(), COUNT(), AVG()
    - GROUP BY, ORDER BY
===============================================================================
*/*/
-- Total orders by product category
SELECT 
    p.product_category_name,
    COUNT(DISTINCT oi.order_id) as order_numbers   
FROM order_items oi
LEFT JOIN  products p
ON oi.product_id=p.product_id
GROUP BY p.product_category_name

--Total orders by sellers
SELECT 
    s.seller_id, 
    COUNT(DISTINCT oi.order_id) AS Total_seller_order
FROM order_items oi
LEFT JOIN sellers s
ON oi.seller_id = s.seller_id
GROUP BY s.seller_id

-- Total revenue for each category
SELECT 
    p.product_category_name,
    SUM(oi.price) as product_revenue,
    SUM(oi.freight_value) as freight_revenue,
    SUM(oi.price + oi.freight_value) as total_revenue,
    COUNT(DISTINCT oi.order_id) as num_orders,
    COUNT(*) as num_items
FROM order_items oi
JOIN products p ON oi.product_id = p.product_id
GROUP BY p.product_category_name
ORDER BY total_revenue DESC;

-- total revenue generated by each customer
SELECT 
    o.customer_id,
    SUM(oi.price) as product_revenue,
    SUM(oi.freight_value) as freight_revenue,
    SUM(oi.price + oi.freight_value) as total_revenue,
    COUNT(DISTINCT oi.order_id) as num_orders,
    COUNT(*) as num_items
FROM order_items oi
JOIN orders o ON oi.order_id = o.order_id
GROUP BY o.customer_id
ORDER BY total_revenue DESC;

-- Distribution of sold items across state
SELECT 
    c.customer_state,
    COUNT(*) as items_sold,
    COUNT(DISTINCT oi.order_id) as num_orders,
    COUNT(DISTINCT o.customer_id) as num_customers,
    SUM(oi.price) as total_revenue
FROM order_items oi
JOIN orders o ON oi.order_id = o.order_id
JOIN customers c ON o.customer_id = c.customer_id
GROUP BY c.customer_state
ORDER BY items_sold DESC;

/*
===============================================================================
Ranking Analysis
===============================================================================
Purpose:
    - To rank items (e.g., products, customers) based on performance or other metrics.
    - To identify top performers or laggards.

SQL Functions Used:
    - Window Ranking Functions: RANK(), DENSE_RANK(), ROW_NUMBER(), TOP
    - Clauses: GROUP BY, ORDER BY
===============================================================================
*/

--5 products with highest revenue
SELECT TOP 5
    p.product_id,
    p.product_category_name,
    SUM(oi.price) as total_revenue,
    COUNT(*) as items_sold,
    COUNT(DISTINCT oi.order_id) as num_orders
FROM order_items oi
JOIN products p ON oi.product_id = p.product_id
GROUP BY p.product_id, p.product_category_name
ORDER BY total_revenue DESC
;

--5 worst-performing products with lowest revenue
SELECT TOP 5
    p.product_id,
    p.product_category_name,
    SUM(oi.price) as total_revenue,
    COUNT(*) as items_sold,
    COUNT(DISTINCT oi.order_id) as num_orders
FROM order_items oi
JOIN products p ON oi.product_id = p.product_id
GROUP BY p.product_id, p.product_category_name
ORDER BY total_revenue ASC

--top 10 customers who have generated the highest revenue
SELECT TOP 10
    o.customer_id,
    c.customer_city,
    c.customer_state,
    SUM(oi.price) as total_revenue,
    COUNT(DISTINCT oi.order_id) as num_orders,
    COUNT(*) as items_purchased
FROM order_items oi
JOIN orders o ON oi.order_id = o.order_id
JOIN customers c ON o.customer_id = c.customer_id
GROUP BY o.customer_id, c.customer_city, c.customer_state
ORDER BY total_revenue DESC

--3 customers with the fewest orders placed
SELECT TOP 3
    o.customer_id,
    c.customer_city,
    c.customer_state,
    COUNT(DISTINCT oi.order_id) as num_orders,
    SUM(oi.price) as total_revenue,
    COUNT(*) as items_purchased
FROM order_items oi
JOIN orders o ON oi.order_id = o.order_id
JOIN customers c ON o.customer_id = c.customer_id
GROUP BY o.customer_id, c.customer_city, c.customer_state
ORDER BY num_orders ASC

/*
===============================================================================
Change Over Time Analysis
===============================================================================
Purpose:
    - To track trends, growth, and changes in key metrics over time.
    - For time-series analysis and identifying seasonality.
    - To measure growth or decline over specific periods.

SQL Functions Used:
    - Date Functions: DATEPART(), DATETRUNC(), FORMAT()
    - Aggregate Functions: SUM(), COUNT(), AVG()
===============================================================================
*/
-- ============================================
-- CHANGE OVER TIME ANALYSES
-- ============================================

-- Total sales by year
SELECT 
    YEAR(o.order_purchase_timestamp) AS order_year,
    SUM(oi.price) AS total_sales,
    COUNT(DISTINCT o.customer_id) AS total_customers,
    SUM(oi.price + oi.freight_value) AS total_revenue_with_freight,
    COUNT(*) AS total_items_sold,
    COUNT(DISTINCT oi.order_id) AS total_orders
FROM order_items oi
JOIN orders o ON oi.order_id = o.order_id
WHERE o.order_purchase_timestamp IS NOT NULL
GROUP BY YEAR(o.order_purchase_timestamp)
ORDER BY YEAR(o.order_purchase_timestamp);

-- Seasonality analysis - Monthly 
SELECT 
    MONTH(o.order_purchase_timestamp) AS order_month,
    SUM(oi.price) AS total_sales,
    COUNT(DISTINCT o.customer_id) AS total_customers,
    COUNT(*) AS total_items_sold,
    COUNT(DISTINCT oi.order_id) AS total_orders,
    AVG(oi.price) AS avg_item_price
FROM order_items oi
JOIN orders o ON oi.order_id = o.order_id
WHERE o.order_purchase_timestamp IS NOT NULL
GROUP BY MONTH(o.order_purchase_timestamp)
ORDER BY MONTH(o.order_purchase_timestamp);

-- Monthly sales trend (Year-Month format)
SELECT 
    DATETRUNC(month, o.order_purchase_timestamp) AS order_date,
    SUM(oi.price) AS total_sales,
    COUNT(DISTINCT o.customer_id) AS total_customers,
    COUNT(*) AS total_items_sold,
    COUNT(DISTINCT oi.order_id) AS total_orders
FROM order_items oi
JOIN orders o ON oi.order_id = o.order_id
WHERE o.order_purchase_timestamp IS NOT NULL
GROUP BY DATETRUNC(month, o.order_purchase_timestamp)
ORDER BY DATETRUNC(month, o.order_purchase_timestamp);

-- ============================================
-- CUMULATIVE ANALYSIS
-- ============================================

-- Running total of sales over time (monthly)
SELECT
    order_month,
    total_sales,
    SUM(total_sales) OVER (ORDER BY order_month) AS running_total_sales,
    AVG(total_sales) OVER (ORDER BY order_month ROWS BETWEEN 2 PRECEDING AND CURRENT ROW) AS three_month_avg
FROM (
    SELECT 
        DATETRUNC(month, o.order_purchase_timestamp) AS order_month,
        SUM(oi.price) AS total_sales
    FROM order_items oi
    JOIN orders o ON oi.order_id = o.order_id
    WHERE o.order_purchase_timestamp IS NOT NULL
    GROUP BY DATETRUNC(month, o.order_purchase_timestamp)
) t
ORDER BY order_month;

-- Moving average analysis
SELECT
    order_month,
    total_sales,
    total_orders,
    average_order_value,
    SUM(total_sales) OVER (ORDER BY order_month) AS running_total_sales,
    AVG(average_order_value) OVER (ORDER BY order_month ROWS BETWEEN 2 PRECEDING AND CURRENT ROW) AS moving_avg_order_value
FROM (
    SELECT 
        DATETRUNC(month, o.order_purchase_timestamp) AS order_month,
        SUM(oi.price) AS total_sales,
        COUNT(DISTINCT oi.order_id) AS total_orders,
        SUM(oi.price) / COUNT(DISTINCT oi.order_id) AS average_order_value
    FROM order_items oi
    JOIN orders o ON oi.order_id = o.order_id
    WHERE o.order_purchase_timestamp IS NOT NULL
    GROUP BY DATETRUNC(month, o.order_purchase_timestamp)
) t
ORDER BY order_month;

-- ============================================
-- PERFORMANCE ANALYSIS
-- ============================================

-- Product category performance: Compare to average & previous Year
WITH yearly_category_sales AS (
    SELECT
        YEAR(o.order_purchase_timestamp) AS order_year,
        p.product_category_name,
        SUM(oi.price) AS current_sales,
        COUNT(DISTINCT oi.order_id) AS total_orders,
        COUNT(*) AS items_sold
    FROM order_items oi
    JOIN orders o ON oi.order_id = o.order_id
    JOIN products p ON oi.product_id = p.product_id
    WHERE o.order_purchase_timestamp IS NOT NULL
    GROUP BY 
        YEAR(o.order_purchase_timestamp),
        p.product_category_name
)

SELECT 
    order_year,
    product_category_name,
    current_sales,
    items_sold,
    AVG(current_sales) OVER (PARTITION BY product_category_name) AS avg_sales,
    current_sales - AVG(current_sales) OVER (PARTITION BY product_category_name) AS diff_avg,
    CASE 
        WHEN current_sales - AVG(current_sales) OVER (PARTITION BY product_category_name) > 0 THEN 'Above Average'
        WHEN current_sales - AVG(current_sales) OVER (PARTITION BY product_category_name) < 0 THEN 'Below Average'
        ELSE 'Average'
    END AS average_change,
    LAG(current_sales) OVER (PARTITION BY product_category_name ORDER BY order_year) AS py_sales,
    current_sales - LAG(current_sales) OVER (PARTITION BY product_category_name ORDER BY order_year) AS diff_py,
    CASE 
        WHEN current_sales - LAG(current_sales) OVER (PARTITION BY product_category_name ORDER BY order_year) > 0 THEN 'Increased'
        WHEN current_sales - LAG(current_sales) OVER (PARTITION BY product_category_name ORDER BY order_year) < 0 THEN 'Decreased'
        ELSE 'No change'
    END AS yoy_change
FROM yearly_category_sales
ORDER BY product_category_name, order_year;

-- Seller performance analysis
WITH yearly_seller_sales AS (
    SELECT
        YEAR(o.order_purchase_timestamp) AS order_year,
        oi.seller_id,
        SUM(oi.price) AS current_sales,
        COUNT(DISTINCT oi.order_id) AS total_orders
    FROM order_items oi
    JOIN orders o ON oi.order_id = o.order_id
    WHERE o.order_purchase_timestamp IS NOT NULL
    GROUP BY 
        YEAR(o.order_purchase_timestamp),
        oi.seller_id
)

SELECT 
    order_year,
    seller_id,
    current_sales,
    total_orders,
    AVG(current_sales) OVER (PARTITION BY seller_id) AS avg_sales,
    LAG(current_sales) OVER (PARTITION BY seller_id ORDER BY order_year) AS py_sales,
    CASE 
        WHEN current_sales - LAG(current_sales) OVER (PARTITION BY seller_id ORDER BY order_year) > 0 THEN 'Increased'
        WHEN current_sales - LAG(current_sales) OVER (PARTITION BY seller_id ORDER BY order_year) < 0 THEN 'Decreased'
        ELSE 'No change'
    END AS yoy_change
FROM yearly_seller_sales
ORDER BY current_sales DESC;

-- ============================================
-- PART-TO-WHOLE ANALYSIS
-- ============================================

-- Category contribution to Overall sales
WITH category_sales AS (
    SELECT
        p.product_category_name AS category,
        SUM(oi.price) AS total_sales,
        COUNT(*) AS items_sold,
        COUNT(DISTINCT oi.order_id) AS total_orders
    FROM order_items oi
    JOIN products p ON oi.product_id = p.product_id
    GROUP BY p.product_category_name
)

SELECT 
    category,
    total_sales,
    items_sold,
    total_orders,
    SUM(total_sales) OVER () AS overall_sales,
    CONCAT(ROUND((CAST(total_sales AS FLOAT) / SUM(total_sales) OVER ()) * 100, 2), '%') AS category_portion,
    CONCAT(ROUND((CAST(items_sold AS FLOAT) / SUM(items_sold) OVER ()) * 100, 2), '%') AS items_portion
FROM category_sales
ORDER BY total_sales DESC;

-- State contribution to Overall sales
WITH state_sales AS (
    SELECT
        c.customer_state AS state,
        SUM(oi.price) AS total_sales,
        COUNT(DISTINCT o.customer_id) AS total_customers,
        COUNT(DISTINCT oi.order_id) AS total_orders
    FROM order_items oi
    JOIN orders o ON oi.order_id = o.order_id
    JOIN customers c ON o.customer_id = c.customer_id
    GROUP BY c.customer_state
)

SELECT 
    state,
    total_sales,
    total_customers,
    total_orders,
    SUM(total_sales) OVER () AS overall_sales,
    CONCAT(ROUND((CAST(total_sales AS FLOAT) / SUM(total_sales) OVER ()) * 100, 2), '%') AS state_portion
FROM state_sales
ORDER BY total_sales DESC;

-- Payment Type Distribution
WITH payment_type_sales AS (
    SELECT
        op.payment_type,
        SUM(op.payment_value) AS total_payment_value,
        COUNT(DISTINCT op.order_id) AS total_orders,
        AVG(op.payment_value) AS avg_payment
    FROM order_payments op
    GROUP BY op.payment_type
)

SELECT 
    payment_type,
    total_payment_value,
    total_orders,
    avg_payment,
    SUM(total_payment_value) OVER () AS overall_payment,
    CONCAT(ROUND((CAST(total_payment_value AS FLOAT) / SUM(total_payment_value) OVER ()) * 100, 2), '%') AS payment_type_portion
FROM payment_type_sales
ORDER BY total_payment_value DESC;

-- ============================================
-- DATA SEGMENTATION
-- ============================================

-- Product price segmentation
WITH product_segment AS (
    SELECT 
        oi.product_id,
        p.product_category_name,
        AVG(oi.price) AS avg_price,
        CASE
            WHEN AVG(oi.price) < 50 THEN 'Budget (Below 50)'
            WHEN AVG(oi.price) BETWEEN 50 AND 150 THEN 'Mid-range (50-150)'
            WHEN AVG(oi.price) BETWEEN 150 AND 500 THEN 'Premium (150-500)'
            ELSE 'Luxury (Above 500)'
        END AS price_range
    FROM order_items oi
    JOIN products p ON oi.product_id = p.product_id
    GROUP BY oi.product_id, p.product_category_name
)

SELECT 
    price_range, 
    COUNT(product_id) AS total_products,
    CONCAT(ROUND((CAST(COUNT(product_id) AS FLOAT) / SUM(COUNT(product_id)) OVER ()) * 100, 2), '%') AS product_portion
FROM product_segment
GROUP BY price_range
ORDER BY COUNT(product_id) DESC;

-- Customer segmentation by spending & activity
WITH customer_spending AS (
    SELECT
        o.customer_id,
        c.customer_state,
        SUM(oi.price) AS total_spending,
        COUNT(DISTINCT oi.order_id) AS total_orders,
        MIN(o.order_purchase_timestamp) AS first_order,
        MAX(o.order_purchase_timestamp) AS last_order,
        DATEDIFF(month, MIN(o.order_purchase_timestamp), MAX(o.order_purchase_timestamp)) AS lifespan_months
    FROM order_items oi
    JOIN orders o ON oi.order_id = o.order_id
    JOIN customers c ON o.customer_id = c.customer_id
    GROUP BY o.customer_id, c.customer_state
)

SELECT 
    customer_segment,
    COUNT(customer_id) AS total_customers,
    AVG(total_spending) AS avg_spending,
    AVG(total_orders) AS avg_orders,
    CONCAT(ROUND((CAST(COUNT(customer_id) AS FLOAT) / SUM(COUNT(customer_id)) OVER ()) * 100, 2), '%') AS customer_portion
FROM (
    SELECT  
        customer_id,
        total_spending,
        total_orders,
        CASE 
            WHEN total_spending > 1000 AND lifespan_months >= 6 THEN 'VIP'
            WHEN total_spending <= 1000 AND lifespan_months >= 6 THEN 'Regular'
            WHEN total_orders > 1 THEN 'Repeat'
            ELSE 'One-time'
        END AS customer_segment
    FROM customer_spending
) t
GROUP BY customer_segment
ORDER BY total_customers DESC;

-- Order size segmentation
WITH order_size AS (
    SELECT
        oi.order_id,
        COUNT(*) AS items_per_order,
        SUM(oi.price) AS order_value,
        CASE
            WHEN COUNT(*) = 1 THEN 'Single Item'
            WHEN COUNT(*) BETWEEN 2 AND 3 THEN 'Small (2-3 items)'
            WHEN COUNT(*) BETWEEN 4 AND 6 THEN 'Medium (4-6 items)'
            ELSE 'Large (7+ items)'
        END AS order_size_segment
    FROM order_items oi
    GROUP BY oi.order_id
)

SELECT 
    order_size_segment,
    COUNT(order_id) AS total_orders,
    AVG(order_value) AS avg_order_value,
    CONCAT(ROUND((CAST(COUNT(order_id) AS FLOAT) / SUM(COUNT(order_id)) OVER ()) * 100, 2), '%') AS order_portion
FROM order_size
GROUP BY order_size_segment
ORDER BY total_orders DESC;

-- ============================================
-- DELIVERY PERFORMANCE ANALYSIS
-- ============================================

-- Delivery time analysis by state
SELECT
    c.customer_state,
    COUNT(DISTINCT o.order_id) AS total_orders,
    AVG(DATEDIFF(day, o.order_purchase_timestamp, o.order_delivered_customer_date)) AS avg_delivery_days,
    AVG(DATEDIFF(day, o.order_estimated_delivery_date, o.order_delivered_customer_date)) AS avg_delivery_variance,
    SUM(CASE WHEN o.order_delivered_customer_date <= o.order_estimated_delivery_date THEN 1 ELSE 0 END) AS on_time_deliveries,
    CONCAT(ROUND((CAST(SUM(CASE WHEN o.order_delivered_customer_date <= o.order_estimated_delivery_date THEN 1 ELSE 0 END) AS FLOAT) / COUNT(*)) * 100, 2), '%') AS on_time_rate
FROM orders o
JOIN customers c ON o.customer_id = c.customer_id
WHERE o.order_delivered_customer_date IS NOT NULL
GROUP BY c.customer_state
ORDER BY avg_delivery_days;

-- Review score impact on sales
WITH review_sales AS (
    SELECT
        r.review_score,
        COUNT(DISTINCT r.order_id) AS total_orders,
        AVG(oi.price) AS avg_order_value,
        SUM(oi.price) AS total_sales
    FROM order_reviews r
    JOIN order_items oi ON r.order_id = oi.order_id
    GROUP BY r.review_score
)

SELECT
    review_score,
    total_orders,
    avg_order_value,
    total_sales,
    CONCAT(ROUND((CAST(total_orders AS FLOAT) / SUM(total_orders) OVER ()) * 100, 2), '%') AS order_portion
FROM review_sales
ORDER BY review_score DESC;

/*
===============================================================================
Customer Report - Olist E-commerce Dataset
===============================================================================
Purpose:
    - This report consolidates key customer metrics and behaviors for Olist

Highlights:
    1. Gathers essential fields such as customer location and transaction details.
    2. Segments customers into categories (VIP, Regular, Repeat, One-time).
    3. Aggregates customer-level metrics:
       - total orders
       - total sales (product revenue)
       - total revenue (including freight)
       - total quantity purchased
       - total products
       - lifespan (in months)
    4. Calculates valuable KPIs:
        - recency (months since last order)
        - average order value
        - average monthly spend
        - average items per order
===============================================================================
*/

-- =============================================================================
-- Create View: customer_report
-- =============================================================================
IF OBJECT_ID('customer_report', 'V') IS NOT NULL
    DROP VIEW customer_report;
GO

CREATE VIEW customer_report AS

WITH base_query AS (
/*---------------------------------------------------------------------------
1) Base Query: Retrieves core columns from tables
---------------------------------------------------------------------------*/
    SELECT
        o.order_id,
        o.customer_id,
        o.order_purchase_timestamp,
        oi.product_id,
        oi.price,
        oi.freight_value,
        (oi.price + oi.freight_value) AS total_item_revenue,
        c.customer_unique_id,
        c.customer_zip_code_prefix,
        c.customer_city,
        c.customer_state
    FROM order_items oi
    LEFT JOIN orders o ON oi.order_id = o.order_id
    LEFT JOIN customers c ON o.customer_id = c.customer_id
    WHERE o.order_purchase_timestamp IS NOT NULL
        AND o.order_status NOT IN ('canceled', 'unavailable')
),

customer_aggregation AS (
/*---------------------------------------------------------------------------
2) Customer Aggregations: Summarizes key metrics at the customer level
---------------------------------------------------------------------------*/
    SELECT 
        customer_id,
        customer_unique_id,
        customer_city,
        customer_state,
        customer_zip_code_prefix,
        COUNT(DISTINCT order_id) AS total_orders,
        SUM(price) AS total_sales,
        SUM(freight_value) AS total_freight,
        SUM(total_item_revenue) AS total_revenue,
        COUNT(*) AS total_items,
        COUNT(DISTINCT product_id) AS total_products,
        MIN(order_purchase_timestamp) AS first_order_date,
        MAX(order_purchase_timestamp) AS last_order_date,
        DATEDIFF(month, MIN(order_purchase_timestamp), MAX(order_purchase_timestamp)) AS lifespan
    FROM base_query
    GROUP BY 
        customer_id,
        customer_unique_id,
        customer_city,
        customer_state,
        customer_zip_code_prefix
)

/*---------------------------------------------------------------------------
3) Final Query: Adds segments and KPIs
---------------------------------------------------------------------------*/
SELECT
    customer_id,
    customer_unique_id,
    customer_city,
    customer_state,
    customer_zip_code_prefix,
    
    -- Customer Segmentation
    CASE 
        WHEN lifespan >= 6 AND total_sales > 1000 THEN 'VIP'
        WHEN lifespan >= 6 AND total_sales <= 1000 THEN 'Regular'
        WHEN total_orders > 1 THEN 'Repeat'
        ELSE 'One-time'
    END AS customer_segment,
    
    -- Date metrics
    first_order_date,
    last_order_date,
    DATEDIFF(month, last_order_date, GETDATE()) AS recency,
    lifespan,
    
    -- Aggregated metrics
    total_orders,
    total_sales,
    total_freight,
    total_revenue,
    total_items,
    total_products,
    
    -- KPIs
    CASE 
        WHEN total_orders = 0 THEN 0
        ELSE ROUND(total_revenue / total_orders, 2)
    END AS avg_order_value,
    
    CASE 
        WHEN total_orders = 0 THEN 0
        ELSE ROUND(CAST(total_items AS FLOAT) / total_orders, 2)
    END AS avg_items_per_order,
    
    CASE 
        WHEN lifespan = 0 THEN total_revenue
        ELSE ROUND(total_revenue / lifespan, 2)
    END AS avg_monthly_spend,
    
    ROUND(total_sales / NULLIF(total_items, 0), 2) AS avg_item_price

FROM customer_aggregation;
GO

-- Query the report (with ORDER BY in the SELECT, not in the view)
SELECT * FROM customer_report
ORDER BY total_revenue DESC;


/*
===============================================================================
Product Report - Olist E-commerce Dataset
===============================================================================
Purpose:
    - This report consolidates key product metrics and performance.

Highlights:
    1. Gathers essential fields such as product category, dimensions, and weight.
    2. Segments products by revenue to identify High-Performers, Mid-Range, or Low-Performers.
    3. Aggregates product-level metrics:
       - total orders
       - total sales
       - total quantity sold
       - total customers (unique)
       - lifespan (in months)
    4. Calculates valuable KPIs:
       - recency (months since last sale)
       - average order revenue (AOR)
       - average monthly revenue
       - average selling price
===============================================================================
*/

-- =============================================================================
-- Create View: product_report
-- =============================================================================
IF OBJECT_ID('product_report', 'V') IS NOT NULL
    DROP VIEW product_report;
GO

CREATE VIEW product_report AS

WITH base_query AS (
/*---------------------------------------------------------------------------
1) Base Query: Retrieves core columns from order_items and products
---------------------------------------------------------------------------*/
    SELECT
        o.order_id,
        o.order_purchase_timestamp,
        o.customer_id,
        oi.product_id,
        oi.seller_id,
        oi.price,
        oi.freight_value,
        p.product_category_name,
        p.product_name_lenght,
        p.product_description_lenght,
        p.product_photos_qty,
        p.product_weight_g,
        p.product_length_cm,
        p.product_height_cm,
        p.product_width_cm
    FROM order_items oi
    LEFT JOIN orders o ON oi.order_id = o.order_id
    LEFT JOIN products p ON oi.product_id = p.product_id
    WHERE o.order_purchase_timestamp IS NOT NULL
        AND o.order_status NOT IN ('canceled', 'unavailable')
),

product_aggregations AS (
/*---------------------------------------------------------------------------
2) Product Aggregations: Summarizes key metrics at the product level
---------------------------------------------------------------------------*/
    SELECT
        product_id,
        product_category_name,
        AVG(product_weight_g) AS avg_weight_g,
        AVG(product_length_cm * product_height_cm * product_width_cm) AS avg_volume_cm3,
        AVG(product_photos_qty) AS avg_photos,
        MIN(order_purchase_timestamp) AS first_sale_date,
        MAX(order_purchase_timestamp) AS last_sale_date,
        DATEDIFF(month, MIN(order_purchase_timestamp), MAX(order_purchase_timestamp)) AS lifespan,
        COUNT(DISTINCT order_id) AS total_orders,
        COUNT(DISTINCT customer_id) AS total_customers,
        COUNT(DISTINCT seller_id) AS total_sellers,
        SUM(price) AS total_sales,
        SUM(freight_value) AS total_freight,
        COUNT(*) AS total_quantity,
        ROUND(AVG(price), 2) AS avg_selling_price,
        ROUND(AVG(freight_value), 2) AS avg_freight_cost
    FROM base_query
    GROUP BY
        product_id,
        product_category_name
)

/*---------------------------------------------------------------------------
3) Final Query: Combines all product results with segments and KPIs
---------------------------------------------------------------------------*/
SELECT 
    product_id,
    product_category_name,
    
    -- Product characteristics
    ROUND(avg_weight_g, 2) AS avg_weight_g,
    ROUND(avg_volume_cm3, 2) AS avg_volume_cm3,
    ROUND(avg_photos, 1) AS avg_photos,
    
    -- Date metrics
    first_sale_date,
    last_sale_date,
    DATEDIFF(month, last_sale_date, GETDATE()) AS recency_in_months,
    lifespan,
    
    -- Product Performance Segment
    CASE
        WHEN total_sales > 10000 THEN 'High-Performer'
        WHEN total_sales >= 2000 THEN 'Mid-Range'
        ELSE 'Low-Performer'
    END AS product_segment,
    
    -- Aggregated metrics
    total_orders,
    total_customers,
    total_sellers,
    total_sales,
    total_freight,
    total_quantity,
    avg_selling_price,
    avg_freight_cost,
    
    -- KPIs
    CASE 
        WHEN total_orders = 0 THEN 0
        ELSE ROUND(total_sales / total_orders, 2)
    END AS avg_order_revenue,
    
    CASE
        WHEN lifespan = 0 THEN total_sales
        ELSE ROUND(total_sales / lifespan, 2)
    END AS avg_monthly_revenue,
    
    CASE
        WHEN total_customers = 0 THEN 0
        ELSE ROUND(total_sales / total_customers, 2)
    END AS avg_revenue_per_customer,
    
    -- Freight efficiency
    CASE
        WHEN total_sales = 0 THEN 0
        ELSE ROUND((total_freight / total_sales) * 100, 2)
    END AS freight_to_sales_ratio

FROM product_aggregations;
GO

-- Query the report (with ORDER BY in the SELECT, not in the view)
SELECT * FROM product_report
ORDER BY total_sales DESC;


/*
===============================================================================
Category Report - Olist E-commerce Dataset
===============================================================================
Purpose:
    - This report consolidates key metrics by product category.

Highlights:
    1. Aggregates category-level metrics
    2. Calculates market share and performance indicators
    3. Identifies top and bottom performing categories
===============================================================================
*/

-- =============================================================================
-- Create View: category_report
-- =============================================================================
IF OBJECT_ID('category_report', 'V') IS NOT NULL
    DROP VIEW category_report;
GO

CREATE VIEW category_report AS

WITH category_aggregations AS (
    SELECT
        p.product_category_name,
        COUNT(DISTINCT oi.product_id) AS total_products,
        COUNT(DISTINCT oi.order_id) AS total_orders,
        COUNT(DISTINCT o.customer_id) AS total_customers,
        SUM(oi.price) AS total_sales,
        SUM(oi.freight_value) AS total_freight,
        COUNT(*) AS total_items_sold,
        AVG(oi.price) AS avg_price,
        MIN(o.order_purchase_timestamp) AS first_sale_date,
        MAX(o.order_purchase_timestamp) AS last_sale_date
    FROM order_items oi
    LEFT JOIN orders o ON oi.order_id = o.order_id
    LEFT JOIN products p ON oi.product_id = p.product_id
    WHERE o.order_purchase_timestamp IS NOT NULL
        AND o.order_status NOT IN ('canceled', 'unavailable')
    GROUP BY p.product_category_name
)

SELECT
    product_category_name,
    total_products,
    total_orders,
    total_customers,
    total_sales,
    total_freight,
    total_items_sold,
    ROUND(avg_price, 2) AS avg_price,
    
    -- Market share
    CONCAT(
        ROUND((CAST(total_sales AS FLOAT) / SUM(total_sales) OVER ()) * 100, 2), 
        '%'
    ) AS sales_market_share,
    
    CONCAT(
        ROUND((CAST(total_items_sold AS FLOAT) / SUM(total_items_sold) OVER ()) * 100, 2), 
        '%'
    ) AS volume_market_share,
    
    -- KPIs
    ROUND(total_sales / NULLIF(total_orders, 0), 2) AS avg_order_value,
    ROUND(total_sales / NULLIF(total_customers, 0), 2) AS avg_customer_value,
    ROUND(CAST(total_items_sold AS FLOAT) / NULLIF(total_orders, 0), 2) AS avg_items_per_order,
    
    -- Date metrics
    first_sale_date,
    last_sale_date,
    DATEDIFF(month, first_sale_date, last_sale_date) AS category_lifespan

FROM category_aggregations;
GO

-- Query the report 
SELECT * FROM category_report
ORDER BY total_sales DESC;


/*
===============================================================================
Seller Report - Olist E-commerce Dataset
===============================================================================
Purpose:
    - This report consolidates key seller metrics and performance.
===============================================================================
*/

-- =============================================================================
-- Create View: seller_report
-- =============================================================================
IF OBJECT_ID('seller_report', 'V') IS NOT NULL
    DROP VIEW seller_report;
GO

CREATE VIEW seller_report AS

WITH seller_aggregations AS (
    SELECT
        oi.seller_id,
        s.seller_zip_code_prefix,
        s.seller_city,
        s.seller_state,
        COUNT(DISTINCT oi.product_id) AS total_products,
        COUNT(DISTINCT oi.order_id) AS total_orders,
        COUNT(DISTINCT o.customer_id) AS total_customers,
        SUM(oi.price) AS total_sales,
        SUM(oi.freight_value) AS total_freight,
        COUNT(*) AS total_items_sold,
        MIN(o.order_purchase_timestamp) AS first_sale_date,
        MAX(o.order_purchase_timestamp) AS last_sale_date,
        DATEDIFF(month, MIN(o.order_purchase_timestamp), MAX(o.order_purchase_timestamp)) AS lifespan
    FROM order_items oi
    LEFT JOIN orders o ON oi.order_id = o.order_id
    LEFT JOIN sellers s ON oi.seller_id = s.seller_id
    WHERE o.order_purchase_timestamp IS NOT NULL
        AND o.order_status NOT IN ('canceled', 'unavailable')
    GROUP BY 
        oi.seller_id,
        s.seller_zip_code_prefix,
        s.seller_city,
        s.seller_state
)

SELECT
    seller_id,
    seller_city,
    seller_state,
    seller_zip_code_prefix,
    
    -- Seller segment
    CASE
        WHEN total_sales > 20000 THEN 'Top Seller'
        WHEN total_sales >= 5000 THEN 'Mid-tier Seller'
        ELSE 'Small Seller'
    END AS seller_segment,
    
    -- Aggregated metrics
    total_products,
    total_orders,
    total_customers,
    total_sales,
    total_freight,
    total_items_sold,
    
    -- Date metrics
    first_sale_date,
    last_sale_date,
    DATEDIFF(month, last_sale_date, GETDATE()) AS recency,
    lifespan,
    
    -- KPIs
    ROUND(total_sales / NULLIF(total_orders, 0), 2) AS avg_order_value,
    ROUND(total_sales / NULLIF(lifespan, 0), 2) AS avg_monthly_revenue,
    ROUND(CAST(total_items_sold AS FLOAT) / NULLIF(total_orders, 0), 2) AS avg_items_per_order,
    ROUND(total_sales / NULLIF(total_customers, 0), 2) AS avg_customer_value

FROM seller_aggregations;
GO

-- Query the report
SELECT * FROM seller_report

ORDER BY total_sales DESC;
