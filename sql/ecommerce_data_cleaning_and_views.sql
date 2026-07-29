Add SQL data cleaning script.


/*
===============================================================================
Project Name : Olist E-Commerce Data Analysis
Author       : Muhammad Shah
Tool         : Microsoft SQL Server (SSMS)
Description  : End-to-end SQL analysis covering sales performance, 
               logistics & shipping metrics, customer acquisition, 
               and payment behavior.
===============================================================================
*/    

-=========================CREATING VIEWS FOR ALL RAW TABLES AND MAKE THEM CLEAN===========================-
---(1)..View Create for raw orders data to change data type
CREATE VIEW vw_clean_orders AS
SELECT 
    order_id,
    customer_id,
    order_status,
    CAST(order_purchase_timestamp AS DATETIME) AS order_purchase_timestamp,
    CAST(order_approved_at AS DATETIME) AS order_approved_at,
    CAST(order_delivered_carrier_date AS DATETIME) AS order_delivered_carrier_date,
    CAST(order_delivered_customer_date AS DATETIME) AS order_delivered_customer_date,
    CAST(order_estimated_delivery_date AS DATETIME) AS order_estimated_delivery_date
FROM raw_orders

---(1)..View Create for raw orders data to change data type
SELECT TOP 10 * FROM vw_clean_orders

--(2)..view create for raw order items data  to change data type 
SELECT TOP 10 * FROM raw_order_items;

CREATE VIEW vw_clean_order_items AS
(
SELECT
order_id,
order_item_id,
product_id,
seller_id,
CAST(shipping_limit_date AS datetime) AS shipping_limit_date,
CAST(price AS DECIMAL(10,2)) AS price,
CAST(freight_value AS DECIMAL(10,2)) AS freight_value
FROM raw_order_items
)
--(2)..view create for raw order items data  to change data type 
SELECT TOP 10 * FROM vw_clean_order_items


--(3)..Create view for olist products
ALTER VIEW vw_clean_products AS
SELECT 
    product_id,
    product_category_name,
    TRY_CAST(product_name_lenght AS INT) AS product_name_length,
    TRY_CAST(product_description_lenght AS INT) AS product_description_length,
    TRY_CAST(product_photos_qty AS INT) AS product_photos_qty,
    TRY_CAST(product_weight_g AS FLOAT) AS product_weight_g,
    TRY_CAST(product_length_cm AS FLOAT) AS product_length_cm,
    TRY_CAST(product_height_cm AS FLOAT) AS product_height_cm,
    TRY_CAST(product_width_cm AS FLOAT) AS product_width_cm
FROM raw_products;
--(3)..Create view for olist products
SELECT TOP 10 * FROM vw_clean_products

--(4).. Create view for raw_category_translation 
CREATE VIEW vw_clean_category_translation AS
SELECT 
    TRIM(CAST(column1 AS nvarchar(100))) AS product_category_name,
    TRIM(CAST(column2 AS nvarchar(100))) AS product_category_name_english
FROM raw_category_translation;
--(4).. Create view for raw_category_translation
SELECT TOP 10 * FROM vw_clean_category_translation

--(5)..create view for raw_order_payments
CREATE VIEW vw_clean_order_payments AS

SELECT
    TRIM(CAST(order_id AS nvarchar(50))) AS order_id,
    TRIM(CAST(payment_type AS nvarchar(50))) AS payment_type,
TRY_CAST(payment_sequential AS INT) AS payment_sequential,
TRY_CAST(payment_installments AS INT) AS payment_installments,
TRY_CAST(payment_value AS FLOAT) AS payment_value
FROM raw_order_payments


--(5)..create view for raw_order_payments
SELECT TOP 10 * FROM vw_clean_order_payments


--(6)..How much total money did we make(total_revenue) and total_delivered_orders?
CREATE VIEW total_revenue_and_total_orders AS
(
SELECT
SUM(COI.price) AS total_product_revenue,
SUM(COI.price + COI.freight_value) AS total_revenue_with_freight_value,
COUNT(DISTINCT CO.order_id) AS total_delivered_orders
FROM 
vw_clean_order_items AS COI
JOIN vw_clean_orders AS CO
ON COI.order_id = CO.order_id
WHERE order_status = 'delivered'
)
--(6)..How much total money did we make(total_revenue) and total_delivered_orders?
SELECT * FROM total_revenue_and_total_orders

