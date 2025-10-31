-- 3. Create summary statistics for each marketing channel and revenue
-- UNNEST() with paired arrays: one with metric names; the other with spend values
WITH unpivoted AS (
SELECT ms.date,
	metric,
	total	
FROM marketing_spend ms
LEFT JOIN revenue r
	ON ms.date = r.date
-- UNNEST converts multiple spend columns into metrics and total value rows	
JOIN LATERAL UNNEST(
	ARRAY['paid_search_spend', 'paid_social_spend', 'display_spend', 'email_spend', 'affiliate_spend', 'tv_spend', 'revenue', 'transactions', 'new_customers'],
	ARRAY[paid_search_spend, paid_social_spend, display_spend, email_spend, affiliate_spend, tv_spend, revenue, transactions, new_customers]
) AS t(metric, total)
	ON TRUE
	)
-- Compute summary statistics
	SELECT metric,
		SUM(total) AS total_value,
		MIN(total) AS min_value,
		MAX(total) AS max_value,
		AVG(total) AS avg_value,
		PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY total) AS median_value,
		STDDEV(total) AS stddev_value
	FROM unpivoted
	GROUP BY 1;
	
-- 4.1 Analyze temporal patterns
-- Monthly aggregations of spend and revenue
WITH combined AS (
SELECT ms.date,
	(ms.paid_search_spend + ms.paid_social_spend + ms.display_spend +
	ms.email_spend + ms.affiliate_spend + ms.tv_spend) AS total_spend,
	r.revenue
FROM marketing_spend ms
LEFT JOIN revenue r 
	ON ms.date = r.date	
)
SELECT date_trunc('month', date) AS date_month,
	SUM(total_spend) AS total_spend,
	SUM(revenue) AS revenue,
    ROUND(AVG(total_spend),2) AS avg_total_spend,
    ROUND(AVG(revenue),2) AS avg_revenue,
    ROUND(AVG(revenue)/NULLIF(AVG(total_spend),0),2) AS avg_roi
FROM combined
GROUP BY 1
order by 1;
	
-- 4.2 Day-of-week patterns
WITH combined AS (
SELECT ms.date,
	TO_CHAR(ms.date, 'Dy') AS day_of_week,
	(ms.paid_search_spend + ms.paid_social_spend + ms.display_spend +
	ms.email_spend + ms.affiliate_spend + ms.tv_spend) AS total_spend,
	r.revenue
FROM marketing_spend ms
LEFT JOIN revenue r 
	ON ms.date = r.date
)
SELECT day_of_week,
	SUM(total_spend) AS total_spend,
	SUM(revenue) AS revenue,
    ROUND(AVG(total_spend),2) AS avg_total_spend,
    ROUND(AVG(revenue),2) AS avg_revenue,
    ROUND(AVG(revenue)/NULLIF(AVG(total_spend),0),2) AS avg_roi
FROM combined
GROUP BY day_of_week;

-- 4.3 Seasonal trends
WITH combined AS (
SELECT ms.date,
	(ms.paid_search_spend + ms.paid_social_spend + ms.display_spend +
	ms.email_spend + ms.affiliate_spend + ms.tv_spend) AS total_spend,
	r.revenue,
    ef.seasonality_index	
FROM marketing_spend ms
LEFT JOIN revenue r 
	ON ms.date = r.date
LEFT JOIN external_factors ef 
	ON ms.date = ef.date
	
)
SELECT date_trunc('month', date) AS date_month,
	ROUND(AVG(seasonality_index),2) AS avg_seasonality,
    ROUND(AVG(total_spend),2) AS avg_total_spend,
    ROUND(AVG(revenue),2) AS avg_revenue,
    ROUND(AVG(revenue)/NULLIF(AVG(total_spend),0),2) AS avg_roi	
FROM combined
GROUP BY 1
ORDER BY 1;