USE olist;

-- Power BI order base

CREATE OR REPLACE VIEW vw_pbi_order_base AS
SELECT
    order_id,
    customer_unique_id,
    purchase_ts,

    DATE_FORMAT(purchase_ts, '%Y-%m-01') AS month_start_date,
    YEAR(purchase_ts) AS purchase_year,
    MONTH(purchase_ts) AS purchase_month,
    DATE_FORMAT(purchase_ts, '%Y-%m') AS yearmonth,

    COALESCE(TRIM(REPLACE(order_type, '\r', '')), 'Canceled') AS order_type,
    COALESCE(TRIM(REPLACE(main_category_by_revenue, '\r', '')), 'No Category') AS main_category_by_revenue,

    customer_state,

    COALESCE(total_revenue,0) AS total_revenue,
    COALESCE(total_price,0) AS total_price,
    COALESCE(total_freight,0) AS total_freight,

    item_count,
    days_to_deliver,
    is_late,
    review_score

FROM v_order_fact
WHERE purchase_ts IS NOT NULL;

SELECT * FROM vw_pbi_order_base LIMIT 10;

-- Common slicer tables
CREATE OR REPLACE VIEW dim_pbi_month AS
SELECT DISTINCT
    DATE_FORMAT(purchase_ts, '%Y-%m-01') AS month_start_date,
    YEAR(purchase_ts) AS purchase_year,
    MONTH(purchase_ts) AS purchase_month,
    DATE_FORMAT(purchase_ts, '%Y-%m') AS yearmonth
FROM v_order_fact
WHERE purchase_ts IS NOT NULL;

CREATE OR REPLACE VIEW dim_pbi_order_type AS
SELECT DISTINCT
    order_type
FROM vw_pbi_order_base
WHERE order_type IS NOT NULL
  AND order_type <> '';

-- Customer latest order context
CREATE OR REPLACE VIEW vw_customer_latest_order_context AS
SELECT
    x.customer_unique_id,
    x.order_id,
    x.purchase_ts,
    x.month_start_date,
    x.purchase_year,
    x.purchase_month,
    x.yearmonth,
    x.order_type,
    x.customer_state
FROM (
    SELECT
        customer_unique_id,
        order_id,
        purchase_ts,
        DATE_FORMAT(purchase_ts, '%Y-%m-01') AS month_start_date,
        YEAR(purchase_ts) AS purchase_year,
        MONTH(purchase_ts) AS purchase_month,
        DATE_FORMAT(purchase_ts, '%Y-%m') AS yearmonth,
        COALESCE(TRIM(REPLACE(order_type, '\r', '')), 'Canceled') AS order_type,
        COALESCE(customer_state, 'Unknown') AS customer_state,
        ROW_NUMBER() OVER (
            PARTITION BY customer_unique_id
            ORDER BY purchase_ts DESC, order_id DESC
        ) AS rn
    FROM v_order_fact
    WHERE purchase_ts IS NOT NULL
      AND customer_unique_id IS NOT NULL
) x
WHERE x.rn = 1;

SELECT * FROM vw_customer_latest_order_context LIMIT 10;

-- Executive Overview
-- KPI's
CREATE OR REPLACE VIEW vw_exec_kpi_source AS
SELECT
	month_start_date,
    purchase_year,
    purchase_month,
    yearmonth,
    order_type,
    
    SUM(total_revenue) AS total_revenue,
    COUNT(DISTINCT order_id) AS total_orders,
    COUNT(DISTINCT customer_unique_id) AS unique_customers,
    AVG(total_revenue) AS avg_order_value
FROM vw_pbi_order_base
GROUP BY
    month_start_date,
    purchase_year,
    purchase_month,
    yearmonth,
    order_type;
    
SELECT * FROM vw_exec_kpi_source LIMIT 10;

-- Monthly revenue trend

CREATE OR REPLACE VIEW vw_exec_monthly_revenue AS
SELECT
    month_start_date,
    purchase_year,
    purchase_month,
    yearmonth,
    order_type,
    SUM(total_revenue) AS monthly_revenue,
    COUNT(DISTINCT order_id) AS total_orders
FROM vw_pbi_order_base
GROUP BY
    month_start_date,
    purchase_year,
    purchase_month,
    yearmonth,
    order_type;
    
SELECT * FROM vw_exec_monthly_revenue LIMIT 10;

-- Top categories

CREATE OR REPLACE VIEW vw_exec_top_categories AS
SELECT
    month_start_date,
    purchase_year,
    purchase_month,
    yearmonth,
    order_type,
    main_category_by_revenue AS category,
    SUM(total_revenue) AS total_revenue,
    COUNT(DISTINCT order_id) AS total_orders
FROM vw_pbi_order_base
WHERE main_category_by_revenue IS NOT NULL
  AND main_category_by_revenue <> ''
GROUP BY
    month_start_date,
    purchase_year,
    purchase_month,
    yearmonth,
    order_type,
    main_category_by_revenue;
    
SELECT * FROM vw_exec_top_categories LIMIT 10;

-- Revenue by state
CREATE OR REPLACE VIEW vw_exec_state_revenue AS
SELECT
    month_start_date,
    purchase_year,
    purchase_month,
    yearmonth,
    order_type,
    customer_state,
    SUM(total_revenue) AS total_revenue,
    COUNT(DISTINCT order_id) AS total_orders
FROM vw_pbi_order_base
WHERE customer_state IS NOT NULL
  AND customer_state <> ''
GROUP BY
    month_start_date,
    purchase_year,
    purchase_month,
    yearmonth,
    order_type,
    customer_state;

SELECT * FROM vw_exec_state_revenue LIMIT 10;