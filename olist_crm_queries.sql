#1. vw_category_loyalty
WITH category_analysis AS (
  SELECT
    COALESCE(t.product_category_name_english, p.product_category_name_english_x) AS category_name,
    COUNT(DISTINCT o.order_id) AS total_orders,
    COUNT(DISTINCT c.customer_unique_id) AS unique_customers,
    COUNT(DISTINCT CASE WHEN cph.total_purchases > 1 THEN c.customer_unique_id END) AS repeat_customers,
    ROUND(100.0 * COUNT(DISTINCT CASE WHEN cph.total_purchases > 1 THEN c.customer_unique_id END) 
          / COUNT(DISTINCT c.customer_unique_id), 2) AS repeat_rate_pct,
    ROUND(SUM(oi.price), 2) AS total_revenue,
    ROUND(AVG(oi.price), 2) AS avg_price,
    ROUND(AVG(r.review_score), 2) AS avg_rating,
    COUNT(DISTINCT o.order_id) * 1.0 / COUNT(DISTINCT c.customer_unique_id) AS avg_orders_per_customer
  FROM `olist-crm-analytics.olist_ecommerce.orders_fixed` o
  JOIN `olist-crm-analytics.olist_ecommerce.customers` c ON o.customer_id = c.customer_id
  JOIN `olist-crm-analytics.olist_ecommerce.items` oi ON o.order_id = oi.order_id
  JOIN `olist-crm-analytics.olist_ecommerce.products` p ON oi.product_id = p.product_id
  LEFT JOIN `olist-crm-analytics.olist_ecommerce.category` t 
    ON p.product_category_name_english_x = t.product_category_name_english
  LEFT JOIN `olist-crm-analytics.olist_ecommerce.reviews` r ON o.order_id = r.order_id
  -- Add purchase history
  LEFT JOIN (
    SELECT c2.customer_unique_id, COUNT(DISTINCT o2.order_id) AS total_purchases
    FROM `olist-crm-analytics.olist_ecommerce.orders_fixed` o2
    JOIN `olist-crm-analytics.olist_ecommerce.customers` c2 ON o2.customer_id = c2.customer_id
    WHERE o2.order_status = 'delivered'
    GROUP BY c2.customer_unique_id
  ) cph ON c.customer_unique_id = cph.customer_unique_id
  WHERE o.order_status = 'delivered'
  GROUP BY category_name
)

SELECT
  category_name,
  total_orders,
  unique_customers,
  repeat_customers,
  repeat_rate_pct,
  total_revenue,
  avg_price,
  avg_rating,
  ROUND(avg_orders_per_customer, 2) AS avg_orders_per_customer,
  CURRENT_TIMESTAMP() AS created_at
FROM category_analysis
ORDER BY repeat_rate_pct DESC

---------------------------------------------------------------------------------------------------

#2. vw_churn_reason
WITH delivery_analysis AS (
  SELECT
    r.review_score,
    DATE_DIFF(DATE(o.order_delivered_customer_date), DATE(o.order_estimated_delivery_date), DAY) AS delivery_delay_days,
    COUNT(*) AS order_count,
    ROUND(AVG(CASE WHEN DATE_DIFF(DATE(o.order_delivered_customer_date), DATE(o.order_estimated_delivery_date), DAY) > 0 THEN 1 ELSE 0 END) * 100, 2) AS late_pct,
    ROUND(SUM(oi.freight_value), 2) AS total_freight_cost,
    ROUND(AVG(oi.freight_value), 2) AS avg_freight_cost,
    COUNT(DISTINCT pm.payment_type) AS payment_types_used
  FROM `olist-crm-analytics.olist_ecommerce.orders_fixed` o
  JOIN `olist-crm-analytics.olist_ecommerce.reviews` r ON o.order_id = r.order_id
  JOIN `olist-crm-analytics.olist_ecommerce.items` oi ON o.order_id = oi.order_id
  JOIN `olist-crm-analytics.olist_ecommerce.payments` pm ON o.order_id = pm.order_id
  WHERE o.order_delivered_customer_date IS NOT NULL
  GROUP BY r.review_score, delivery_delay_days
)

SELECT
  review_score,
  delivery_delay_days,
  order_count,
  late_pct,
  total_freight_cost,
  avg_freight_cost,
  payment_types_used,
  CASE
    WHEN review_score <= 2 AND delivery_delay_days > 0 THEN 'Delay + Poor Rating'
    WHEN review_score <= 2 THEN 'Poor Product/Service'
    WHEN delivery_delay_days > 0 THEN 'Late Delivery'
    WHEN avg_freight_cost > 30 THEN 'High Shipping Cost'
    ELSE 'Other'
  END AS churn_reason,
  CURRENT_TIMESTAMP() AS created_at
FROM delivery_analysis
ORDER BY order_count DESC

----------------------------------------------------------------------------------------------

