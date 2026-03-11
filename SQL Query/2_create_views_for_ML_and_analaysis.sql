USE olist;

-- EXAMING TABLES

SELECT * FROM customers LIMIT 10;

SELECT * FROM geolocation LIMIT 10;

SELECT * FROM order_items LIMIT 10;

SELECT * FROM order_payments LIMIT 10;

SELECT * FROM order_reviews LIMIT 10;

SELECT * FROM orders LIMIT 10;

SELECT * FROM product_categories LIMIT 10;

SELECT * FROM products LIMIT 10;

SELECT * FROM sellers LIMIT 10;

-- Order revenue (items aggregate)
SELECT * FROM order_items LIMIT 10;

CREATE OR REPLACE VIEW v_order_revenue AS
SELECT
	order_id,
    SUM(price) AS total_price,
    SUM(freight_value) AS total_freight,
    SUM(price + freight_value) AS total_revenue,
    COUNT(*) AS item_count
FROM order_items
GROUP BY order_id;

SELECT * FROM v_order_revenue LIMIT 10;

-- Payment summary (payments aggregate)
SELECT * FROM order_payments LIMIT 10;

CREATE OR REPLACE VIEW v_order_payments AS
SELECT
	order_id,
    SUM(payment_value) AS total_payment,
    MAX(payment_installments) AS max_installments,
    COUNT(*) AS payment_count
FROM order_payments
GROUP BY order_id;

SELECT * FROM v_order_payments LIMIT 10;

-- Review summary (order-level)
-- Our goal is to receive the latest feedback on every order.
SELECT * FROM order_reviews LIMIT 10;

CREATE OR REPLACE VIEW v_order_reviews AS
SELECT
	order_id,
    review_score,
    review_comment_title,
    review_comment_message,
    review_creation_date
FROM(
	SELECT
		order_id,
		review_score,
		review_comment_title,
		review_comment_message,
		review_creation_date,
		ROW_NUMBER() OVER w AS row_num
	FROM order_reviews
	WINDOW w AS (PARTITION BY order_id ORDER BY review_creation_date DESC)) a
WHERE a.row_num = 1;

SELECT * FROM v_order_reviews LIMIT 10;

-- Product category
SELECT * FROM order_items LIMIT 10;
SELECT * FROM products LIMIT 10;
SELECT * FROM product_categories LIMIT 10;


-- The most dominant category in the order.
CREATE OR REPLACE VIEW v_order_main_category AS
SELECT
  t.order_id,
  pc.product_category_name_english AS product_category_name,
  t.item_count
FROM (
  SELECT
    oi.order_id,
    p.product_category_name,
    COUNT(*) AS item_count,
    ROW_NUMBER() OVER (
      PARTITION BY oi.order_id
      ORDER BY COUNT(*) DESC, p.product_category_name
    ) AS rn
  FROM order_items oi
  JOIN products p ON p.product_id = oi.product_id
  GROUP BY oi.order_id, p.product_category_name
) t
JOIN product_categories pc
  ON pc.product_category_name = t.product_category_name
WHERE t.rn = 1;

SELECT * FROM v_order_main_category LIMIT 10;

-- Is the order a single category or a mixed order?
CREATE OR REPLACE VIEW v_order_category_type AS
SELECT
	oi.order_id,
    COUNT(DISTINCT p.product_category_name) AS category_count,
    CASE
		WHEN COUNT(DISTINCT p.product_category_name) = 1 THEN 'Single'
        ELSE 'Multi'
	END AS order_type
FROM order_items oi
JOIN products p ON p.product_id = oi.product_id
GROUP BY oi.order_id;

SELECT * FROM v_order_category_type LIMIT 10;

-- All Categories in the Order
CREATE OR REPLACE VIEW v_order_all_categories AS
SELECT
	oi.order_id,
    GROUP_CONCAT(DISTINCT pc.product_category_name_english
				ORDER BY pc.product_category_name_english
                SEPARATOR ',') AS categories
FROM order_items oi
JOIN products p ON p.product_id = oi.product_id
JOIN product_categories pc ON pc.product_category_name = p.product_category_name
GROUP BY oi.order_id;

SELECT * FROM v_order_all_categories LIMIT 10;

-- Expenditure-Based Main Category

CREATE OR REPLACE VIEW v_order_main_category_revenue AS
SELECT
  order_id,
  pc.product_category_name_english AS product_category_name,
  revenue
FROM (
  SELECT
    oi.order_id,
    p.product_category_name,
    SUM(oi.price + oi.freight_value) AS revenue,
    ROW_NUMBER() OVER (
      PARTITION BY oi.order_id
      ORDER BY SUM(oi.price + oi.freight_value) DESC, p.product_category_name
    ) AS row_num
  FROM order_items oi
  JOIN products p ON p.product_id = oi.product_id
  GROUP BY oi.order_id, p.product_category_name
) t
JOIN product_categories pc ON pc.product_category_name = t.product_category_name
WHERE row_num = 1;

SELECT * FROM v_order_main_category_revenue LIMIT 10;

-- Create order_fact view

SELECT * FROM v_order_revenue  LIMIT 10;

CREATE OR REPLACE VIEW v_order_fact AS
SELECT
	o.order_id,
    o.customer_id,
    o.order_status,
    
	-- timestamps
    o.order_purchase_timestamp AS purchase_ts,
    o.order_approved_at AS approved_ts,
    o.order_delivered_carrier_date AS carrier_ts,
    o.order_delivered_customer_date AS delivered_ts,
    o.order_estimated_delivery_date AS est_delivery_ts,
    
    -- delivery KPIs
    CASE
		WHEN o.order_delivered_customer_date IS NULL THEN NULL
        ELSE DATEDIFF(o.order_delivered_customer_date, o.order_purchase_timestamp)
	END AS days_to_deliver,
    
    CASE
		WHEN o.order_delivered_customer_date IS NULL THEN NULL
        WHEN o.order_delivered_customer_date > o.order_estimated_delivery_date THEN 1
        ELSE 0
	END AS is_late,
    
    -- revenue
    r.total_price,
	r.total_freight,
	r.total_revenue,
	r.item_count,
    
    -- payments
    p.total_payment,
    p.payment_count,
    p.max_installments,
    (p.total_payment - r.total_revenue) AS payment_minus_revenue,
    
    -- reviews (latest)
    rv.review_score,
    rv.review_comment_title,
    rv.review_comment_message,
    rv.review_creation_date,
    
    -- category features
	mc.product_category_name AS main_category_by_item,
	mcr.product_category_name AS main_category_by_revenue,
	ct.category_count,
	ct.order_type,
	ac.categories AS all_categories
    
    FROM orders o
    LEFT JOIN v_order_revenue r
		ON r.order_id = o.order_id
	LEFT JOIN v_order_payments p
		ON p.order_id = o.order_id
	LEFT JOIN v_order_reviews rv
		ON rv.order_id = o.order_id
	LEFT JOIN v_order_main_category mc
		ON mc.order_id = o.order_id
	LEFT JOIN v_order_main_category_revenue mcr
		ON mcr.order_id = o.order_id
	LEFT JOIN v_order_category_type ct
		ON ct.order_id = o.order_id
	LEFT JOIN v_order_all_categories ac
		ON ac.order_id = o.order_id;
        
SELECT * FROM v_order_fact  LIMIT 10;

CREATE OR REPLACE VIEW v_order_fact_delivered AS
SELECT *
FROM v_order_fact
WHERE order_status = 'delivered'
  AND delivered_ts IS NOT NULL;
  
SELECT * FROM v_order_fact_delivered  LIMIT 10;
        

    
		