--(7)..create view for raw customers olist 
CREATE VIEW vw_clean_customers AS
SELECT
    TRIM(CAST(customer_id AS nvarchar(50))) AS customer_id,
    TRIM(CAST(customer_unique_id AS nvarchar(50))) AS customer_unique_id,
    TRIM(CAST(customer_zip_code_prefix AS nvarchar(10))) AS customer_zip_code_prefix,
    TRIM(CAST(customer_city AS nvarchar(100))) AS customer_city,
    TRIM(CAST(customer_state AS nvarchar(10))) AS customer_state
FROM raw_customers;
--(7)..create view for raw customers olist 
SELECT TOP 10 * FROM vw_clean_customers


--(8)..create view for raw seller 
CREATE VIEW vw_clean_sellers AS
SELECT
    TRIM(CAST(seller_id AS nvarchar(50))) AS seller_id,
    TRIM(CAST(seller_zip_code_prefix AS nvarchar(10))) AS seller_zip_code_prefix,
    TRIM(CAST(seller_city AS nvarchar(100))) AS seller_city,
    TRIM(CAST(seller_state AS nvarchar(10))) AS seller_state
FROM raw_seller
--(8)..create view for raw seller 
SELECT TOP 5 * FROM vw_clean_sellers

--(9)..create view for raw orders reviews 
CREATE VIEW vw_clean_order_reviews AS
SELECT 
TRY_CAST(review_id AS nvarchar(50)) AS review_id,
TRY_CAST(order_id AS nvarchar(50)) AS order_id,
TRY_CAST(review_score AS INT) AS review_score,
TRY_CAST(review_comment_title AS nvarchar(255)) AS review_comment_title,
TRY_CAST(review_comment_message AS nvarchar(max)) AS review_comment_message,
TRY_CAST(review_creation_date AS DATETIME) AS review_creation_date,
TRY_CAST(review_answer_timestamp AS DATETIME) AS review_answer_timestamp
FROM raw_order_reviews

--(9)..create view for raw orders reviews
SELECT TOP 10 * FROM vw_clean_order_reviews

--(10)..What percentage of our total orders are delivered vs. canceled (or other statuses)?

SELECT
COUNT(*) AS total_orders,
order_status,
(COUNT(*) * 100.0) / (SELECT COUNT(*) FROM vw_clean_orders) AS status_percentage
FROM vw_clean_orders
GROUP BY order_status
ORDER BY total_orders DESC


--11)..Find the Top 10 product categories ranked by total revenue, 
--including the English category name and the total number of items sold.
SELECT TOP 10
    ISNULL(CCT.product_category_name_english, CP.product_category_name) AS category_name,
    SUM(COI.price + COI.freight_value) AS total_revenue_with_freight,
    COUNT(COI.order_item_id) AS total_items_sold
FROM vw_clean_orders AS CO
JOIN vw_clean_order_items AS COI
    ON CO.order_id = COI.order_id
JOIN vw_clean_products AS CP
    ON COI.product_id = CP.product_id
LEFT JOIN vw_clean_category_translation AS CCT
    ON CP.product_category_name = CCT.product_category_name
WHERE CO.order_status = 'delivered'
GROUP BY ISNULL(CCT.product_category_name_english, CP.product_category_name)
ORDER BY total_revenue_with_freight DESC;


--(12)..How is our overall revenue trending month-over-month? Are we growing or declining over time?
SELECT
MONTH(CO.order_purchase_timestamp) AS Month,
YEAR(CO.order_purchase_timestamp) AS Year,
SUM(COI.price + COI.freight_value) AS Total_revenue_with_freight
FROM vw_clean_orders AS CO
JOIN vw_clean_order_items AS COI
ON CO.order_id = COI.order_id
WHERE CO.order_status = 'delivered'
GROUP BY YEAR(CO.order_purchase_timestamp),MONTH(CO.order_purchase_timestamp)
ORDER BY Year ASC,
         Month ASC


--(13)..What percentage of our delivered orders arrived late (after the estimated delivery date), 
--and what is our average delivery time in days?
SELECT
COUNT(order_id)  AS total_delivered_orders,

SUM(CASE 
        WHEN order_delivered_customer_date > order_estimated_delivery_date THEN 1
        ELSE 0
        END) AS late_orders_count,