#3. vw_customer_churn_risk
WITH customer_purchase_history AS (
  SELECT
    c.customer_unique_id,
    c.customer_city,
    c.customer_state,
    COUNT(DISTINCT o.order_id) AS total_purchases,
    MAX(o.order_purchase_timestamp) AS last_purchase_date,
    DATE_DIFF(DATE '2018-10-17', DATE(MAX(o.order_purchase_timestamp)), DAY) AS days_since_purchase,
    ROUND(SUM(p.payment_value), 2) AS lifetime_value,
    ROUND(AVG(p.payment_value), 2) AS avg_order_value,
    ROUND(AVG(r.review_score), 2) AS avg_rating
  FROM `olist_ecommerce.customers` c
  JOIN `olist_ecommerce.orders_fixed` o ON c.customer_id = o.customer_id
  JOIN `olist_ecommerce.payments` p ON o.order_id = p.order_id
  LEFT JOIN `olist_ecommerce.reviews` r ON o.order_id = r.order_id
  WHERE o.order_status = 'delivered'
  GROUP BY c.customer_unique_id, c.customer_city, c.customer_state
),

churn_risk AS (
  SELECT
    *,
    CASE
      WHEN total_purchases = 1 THEN '1-Time Buyer'
      WHEN total_purchases >= 2 AND days_since_purchase > 180 THEN 'At Risk'
      WHEN total_purchases >= 2 AND days_since_purchase <= 180 THEN 'Active'
      ELSE 'New'
    END AS churn_status
  FROM customer_purchase_history
)

SELECT
  customer_unique_id,
  customer_city,
  customer_state,
  total_purchases,
  last_purchase_date,
  days_since_purchase,
  lifetime_value,
  avg_order_value,
  avg_rating,
  churn_status,
  CURRENT_TIMESTAMP() AS created_at
FROM churn_risk

----------------------------------------------------------------------------------------

#4. vw_customer_clv
WITH customer_clv AS (
  SELECT
    c.customer_unique_id,
    c.customer_city,
    c.customer_state,
    -- AOV: Average Order Value
    ROUND(SUM(p.payment_value) / COUNT(DISTINCT o.order_id), 2) AS avg_order_value,
    -- Frequency: Purchase count
    COUNT(DISTINCT o.order_id) AS purchase_frequency,
    -- Customer Lifespan: Days from first to last purchase
    DATE_DIFF(MAX(o.order_purchase_timestamp), MIN(o.order_purchase_timestamp), DAY) AS customer_lifespan_days,
    -- CLV = AOV × Frequency × (Lifespan in years)
    ROUND(
      (SUM(p.payment_value) / COUNT(DISTINCT o.order_id)) * 
      COUNT(DISTINCT o.order_id) * 
      (DATE_DIFF(MAX(o.order_purchase_timestamp), MIN(o.order_purchase_timestamp), DAY) / 365.0 + 1),
      2
    ) AS customer_lifetime_value,
    ROUND(SUM(p.payment_value), 2) AS total_spent,
    ROUND(AVG(r.review_score), 2) AS avg_satisfaction
  FROM `olist-crm-analytics.olist_ecommerce.customers` c
  JOIN `olist-crm-analytics.olist_ecommerce.orders_fixed` o ON c.customer_id = o.customer_id
  JOIN `olist-crm-analytics.olist_ecommerce.payments` p ON o.order_id = p.order_id
  LEFT JOIN `olist-crm-analytics.olist_ecommerce.reviews` r ON o.order_id = r.order_id
  WHERE o.order_status = 'delivered'
  GROUP BY c.customer_unique_id, c.customer_city, c.customer_state
)

SELECT
  customer_unique_id,
  customer_city,
  customer_state,
  avg_order_value,
  purchase_frequency,
  customer_lifespan_days,
  customer_lifetime_value,
  total_spent,
  avg_satisfaction,
  CURRENT_TIMESTAMP() AS created_at
FROM customer_clv

------------------------------------------------------------------------------------------------

#5. vw_customer_rfm
WITH customer_metrics AS (
  SELECT
    c.customer_unique_id,
    c.customer_city,
    c.customer_state,
    -- RECENCY: Days since last purchase
    DATE_DIFF(DATE '2018-10-17', DATE(MAX(o.order_purchase_timestamp)), DAY) AS recency_days,
    -- FREQUENCY: Number of purchases
    COUNT(DISTINCT o.order_id) AS frequency,
    -- MONETARY: Total spend
    ROUND(SUM(p.payment_value), 2) AS monetary_value
  FROM `olist_ecommerce.orders_fixed` o
  JOIN `olist_ecommerce.customers` c ON o.customer_id = c.customer_id
  JOIN `olist_ecommerce.payments` p ON o.order_id = p.order_id
  WHERE o.order_status = 'delivered'
  GROUP BY c.customer_unique_id, c.customer_city, c.customer_state
),

