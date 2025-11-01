-- 1.1 Check for missing values
-- Count NULLs per columns
SELECT COUNT(*) AS total_rows,
	SUM(CASE WHEN date IS NULL THEN 1 ELSE 0 END) AS missing_date,
	SUM(CASE WHEN paid_search_spend IS NULL THEN 1 ELSE 0 END) AS missing_paid_search_spend,
	SUM(CASE WHEN paid_social_spend IS NULL THEN 1 ELSE 0 END) AS missing_paid_social_spend,
	SUM(CASE WHEN display_spend IS NULL THEN 1 ELSE 0 END) AS missing_display_spend,
	SUM(CASE WHEN email_spend IS NULL THEN 1 ELSE 0 END) AS missing_email_spend,
	SUM(CASE WHEN affiliate_spend IS NULL THEN 1 ELSE 0 END) AS missing_affiliate_spend,
	SUM(CASE WHEN tv_spend IS NULL THEN 1 ELSE 0 END) AS missing_tv_spend
FROM marketing_spend;

SELECT COUNT(*) AS total_rows,
	SUM(CASE WHEN date IS NULL THEN 1 ELSE 0 END) AS missing_date,
	SUM(CASE WHEN revenue IS NULL THEN 1 ELSE 0 END) AS missing_revenue,
	SUM(CASE WHEN transactions IS NULL THEN 1 ELSE 0 END) AS missing_transactions,
	SUM(CASE WHEN new_customers IS NULL THEN 1 ELSE 0 END) AS missing_new_customers
FROM revenue;

SELECT COUNT(*) AS total_rows,
	SUM(CASE WHEN date IS NULL THEN 1 ELSE 0 END) AS missing_date,
	SUM(CASE WHEN is_weekend IS NULL THEN 1 ELSE 0 END) AS missing_is_weekend,
	SUM(CASE WHEN is_holiday IS NULL THEN 1 ELSE 0 END) AS missing_is_holiday,
	SUM(CASE WHEN promotion_active IS NULL THEN 1 ELSE 0 END) AS missing_promotion_active,
	SUM(CASE WHEN competitor_index IS NULL THEN 1 ELSE 0 END) AS missing_competitor_index,
	SUM(CASE WHEN seasonality_index IS NULL THEN 1 ELSE 0 END) AS missing_seasonality_index
FROM external_factors;

-- 1.2 Identify any date gaps in the data
-- Using LAG() window function to get the previous date; if date gap > 1 then there is a date gap
-- Missing 2023-10-29 and 2024-10-27 in three tabels
WITH date_diff as (
SELECT
    date,
    LAG(date) OVER (ORDER BY date) AS prev_date,
    date - LAG(date) OVER (ORDER BY date) AS date_diff
FROM marketing_spend
ORDER BY date
)
	SELECT date,
		prev_date,
		date_diff
	FROM date_diff
	WHERE date_diff > 1;

WITH date_diff as (
SELECT
    date,
    LAG(date) OVER (ORDER BY date) AS prev_date,
    date - LAG(date) OVER (ORDER BY date) AS date_diff
FROM revenue
ORDER BY date
)
	SELECT date,
		prev_date,
		date_diff
	FROM date_diff
	WHERE date_diff > 1;

WITH date_diff as (
SELECT
    date,
    LAG(date) OVER (ORDER BY date) AS prev_date,
    date - LAG(date) OVER (ORDER BY date) AS date_diff
FROM external_factors
ORDER BY date
)
	SELECT date,
		prev_date,
		date_diff
	FROM date_diff
	WHERE date_diff > 1;

-- 1.3 Find outliner in spend and revenue
-- Detect outliers in spend and revenue using IQR
-- Values outside (Q1 - 1.5*IQR, Q3 + 1.5*IQR) as outliers
WITH combined AS (
  SELECT date, col_name, value
  FROM marketing_spend
  CROSS JOIN LATERAL (
	VALUES 
	  ('paid_search_spend', paid_search_spend),
	  ('paid_social_spend', paid_social_spend),
	  ('display_spend', display_spend),
	  ('email_spend', email_spend),
	  ('affiliate_spend', affiliate_spend),
	  ('tv_spend', tv_spend)
  ) AS t(col_name, value)
  UNION ALL
  SELECT date, col_name, value
  FROM revenue
  CROSS JOIN LATERAL (
	VALUES
	  ('revenue', revenue),
	  ('transactions', transactions),
	  ('new_customers', new_customers)
  ) AS t(col_name, value)

-- Compute IQR for each column
), iqr_stats AS (
  SELECT col_name,
	percentile_cont(0.25) WITHIN GROUP (ORDER BY value) AS q1,
	percentile_cont(0.75) WITHIN GROUP (ORDER BY value) AS q3
  FROM combined
  GROUP BY col_name
	
-- Detect outliers
)
  SELECT c.date,
	c.col_name,
	c.value
  FROM combined c
  LEFT JOIN iqr_stats s
	ON c.col_name = s.col_name
  WHERE c.value < (s.q1 - 1.5 * (s.q3 - s.q1))
	OR c.value > (s.q3 + 1.5 * (s.q3 - s.q1))
  ORDER BY c.date, c.col_name;