(SUM(CASE WHEN order_delivered_customer_date > order_estimated_delivery_date THEN 1 
ELSE 0 
END) * 100.0) / COUNT(order_id) AS late_delivery_percentage,

AVG(DATEDIFF(DAY, order_purchase_timestamp, order_delivered_customer_date)) AS avg_delivery_days

FROM vw_clean_orders
WHERE order_status = 'delivered' 
  AND order_delivered_customer_date IS NOT NULL;



--(14)..Which 5 product categories have the highest average shipping cost (freight value) per item?
SELECT TOP 5 
    ISNULL(CCT.product_category_name_english, CP.product_category_name) AS category_name,
    AVG(COI.freight_value) AS avg_shipping_cost
FROM vw_clean_orders AS CO
JOIN vw_clean_order_items AS COI 
    ON CO.order_id = COI.order_id
JOIN vw_clean_products AS CP 
    ON COI.product_id = CP.product_id
LEFT JOIN vw_clean_category_translation AS CCT 
    ON CP.product_category_name = CCT.product_category_name
WHERE CO.order_status = 'delivered'
GROUP BY ISNULL(CCT.product_category_name_english, CP.product_category_name)
ORDER BY avg_shipping_cost DESC;



--(15)..How is customer payment choice distributed across credit card, boleto, voucher, 
--and debit card in terms of total payment value and transaction volume?
SELECT
COP.payment_type,
COUNT(CO.order_id) AS total_transactions,
SUM(COP.payment_value) AS total_payment_value
FROM vw_clean_orders AS CO
JOIN vw_clean_order_payments COP 
ON CO.order_id = COP.order_id
WHERE CO.order_status = 'delivered'
GROUP BY COP.payment_type
ORDER BY total_payment_value DESC



--(16).."Which top 10 customer cities generate the highest total order revenue for delivered orders?"
SELECT TOP 10
    CC.customer_city,
        SUM(COI.price + COI.freight_value) AS total_revenue_with_freight,
        COUNT(CO.order_id) AS total_orders
FROM vw_clean_orders AS CO
JOIN vw_clean_customers AS CC
    ON CO.customer_id = CC.customer_id
JOIN vw_clean_order_items AS COI
    ON CO.order_id = COI.order_id
        WHERE CO.order_status = 'delivered'
        GROUP BY CC.customer_city
        ORDER BY total_revenue_with_freight DESC;


--(17)..What is our overall Average Order Value (AOV)â€”including item prices and freightâ€”across all delivered orders?
SELECT 
SUM(COI.price + COI.freight_value) AS Total_revenue,
COUNT(DISTINCT CO.order_id) AS Total_orders,
(SUM(COI.price + COI.freight_value) * 1.0)/ COUNT(DISTINCT CO.order_id) AS AOV
FROM vw_clean_orders AS CO
JOIN vw_clean_order_items AS COI
ON CO.order_id = COI.order_id
WHERE CO.order_status = 'delivered'


------------------Seller Performance & Delivery Metrics----------------------------------



--(18)..Which seller states have the highest proportion of late deliveries for delivered orders, 
--and how many total orders do they ship?
SELECT
    CS.seller_state,
    COUNT(DISTINCT CO.order_id) AS total_orders,
    COUNT(DISTINCT CASE WHEN CO.order_delivered_customer_date > CO.order_estimated_delivery_date THEN CO.order_id END) AS late_orders,
    ROUND(
        (COUNT(DISTINCT CASE WHEN CO.order_delivered_customer_date > CO.order_estimated_delivery_date THEN CO.order_id END) * 100.0) 
        / COUNT(DISTINCT CO.order_id), 2
    ) AS late_delivery_pct
FROM vw_clean_orders AS CO
JOIN vw_clean_order_items AS COI 
    ON CO.order_id = COI.order_id
JOIN vw_clean_sellers AS CS 
    ON COI.seller_id = CS.seller_id
WHERE CO.order_status = 'delivered'
GROUP BY CS.seller_state
HAVING COUNT(DISTINCT CO.order_id) >= 100
ORDER BY late_delivery_pct DESC;

--(19)..Which top 5 product categories generate the highest total revenue (price + freight) for delivered orders?
SELECT TOP 5
COUNT(COI.order_item_id) AS total_items_sold,
CP.product_category_name,
SUM(COI.price + COI.freight_value) AS total_revenue
FROM vw_clean_orders AS CO
JOIN vw_clean_order_items AS COI
ON CO.order_id = COI.order_id
JOIN vw_clean_products AS CP
ON COI.product_id = CP.product_id
WHERE order_status = 'delivered'
GROUP BY CP.product_category_name
ORDER BY total_revenue DESC