rfm_scores AS (
  SELECT
    *,
    NTILE(5) OVER (ORDER BY recency_days DESC) AS r_score,
    NTILE(5) OVER (ORDER BY frequency ASC) AS f_score,
    NTILE(5) OVER (ORDER BY monetary_value ASC) AS m_score
  FROM customer_metrics
),

segmentation AS (
  SELECT
    *,
    CASE
      WHEN r_score >= 4 AND f_score >= 4 THEN 'Champion'
      WHEN r_score >= 3 AND f_score >= 3 THEN 'Loyal'
      WHEN r_score >= 4 AND f_score <= 2 THEN 'New Customer'
      WHEN r_score <= 2 AND f_score >= 3 THEN 'At Risk'
      WHEN r_score <= 2 AND f_score <= 2 THEN 'Lost'
      ELSE 'Potential'
    END AS rfm_segment
  FROM rfm_scores
)

SELECT
  customer_unique_id,
  customer_city,
  customer_state,
  recency_days,
  frequency,
  monetary_value,
  r_score,
  f_score,
  m_score,
  (r_score + f_score + m_score) AS rfm_total,
  rfm_segment,
  CURRENT_TIMESTAMP() AS created_at
FROM segmentation

------------------------------------------------------------------------------------------------

#6. vw_customer_satisfaction
WITH location_satisfaction AS (
  SELECT
    c.customer_state,
    c.customer_city,
    COUNT(DISTINCT o.order_id) AS total_orders,
    COUNT(DISTINCT c.customer_unique_id) AS unique_customers,
    ROUND(AVG(r.review_score), 2) AS avg_rating,
    COUNT(CASE WHEN r.review_score = 5 THEN 1 END) AS five_star_count,
    COUNT(CASE WHEN r.review_score = 1 THEN 1 END) AS one_star_count,
    ROUND(100.0 * COUNT(CASE WHEN r.review_score = 1 THEN 1 END) / COUNT(*), 2) AS one_star_pct,
    ROUND(AVG(DATE_DIFF(DATE(o.order_delivered_customer_date), DATE(o.order_estimated_delivery_date), DAY)), 2) AS avg_delay_days
  FROM `olist-crm-analytics.olist_ecommerce.customers` c
  JOIN `olist-crm-analytics.olist_ecommerce.orders_fixed` o ON c.customer_id = o.customer_id
  JOIN `olist-crm-analytics.olist_ecommerce.reviews` r ON o.order_id = r.order_id
  WHERE o.order_status = 'delivered'
  GROUP BY c.customer_state, c.customer_city
)

SELECT
  customer_state,
  customer_city,
  total_orders,
  unique_customers,
  avg_rating,
  five_star_count,
  one_star_count,
  one_star_pct,
  avg_delay_days,
  CASE
    WHEN avg_rating >= 4.5 THEN 'Very Satisfied'
    WHEN avg_rating >= 4 THEN 'Satisfied'
    WHEN avg_rating >= 3 THEN 'Neutral'
    WHEN avg_rating >= 2 THEN 'Dissatisfied'
    ELSE 'Very Dissatisfied'
  END AS satisfaction_level,
  CURRENT_TIMESTAMP() AS created_at
FROM location_satisfaction
ORDER BY avg_rating ASC

-------------------------------------------------------------------------------------------------------

#7. vw_revenue_risk
WITH customer_segment_revenue AS (
  SELECT
    c.customer_unique_id,
    CASE
      WHEN COUNT(DISTINCT o.order_id) = 1 THEN 'One-Time Buyer'
      WHEN COUNT(DISTINCT o.order_id) >= 2 
           AND DATE_DIFF(DATE '2018-10-17', DATE(MAX(o.order_purchase_timestamp)), DAY) > 180 
           THEN 'At Risk'
      WHEN COUNT(DISTINCT o.order_id) >= 2 THEN 'Active'
      ELSE 'New'
    END AS customer_segment,
    ROUND(SUM(p.payment_value), 2) AS customer_revenue
  FROM `olist-crm-analytics.olist_ecommerce.customers` c
  JOIN `olist-crm-analytics.olist_ecommerce.orders_fixed` o ON c.customer_id = o.customer_id
  JOIN `olist-crm-analytics.olist_ecommerce.payments` p ON o.order_id = p.order_id
  WHERE o.order_status = 'delivered'
  GROUP BY c.customer_unique_id
)

SELECT
  customer_segment,
  COUNT(*) AS customer_count,
  ROUND(SUM(customer_revenue), 2) AS segment_revenue,
  ROUND(AVG(customer_revenue), 2) AS avg_customer_revenue,
  ROUND(100.0 * SUM(customer_revenue) / SUM(SUM(customer_revenue)) OVER(), 2) AS revenue_pct,
  CURRENT_TIMESTAMP() AS created_at
FROM customer_segment_revenue
GROUP BY customer_segment
ORDER BY segment_revenue DESC