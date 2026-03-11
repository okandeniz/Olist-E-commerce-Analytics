USE olist;

-- Main RFM Analytics Table

CREATE OR REPLACE VIEW vw_rfm_analysis_base AS
SELECT
    c.customer_unique_id,
    c.order_id,

    -- time
    c.purchase_ts,
    c.month_start_date,
    c.purchase_year,
    c.purchase_month,
    c.yearmonth,

    -- dimensions
    c.order_type,
    c.customer_state,

    -- RFM metrics
    r.recency_days,
    r.frequency,
    r.monetary,
    r.aov,

    -- RFM scores
    r.recency_score,
    r.frequency_score,
    r.monetary_score,
    r.RFM_SCORE,

    -- segments
    r.segment,
    r.log_monetary

FROM vw_customer_latest_order_context c
LEFT JOIN rfm_customer_segments r
ON c.customer_unique_id = r.customer_unique_id;

-- Segment Order

CREATE OR REPLACE VIEW vw_rfm_analysis_enriched AS
SELECT
    *,

    CASE
        WHEN segment='champions' THEN 9
        WHEN segment='loyal_customers' THEN 8
        WHEN segment='potential_loyalists' THEN 7
        WHEN segment='new_customers' THEN 6
        WHEN segment='promising' THEN 5
        WHEN segment='about_to_sleep' THEN 4
        WHEN segment='at_risk' THEN 3
        WHEN segment='cant_loose' THEN 2
        WHEN segment='hibernating' THEN 1
        ELSE 0
    END AS segment_order

FROM vw_rfm_analysis_base;

-- KPI's

CREATE OR REPLACE VIEW vw_rfm_kpi_source AS
SELECT
    month_start_date,
    yearmonth,
    order_type,

    COUNT(DISTINCT customer_unique_id) AS total_customers,

    ROUND(AVG(recency_days),1) AS avg_recency_days,

    ROUND(AVG(frequency),2) AS avg_frequency,

    ROUND(AVG(monetary),2) AS avg_monetary

FROM vw_rfm_analysis_enriched
GROUP BY
    month_start_date,
    yearmonth,
    order_type;
    
-- RFM Segment Distribution

CREATE OR REPLACE VIEW vw_rfm_segment_distribution AS
SELECT
    month_start_date,
    yearmonth,
    order_type,
    segment,
    segment_order,

    COUNT(DISTINCT customer_unique_id) AS customer_count,
    ROUND(AVG(monetary),2) AS avg_customer_value

FROM vw_rfm_analysis_enriched
GROUP BY
    month_start_date,
    yearmonth,
    order_type,
    segment,
    segment_order;
    
-- Average Customer Value by Segment

CREATE OR REPLACE VIEW vw_rfm_value_by_segment AS
SELECT
    month_start_date,
    yearmonth,
    order_type,
    segment,

    ROUND(AVG(monetary),2) AS avg_customer_value

FROM vw_rfm_analysis_enriched
GROUP BY
    month_start_date,
    yearmonth,
    order_type,
    segment;
    
-- Frequency by Segment
    
CREATE OR REPLACE VIEW vw_rfm_frequency_segment AS
SELECT
    month_start_date,
    yearmonth,
    order_type,
    segment,

    ROUND(AVG(frequency),2) AS avg_frequency

FROM vw_rfm_analysis_enriched
GROUP BY
    month_start_date,
    yearmonth,
    order_type,
    segment;
    
-- Recency vs Monetary Scatter


CREATE OR REPLACE VIEW vw_rfm_scatter AS
SELECT
    month_start_date,
    yearmonth,
    order_type,
    segment,
    customer_unique_id,

    recency_days,
    monetary,
    frequency

FROM vw_rfm_analysis_enriched;

-- Top High Value Customers

CREATE OR REPLACE VIEW vw_rfm_top_customers AS
SELECT
    customer_unique_id,
    segment,
    recency_days,
    frequency,
    monetary,
    aov
FROM vw_rfm_analysis_enriched
ORDER BY monetary DESC;
