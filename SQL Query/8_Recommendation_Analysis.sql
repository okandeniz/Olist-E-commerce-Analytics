USE olist;

-- Main Recommendation Fact Table

CREATE OR REPLACE VIEW vw_recommendation_base AS
SELECT
    o.order_id,
    o.customer_unique_id,

    -- time
    o.purchase_ts,
    o.month_start_date,
    o.purchase_year,
    o.purchase_month,
    o.yearmonth,

    -- dimensions
    o.order_type,
    o.main_category_by_revenue,
    o.customer_state,

    -- revenue
    o.total_revenue,
    o.total_price,
    o.total_freight,
    o.item_count,

    -- delivery
    o.days_to_deliver,
    o.is_late,

    -- review
    o.review_score,

    -- recommendation model outputs
    r.purchased_category,
    r.item_based_suggestion,
    r.association_recommendation,
    r.correlation,
    r.support,
    r.confidence,
    r.lift

FROM vw_pbi_order_base o
LEFT JOIN recommendation_results r
ON o.order_id = r.order_id;

-- Recommendation Segment

CREATE OR REPLACE VIEW vw_recommendation_enriched AS
SELECT
    *,

    CASE
        WHEN correlation >= 0.9 THEN 'Very Strong'
        WHEN correlation >= 0.75 THEN 'Strong'
        WHEN correlation >= 0.5 THEN 'Moderate'
        WHEN correlation > 0 THEN 'Weak'
        ELSE 'No Recommendation'
    END AS recommendation_strength,

    CASE
        WHEN correlation >= 0.9 THEN 4
        WHEN correlation >= 0.75 THEN 3
        WHEN correlation >= 0.5 THEN 2
        WHEN correlation > 0 THEN 1
        ELSE 0
    END AS recommendation_strength_order

FROM vw_recommendation_base;

-- Executive KPI View

CREATE OR REPLACE VIEW vw_recommendation_kpi_source AS
SELECT
    month_start_date,
    yearmonth,
    order_type,

    COUNT(order_id) AS total_orders,

    SUM(CASE WHEN item_based_suggestion IS NOT NULL THEN 1 ELSE 0 END) 
        AS orders_with_recommendation,

    ROUND(AVG(correlation),3) AS avg_correlation,

    ROUND(AVG(lift),3) AS avg_lift,

    ROUND(
        100*SUM(CASE WHEN item_based_suggestion IS NOT NULL THEN 1 ELSE 0 END)/COUNT(order_id),
        2
    ) AS recommendation_coverage_pct

FROM vw_recommendation_enriched
GROUP BY
    month_start_date,
    yearmonth,
    order_type;
    
-- Recommendation Strength Distribution

CREATE OR REPLACE VIEW vw_recommendation_strength AS
SELECT
    month_start_date,
    yearmonth,
    order_type,
    recommendation_strength,
    recommendation_strength_order,

    COUNT(order_id) AS order_count,
    ROUND(AVG(correlation),3) AS avg_correlation

FROM vw_recommendation_enriched
GROUP BY
    month_start_date,
    yearmonth,
    order_type,
    recommendation_strength,
    recommendation_strength_order;
    
-- Recommendation Trend

CREATE OR REPLACE VIEW vw_recommendation_trend AS
SELECT
    month_start_date,
    yearmonth,
    order_type,

    ROUND(AVG(correlation),3) AS avg_correlation,
    ROUND(AVG(lift),3) AS avg_lift

FROM vw_recommendation_enriched
GROUP BY
    month_start_date,
    yearmonth,
    order_type;

-- Cross-Sell Opportunities

CREATE OR REPLACE VIEW vw_dash_cross_sell_category AS
SELECT
    month_start_date,
    yearmonth,
    order_type,
    purchased_category,
    item_based_suggestion,

    COUNT(order_id) AS recommendation_count,
    ROUND(AVG(correlation),3) AS avg_correlation,
    ROUND(AVG(lift),3) AS avg_lift

FROM vw_recommendation_enriched
WHERE item_based_suggestion IS NOT NULL
GROUP BY
    month_start_date,
    yearmonth,
    order_type,
    purchased_category,
    item_based_suggestion;
    
-- Recommendation Performance by Category

CREATE OR REPLACE VIEW vw_recommendation_category_performance AS
SELECT
    month_start_date,
    yearmonth,
    order_type,
    main_category_by_revenue,

    COUNT(order_id) AS orders,
    ROUND(AVG(correlation),3) AS avg_correlation,
    ROUND(AVG(lift),3) AS avg_lift

FROM vw_recommendation_enriched
GROUP BY
    month_start_date,
    yearmonth,
    order_type,
    main_category_by_revenue;
    
-- Top Recommendation Opportunities Table

CREATE OR REPLACE VIEW vw_top_recommendations AS
SELECT
    order_id,
    customer_unique_id,
    purchased_category,
    item_based_suggestion,
    correlation,
    lift,
    confidence
FROM vw_recommendation_enriched
WHERE correlation >= 0.8
ORDER BY correlation DESC;