--(20)..What is the average actual delivery time (in days) for delivered orders, broken down by customer state?
SELECT
CC.customer_state,
COUNT(DISTINCT CO.order_id) AS total_delivered_orders,
ROUND(AVG(DATEDIFF(DAY,CO.order_purchase_timestamp,CO.order_delivered_customer_date) * 1.0) ,2) AS avg_delivery_days
FROM vw_clean_orders AS CO
JOIN vw_clean_order_items AS COI
ON CO.order_id = COI.order_id
JOIN vw_clean_customers AS CC
ON CO.customer_id = CC.customer_id
WHERE order_status = 'delivered'
GROUP BY customer_state
ORDER BY avg_delivery_days DESC;



--(21)..What is the average customer review score for orders delivered on time versus orders delivered late?
SELECT
CASE
    WHEN order_delivered_customer_date > order_estimated_delivery_date THEN 'On-Time'
    ELSE 'Late'
END AS late_delivery,
COUNT(COR.review_id) AS total_reviews,
ROUND(AVG(COR.review_score * 1.0), 2) AS avg_review_score
FROM vw_clean_orders AS CO
JOIN vw_clean_order_reviews AS COR
ON CO.order_id = COR.order_id
WHERE order_status = 'delivered'
GROUP BY CASE
              WHEN order_delivered_customer_date > order_estimated_delivery_date THEN 'On-Time'
              ELSE 'Late'
        END;


--(22)..Who are the top 10 sellers overall in terms of total sales volume (number of items sold) 
--and total revenue generated for delivered orders?
SELECT TOP 10
CS.seller_id,
CS.seller_city,
CS.seller_state,
COUNT(DISTINCT COI.order_item_id) AS Total_sales_volume,
ROUND(SUM(COI.price + COI.freight_value),2) AS total_revenue
FROM vw_clean_orders AS CO
JOIN vw_clean_order_items AS COI
ON CO.order_id = COI.order_id
JOIN vw_clean_sellers AS CS
ON COI.seller_id = CS.seller_id
WHERE order_status = 'delivered'
GROUP BY 
    CS.seller_id,
    CS.seller_city,
    CS.seller_state
ORDER BY total_revenue DESC;


--------------Customer Retention, Payment Preferences & Advanced Cohort Analysis-----------------

--(23)...What is the breakdown of order volume, total payment value,
--and average payment value by payment type for delivered orders?"
SELECT
    COP.payment_type,
    COUNT(DISTINCT CO.order_id) AS total_orders,
    ROUND(SUM(COP.payment_value), 2) AS total_payment_value,
    ROUND(AVG(COP.payment_value * 1.0), 2) AS avg_payment_value
FROM vw_clean_orders AS CO
JOIN vw_clean_order_payments AS COP
    ON CO.order_id = COP.order_id
WHERE CO.order_status = 'delivered'
GROUP BY COP.payment_type
ORDER BY total_payment_value DESC;



--(24)..What percentage of unique customers have placed more than one delivered order (repeat customers)

WITH CustomerOrderCounts AS (
    SELECT 
        CC.customer_unique_id,
        COUNT(DISTINCT CO.order_id) AS total_orders
    FROM vw_clean_orders AS CO
    JOIN vw_clean_customers AS CC 
        ON CO.customer_id = CC.customer_id
    WHERE CO.order_status = 'delivered'
    GROUP BY CC.customer_unique_id
)
SELECT 
    COUNT(CASE WHEN total_orders > 1 THEN 1 END) AS repeat_customers,
    COUNT(*) AS total_customers,
    ROUND(
        (COUNT(CASE WHEN total_orders > 1 THEN 1.0 END) / COUNT(*)) * 100, 
        2
    ) AS repeat_customer_percentage
FROM CustomerOrderCounts;


