USE olist;

DROP VIEW IF EXISTS vw_kpi_clv_executive,  vw_clv_distribution, vw_clv_segment_distribution, vw_clv_by_state, vw_clv_monthly_trend;

SELECT * FROM clv_customer_segments LIMIT 10;

SELECT * FROM nbd_summary LIMIT 10;

SELECT * FROM vw_customer_latest_order_context LIMIT 10;

SELECT COUNT(DISTINCT customer_unique_id)
FROM vw_customer_latest_order_context;

SELECT COUNT(DISTINCT customer_unique_id)
FROM clv_customer_segments;

SELECT COUNT(DISTINCT customer_unique_id)
FROM nbd_summary;

CREATE OR REPLACE VIEW vw_clv_pbi AS
SELECT
    c.customer_unique_id,
    c.order_id,
    c.purchase_ts,
    c.month_start_date,
    c.purchase_year,
    c.purchase_month,
    c.yearmonth,
    c.order_type,
    c.customer_state,

    clv.total_transaction,
    clv.total_unit,
    clv.total_price,
    clv.average_order_value,
    clv.purchase_frequency,
    clv.profit_margin,
    clv.customer_value,
    clv.cltv,
    clv.segment,

    nbd.frequency,
    nbd.recency,
    nbd.T,
    nbd.monetary_value,
    nbd.expected_purc_1_week,
    nbd.expected_purc_1_month,
    nbd.expected_purc_3_month

FROM vw_customer_latest_order_context c
LEFT JOIN clv_customer_segments clv
    ON c.customer_unique_id = clv.customer_unique_id
LEFT JOIN nbd_summary nbd
    ON c.customer_unique_id = nbd.customer_unique_id;
    
## createing analyses base
    
CREATE OR REPLACE VIEW vw_clv_analysis_base AS
SELECT
    customer_unique_id,
    order_id,
    purchase_ts,
    month_start_date,
    purchase_year,
    purchase_month,
    yearmonth,
    order_type,
    customer_state,
    total_transaction,
    total_unit,
    total_price,
    average_order_value,
    purchase_frequency,
    profit_margin,
    customer_value,
    cltv,
    segment,
    frequency,
    recency,
    T,
    monetary_value,
    expected_purc_1_week,
    expected_purc_1_month,
    expected_purc_3_month,

    CASE
		WHEN cltv < 0.005 THEN '0 - 0.005'
		WHEN cltv < 0.01 THEN '0.005 - 0.01'
		WHEN cltv < 0.02 THEN '0.01 - 0.02'
		WHEN cltv < 0.05 THEN '0.02 - 0.05'
		WHEN cltv < 0.1 THEN '0.05 - 0.1'
		WHEN cltv < 0.5 THEN '0.1 - 0.5'
		WHEN cltv < 1 THEN '0.5 - 1'
		ELSE '1+'
	END AS clv_bin,

    CASE
		WHEN cltv < 0.005 THEN 1
		WHEN cltv < 0.01 THEN 2
		WHEN cltv < 0.02 THEN 3
		WHEN cltv < 0.05 THEN 4
		WHEN cltv < 0.1 THEN 5
		WHEN cltv < 0.5 THEN 6
		WHEN cltv < 1 THEN 7
		ELSE 8
	END AS clv_bin_order,

    CASE
		WHEN cltv >= 1 THEN 'VIP'
		WHEN cltv >= 0.1 THEN 'High Value'
		WHEN cltv >= 0.03 THEN 'Medium Value'
		WHEN cltv >= 0.01 THEN 'Low Value'
		ELSE 'Very Low'
	END AS clv_segment,

    CASE
		WHEN cltv >= 1 THEN 5
		WHEN cltv >= 0.1 THEN 4
		WHEN cltv >= 0.03 THEN 3
		WHEN cltv >= 0.01 THEN 2
		ELSE 1
	END AS clv_segment_order
FROM vw_clv_pbi;

## KPI's
CREATE OR REPLACE VIEW vw_clv_kpi_source AS
SELECT
    month_start_date,
    yearmonth,
    order_type,
    COUNT(DISTINCT customer_unique_id) AS total_customers,
    ROUND(AVG(cltv), 6) AS avg_clv,
    ROUND(SUM(cltv), 6) AS total_clv,
    ROUND(SUM(expected_purc_3_month), 4) AS expected_purchases_3m,
    COUNT(DISTINCT CASE 
        WHEN clv_segment IN ('VIP', 'High Value') THEN customer_unique_id 
    END) AS high_value_customers,
    ROUND(
        100.0 * COUNT(DISTINCT CASE 
            WHEN clv_segment IN ('VIP', 'High Value') THEN customer_unique_id 
        END) / COUNT(DISTINCT customer_unique_id),
        2
    ) AS high_value_customer_pct
FROM vw_clv_analysis_base
GROUP BY month_start_date, yearmonth, order_type;

SELECT * FROM vw_clv_kpi_source LIMIT 10;

# CLV distribution

CREATE OR REPLACE VIEW vw_clv_distribution AS
SELECT
    month_start_date,
    yearmonth,
    order_type,
    clv_bin,
    clv_bin_order,
    COUNT(DISTINCT customer_unique_id) AS customer_count,
    ROUND(AVG(cltv), 6) AS avg_clv,
    ROUND(SUM(cltv), 6) AS total_clv
FROM vw_clv_analysis_base
GROUP BY
    month_start_date,
    yearmonth,
    order_type,
    clv_bin,
    clv_bin_order;
    
SELECT * FROM vw_clv_distribution LIMIT 10;

## CLV segment distribution

CREATE OR REPLACE VIEW vw_clv_segment_distribution AS
SELECT
    month_start_date,
    yearmonth,
    order_type,
    clv_segment,
    clv_segment_order,
    COUNT(DISTINCT customer_unique_id) AS customer_count,
    ROUND(AVG(cltv), 6) AS avg_clv,
    ROUND(SUM(cltv), 6) AS total_clv,
    ROUND(SUM(expected_purc_3_month), 4) AS expected_purchases_3m
FROM vw_clv_analysis_base
GROUP BY
    month_start_date,
    yearmonth,
    order_type,
    clv_segment,
    clv_segment_order;

SELECT * FROM vw_clv_segment_distribution LIMIT 10;
## Customer value by state

CREATE OR REPLACE VIEW vw_clv_by_state AS
SELECT
    month_start_date,
    yearmonth,
    order_type,
    customer_state,
    COUNT(DISTINCT customer_unique_id) AS customer_count,
    ROUND(AVG(cltv), 6) AS avg_clv,
    ROUND(SUM(cltv), 6) AS total_clv,
    ROUND(SUM(expected_purc_3_month), 4) AS expected_purchases_3m
FROM vw_clv_analysis_base
GROUP BY
    month_start_date,
    yearmonth,
    order_type,
    customer_state;
    
SELECT * FROM vw_clv_by_state LIMIT 10;

## Monthly CLV trend
CREATE OR REPLACE VIEW vw_clv_monthly_trend AS
SELECT
    month_start_date,
    yearmonth,
    order_type,
    COUNT(DISTINCT customer_unique_id) AS customer_count,
    ROUND(AVG(cltv), 6) AS avg_clv,
    ROUND(SUM(cltv), 6) AS total_clv,
    ROUND(SUM(expected_purc_3_month), 4) AS expected_purchases_3m,
    ROUND(AVG(expected_purc_3_month), 6) AS avg_expected_purchases_3m
FROM vw_clv_analysis_base
GROUP BY
    month_start_date,
    yearmonth,
    order_type;
    
SELECT * FROM vw_clv_monthly_trend LIMIT 10;   

    