--(25)..What is the monthly customer acquisition count (first-time buyers) 
--and monthly revenue trend for delivered orders across the entire dataset?
WITH FirstPurchase AS (
    SELECT 
        CC.customer_unique_id,
        MIN(CO.order_purchase_timestamp) AS first_order_date
    FROM vw_clean_orders AS CO
    JOIN vw_clean_customers AS CC 
        ON CO.customer_id = CC.customer_id
    WHERE CO.order_status = 'delivered'
    GROUP BY CC.customer_unique_id
),
MonthlyAcquisition AS (
    SELECT 
        FORMAT(first_order_date, 'yyyy-MM') AS year_month,
        COUNT(customer_unique_id) AS new_customers
    FROM FirstPurchase
    GROUP BY FORMAT(first_order_date, 'yyyy-MM')
),
MonthlyRevenue AS (
    SELECT 
        FORMAT(CO.order_purchase_timestamp, 'yyyy-MM') AS year_month,
        ROUND(SUM(COI.price + COI.freight_value), 2) AS total_revenue
    FROM vw_clean_orders AS CO
    JOIN vw_clean_order_items AS COI 
        ON CO.order_id = COI.order_id
    WHERE CO.order_status = 'delivered'
    GROUP BY FORMAT(CO.order_purchase_timestamp, 'yyyy-MM')
)
SELECT 
    MR.year_month,
    ISNULL(MA.new_customers, 0) AS new_customers_acquired,
    MR.total_revenue
FROM MonthlyRevenue AS MR
LEFT JOIN MonthlyAcquisition AS MA 
    ON MR.year_month = MA.year_month
ORDER BY MR.year_month ASC;

--(26)..or each monthly customer cohort (grouped by their first purchase month), 
--what percentage of those customers return to make another purchase within 30, 90, and 180 days?
WITH CustomerFirstOrder AS (
    -- Step 1: Find the first order date for every unique customer
    SELECT 
        CC.customer_unique_id,
        MIN(CO.order_purchase_timestamp) AS first_order_date,
        FORMAT(MIN(CO.order_purchase_timestamp), 'yyyy-MM') AS cohort_month
    FROM vw_clean_orders AS CO
    JOIN vw_clean_customers AS CC 
        ON CO.customer_id = CC.customer_id
    WHERE CO.order_status = 'delivered'
    GROUP BY CC.customer_unique_id
),
CustomerAllOrders AS (
    -- Step 2: Get all delivered order dates for each customer
    SELECT DISTINCT
        CC.customer_unique_id,
        CO.order_purchase_timestamp AS order_date
    FROM vw_clean_orders AS CO
    JOIN vw_clean_customers AS CC 
        ON CO.customer_id = CC.customer_id
    WHERE CO.order_status = 'delivered'
),
CohortActivity AS (
    -- Step 3: Calculate days between first purchase and subsequent purchases
    SELECT 
        FO.cohort_month,
        FO.customer_unique_id,
        DATEDIFF(day, FO.first_order_date, AO.order_date) AS days_since_first_order
    FROM CustomerFirstOrder AS FO
    JOIN CustomerAllOrders AS AO 
        ON FO.customer_unique_id = AO.customer_unique_id
)
-- Step 4: Aggregate cohort numbers and calculate retention percentages
WITH CustomerFirstOrder AS (
    -- Step 1: Find the first order date for every unique customer
    SELECT 
        CC.customer_unique_id,
        MIN(CO.order_purchase_timestamp) AS first_order_date,
        FORMAT(MIN(CO.order_purchase_timestamp), 'yyyy-MM') AS cohort_month
    FROM vw_clean_orders AS CO
    JOIN vw_clean_customers AS CC 
        ON CO.customer_id = CC.customer_id
    WHERE CO.order_status = 'delivered'
    GROUP BY CC.customer_unique_id
),
CustomerAllOrders AS (
    -- Step 2: Get all delivered order dates for each customer
    SELECT DISTINCT
        CC.customer_unique_id,
        CO.order_purchase_timestamp AS order_date
    FROM vw_clean_orders AS CO
    JOIN vw_clean_customers AS CC 
        ON CO.customer_id = CC.customer_id
    WHERE CO.order_status = 'delivered'
),
CohortActivity AS (
    -- Step 3: Calculate days between first purchase and subsequent purchases
    SELECT 
        FO.cohort_month,
        FO.customer_unique_id,
        DATEDIFF(day, FO.first_order_date, AO.order_date) AS days_since_first_order
    FROM CustomerFirstOrder AS FO
    JOIN CustomerAllOrders AS AO 
        ON FO.customer_unique_id = AO.customer_unique_id
)
