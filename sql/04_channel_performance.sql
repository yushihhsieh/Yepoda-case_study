-- 1. Calculate total spend and total revenue by channel for the entire period
-- Assumption: revenue is total per day, not broken down by channel, so I'll assume revenue is allocated proportionally to spend share
-- formula: revenue * (spend_per_channel/total_spend)
WITH daily_data AS (
  SELECT ms.date,
	ms.paid_search_spend,
	ms.paid_social_spend,
	ms.display_spend,
	ms.email_spend,
	ms.affiliate_spend,
	ms.tv_spend,
	r.revenue,
	(ms.paid_search_spend + ms.paid_social_spend + ms.display_spend +
	ms.email_spend + ms.affiliate_spend + ms.tv_spend) AS total_spend
  FROM marketing_spend ms
  LEFT JOIN revenue r 
	USING (date)

-- Aggregate spend and allocate revenue proportionally
), aggregated AS (
  SELECT SUM(paid_search_spend) AS paid_search_spend,
	SUM(paid_social_spend) AS paid_social_spend,
	SUM(display_spend) AS display_spend,
	SUM(email_spend) AS email_spend,
	SUM(affiliate_spend) AS affiliate_spend,
	SUM(tv_spend) AS tv_spend,
	SUM(CASE WHEN total_spend > 0 THEN revenue * (paid_search_spend / total_spend) ELSE 0 END) AS paid_search_revenue,
	SUM(CASE WHEN total_spend > 0 THEN revenue * (paid_social_spend / total_spend) ELSE 0 END) AS paid_social_revenue,
	SUM(CASE WHEN total_spend > 0 THEN revenue * (display_spend / total_spend) ELSE 0 END) AS display_revenue,
	SUM(CASE WHEN total_spend > 0 THEN revenue * (email_spend / total_spend) ELSE 0 END) AS email_revenue,
	SUM(CASE WHEN total_spend > 0 THEN revenue * (affiliate_spend / total_spend) ELSE 0 END) AS affiliate_revenue,
	SUM(CASE WHEN total_spend > 0 THEN revenue * (tv_spend / total_spend) ELSE 0 END) AS tv_revenue
  FROM daily_data

-- Pivot channels into rows using UNNEST	
), channel_totals AS (
  SELECT UNNEST(ARRAY['paid_search', 'paid_social', 'display', 'email', 'affiliate', 'tv']) AS channel,
	UNNEST(ARRAY[paid_search_spend, paid_social_spend, display_spend, email_spend, affiliate_spend, tv_spend]) AS total_spend,
	UNNEST(ARRAY[paid_search_revenue, paid_social_revenue, display_revenue, email_revenue, affiliate_revenue, tv_revenue]) AS total_revenue
  FROM aggregated

)
  SELECT channel,
	total_spend,
	total_revenue,
	ROUND(total_revenue / NULLIF(total_spend,0), 4) AS roas
  FROM channel_totals
  ORDER BY total_revenue DESC;


-- 2. Compute ROAS (Return on Ad Spend) for each channel 
-- Use 7-day, 14-day, and 30-day attribution windows
WITH base_data AS (
  SELECT ms.date AS spend_date,
    r.date AS revenue_date,
    r.revenue,
    ms.paid_search_spend,
    ms.paid_social_spend,
    ms.display_spend,
    ms.email_spend,
    ms.affiliate_spend,
    ms.tv_spend,
    (ms.paid_search_spend + ms.paid_social_spend + ms.display_spend +
     ms.email_spend + ms.affiliate_spend + ms.tv_spend) AS total_spend
  FROM marketing_spend ms
  LEFT JOIN revenue r
	ON r.date BETWEEN ms.date AND ms.date + INTERVAL '30 day'
	
-- Allocate revenue proportionally to spend share
), proportional_revenue AS (
  SELECT spend_date,
	revenue_date,
	revenue,
	paid_search_spend,
	paid_social_spend,
	display_spend,
	email_spend,
	affiliate_spend,
	tv_spend,
	total_spend,
	revenue * (paid_search_spend / NULLIF(total_spend, 0)) AS paid_search_revenue,
	revenue * (paid_social_spend / NULLIF(total_spend, 0)) AS paid_social_revenue,
	revenue * (display_spend / NULLIF(total_spend, 0)) AS display_revenue,
	revenue * (email_spend / NULLIF(total_spend, 0)) AS email_revenue,
	revenue * (affiliate_spend / NULLIF(total_spend, 0)) AS affiliate_revenue,
	revenue * (tv_spend / NULLIF(total_spend, 0)) AS tv_revenue
  FROM base_data

-- Aggregate revenues by spend_date for each attribution window
), attributed_revenue AS (
  SELECT spend_date,
	SUM(paid_search_spend) AS paid_search_spend,
	SUM(paid_social_spend) AS paid_social_spend,
	SUM(display_spend) AS display_spend,
 	SUM(email_spend) AS email_spend,
	SUM(affiliate_spend) AS affiliate_spend,
	SUM(tv_spend) AS tv_spend,

	SUM(CASE WHEN revenue_date <= spend_date + INTERVAL '7 day' THEN paid_search_revenue ELSE 0 END) AS paid_search_rev_7d,
	SUM(CASE WHEN revenue_date <= spend_date + INTERVAL '14 day' THEN paid_search_revenue ELSE 0 END) AS paid_search_rev_14d,
	SUM(CASE WHEN revenue_date <= spend_date + INTERVAL '30 day' THEN paid_search_revenue ELSE 0 END) AS paid_search_rev_30d,

	SUM(CASE WHEN revenue_date <= spend_date + INTERVAL '7 day' THEN paid_social_revenue ELSE 0 END) AS paid_social_rev_7d,
	SUM(CASE WHEN revenue_date <= spend_date + INTERVAL '14 day' THEN paid_social_revenue ELSE 0 END) AS paid_social_rev_14d,
	SUM(CASE WHEN revenue_date <= spend_date + INTERVAL '30 day' THEN paid_social_revenue ELSE 0 END) AS paid_social_rev_30d,

	SUM(CASE WHEN revenue_date <= spend_date + INTERVAL '7 day' THEN display_revenue ELSE 0 END) AS display_rev_7d,
	SUM(CASE WHEN revenue_date <= spend_date + INTERVAL '14 day' THEN display_revenue ELSE 0 END) AS display_rev_14d,
	SUM(CASE WHEN revenue_date <= spend_date + INTERVAL '30 day' THEN display_revenue ELSE 0 END) AS display_rev_30d,

 	SUM(CASE WHEN revenue_date <= spend_date + INTERVAL '7 day' THEN email_revenue ELSE 0 END) AS email_rev_7d,
	SUM(CASE WHEN revenue_date <= spend_date + INTERVAL '14 day' THEN email_revenue ELSE 0 END) AS email_rev_14d,
    SUM(CASE WHEN revenue_date <= spend_date + INTERVAL '30 day' THEN email_revenue ELSE 0 END) AS email_rev_30d,

	SUM(CASE WHEN revenue_date <= spend_date + INTERVAL '7 day' THEN affiliate_revenue ELSE 0 END) AS affiliate_rev_7d,
	SUM(CASE WHEN revenue_date <= spend_date + INTERVAL '14 day' THEN affiliate_revenue ELSE 0 END) AS affiliate_rev_14d,
	SUM(CASE WHEN revenue_date <= spend_date + INTERVAL '30 day' THEN affiliate_revenue ELSE 0 END) AS affiliate_rev_30d,

	SUM(CASE WHEN revenue_date <= spend_date + INTERVAL '7 day' THEN tv_revenue ELSE 0 END) AS tv_rev_7d,
 	SUM(CASE WHEN revenue_date <= spend_date + INTERVAL '14 day' THEN tv_revenue ELSE 0 END) AS tv_rev_14d,
    SUM(CASE WHEN revenue_date <= spend_date + INTERVAL '30 day' THEN tv_revenue ELSE 0 END) AS tv_rev_30d
  FROM proportional_revenue
  GROUP BY 1

-- Aggregate totals across all spend dates
), channel_totals AS (
  SELECT SUM(paid_search_spend) AS paid_search_spend,
	SUM(paid_social_spend) AS paid_social_spend,
	SUM(display_spend) AS display_spend,
	SUM(email_spend) AS email_spend,
	SUM(affiliate_spend) AS affiliate_spend,
	SUM(tv_spend) AS tv_spend,

	SUM(paid_search_rev_7d) AS paid_search_rev_7d,
	SUM(paid_search_rev_14d) AS paid_search_rev_14d,
	SUM(paid_search_rev_30d) AS paid_search_rev_30d,

	SUM(paid_social_rev_7d) AS paid_social_rev_7d,
	SUM(paid_social_rev_14d) AS paid_social_rev_14d,
	SUM(paid_social_rev_30d) AS paid_social_rev_30d,

	SUM(display_rev_7d) AS display_rev_7d,
	SUM(display_rev_14d) AS display_rev_14d,
	SUM(display_rev_30d) AS display_rev_30d,

	SUM(email_rev_7d) AS email_rev_7d,
	SUM(email_rev_14d) AS email_rev_14d,
	SUM(email_rev_30d) AS email_rev_30d,

	SUM(affiliate_rev_7d) AS affiliate_rev_7d,
	SUM(affiliate_rev_14d) AS affiliate_rev_14d,
	SUM(affiliate_rev_30d) AS affiliate_rev_30d,
	
	SUM(tv_rev_7d) AS tv_rev_7d,
	SUM(tv_rev_14d) AS tv_rev_14d,
	SUM(tv_rev_30d) AS tv_rev_30d
  FROM attributed_revenue

-- Use UNNEST to transform channels into rows
), roas_by_channel AS (
  SELECT
    UNNEST(ARRAY['paid_search','paid_social','display','email','affiliate','tv']) AS channel,
    UNNEST(ARRAY[paid_search_spend, paid_social_spend, display_spend, email_spend, affiliate_spend, tv_spend]) AS total_spend,
    UNNEST(ARRAY[paid_search_rev_7d, paid_social_rev_7d, display_rev_7d, email_rev_7d, affiliate_rev_7d, tv_rev_7d]) AS rev_7d,
    UNNEST(ARRAY[paid_search_rev_14d, paid_social_rev_14d, display_rev_14d, email_rev_14d, affiliate_rev_14d, tv_rev_14d]) AS rev_14d,
    UNNEST(ARRAY[paid_search_rev_30d, paid_social_rev_30d, display_rev_30d, email_rev_30d, affiliate_rev_30d, tv_rev_30d]) AS rev_30d
  FROM channel_totals

)
  SELECT channel,
  ROUND(rev_7d / NULLIF(total_spend, 0), 4) AS roas_7d,
  ROUND(rev_14d / NULLIF(total_spend, 0), 4) AS roas_14d,
  ROUND(rev_30d / NULLIF(total_spend, 0), 4) AS roas_30d
  FROM roas_by_channel
  ORDER BY channel;
  
  
-- 3. Identify the top and bottom performing channels
-- by Total revenue generated; by Efficiency (revenue per dollar spent)
WITH daily_data AS (
  SELECT ms.date,
	ms.paid_search_spend,
	ms.paid_social_spend,
	ms.display_spend,
	ms.email_spend,
	ms.affiliate_spend,
	ms.tv_spend,
	r.revenue,
	(ms.paid_search_spend + ms.paid_social_spend + ms.display_spend +
	ms.email_spend + ms.affiliate_spend + ms.tv_spend) AS total_spend
  FROM marketing_spend ms
  LEFT JOIN revenue r 
	USING (date)

-- Aggregate spend and allocate revenue proportionally
), aggregated AS (
  SELECT SUM(paid_search_spend) AS paid_search_spend,
	SUM(paid_social_spend) AS paid_social_spend,
	SUM(display_spend) AS display_spend,
	SUM(email_spend) AS email_spend,
	SUM(affiliate_spend) AS affiliate_spend,
	SUM(tv_spend) AS tv_spend,
	SUM(CASE WHEN total_spend > 0 THEN revenue * (paid_search_spend / total_spend) ELSE 0 END) AS paid_search_revenue,
	SUM(CASE WHEN total_spend > 0 THEN revenue * (paid_social_spend / total_spend) ELSE 0 END) AS paid_social_revenue,
	SUM(CASE WHEN total_spend > 0 THEN revenue * (display_spend / total_spend) ELSE 0 END) AS display_revenue,
	SUM(CASE WHEN total_spend > 0 THEN revenue * (email_spend / total_spend) ELSE 0 END) AS email_revenue,
	SUM(CASE WHEN total_spend > 0 THEN revenue * (affiliate_spend / total_spend) ELSE 0 END) AS affiliate_revenue,
	SUM(CASE WHEN total_spend > 0 THEN revenue * (tv_spend / total_spend) ELSE 0 END) AS tv_revenue
  FROM daily_data

-- Pivot channels into rows using UNNEST	
), channel_totals AS (
  SELECT UNNEST(ARRAY['paid_search', 'paid_social', 'display', 'email', 'affiliate', 'tv']) AS channel,
	UNNEST(ARRAY[paid_search_spend, paid_social_spend, display_spend, email_spend, affiliate_spend, tv_spend]) AS total_spend,
	UNNEST(ARRAY[paid_search_revenue, paid_social_revenue, display_revenue, email_revenue, affiliate_revenue, tv_revenue]) AS total_revenue
  FROM aggregated

)
  SELECT channel,
	total_spend,
	total_revenue,
	ROUND(total_revenue / NULLIF(total_spend,0), 4) AS efficiency
  FROM channel_totals
  ORDER BY total_revenue DESC;


-- 4. Analyze channel performance
-- Month/quarter; Weekend vs weekday; Promotional vs non-promotional periods
-- Joins marketing spend, revenue and external factors on date. Adds month, quarter, weekend, and promotion flags dimensions.
WITH daily_data AS (
  SELECT ms.date,
	DATE_TRUNC('month', ms.date) AS month,
	DATE_TRUNC('quarter', ms.date) AS quarter,	
	ms.paid_search_spend,
	ms.paid_social_spend,
	ms.display_spend,
	ms.email_spend,
	ms.affiliate_spend,
	ms.tv_spend,
	r.revenue,
	(ms.paid_search_spend + ms.paid_social_spend + ms.display_spend +
         ms.email_spend + ms.affiliate_spend + ms.tv_spend) AS total_spend,
	ef.is_weekend,
	ef.promotion_active
	FROM marketing_spend ms
    LEFT JOIN revenue r 
		USING (date)
    LEFT JOIN external_factors ef 
	USING (date)
	
-- Allocate revenue proportionally to spend per channel
), proportional_revenue AS (
  SELECT *,
	revenue * (paid_search_spend / NULLIF(total_spend, 0)) AS paid_search_revenue,
	revenue * (paid_social_spend / NULLIF(total_spend, 0)) AS paid_social_revenue,
	revenue * (display_spend / NULLIF(total_spend, 0)) AS display_revenue,
	revenue * (email_spend / NULLIF(total_spend, 0)) AS email_revenue,
	revenue * (affiliate_spend / NULLIF(total_spend, 0)) AS affiliate_revenue,
	revenue * (tv_spend / NULLIF(total_spend, 0)) AS tv_revenue
  FROM daily_data
	
-- Aggregate spend and revenue by month, quarter, weekend, promotion
), aggregated AS (
  SELECT month,
	quarter,
	is_weekend,
	promotion_active,
	SUM(paid_search_spend) AS paid_search_spend,
	SUM(paid_social_spend) AS paid_social_spend,
	SUM(display_spend) AS display_spend,
	SUM(email_spend) AS email_spend,
	SUM(affiliate_spend) AS affiliate_spend,
	SUM(tv_spend) AS tv_spend,
	SUM(paid_search_revenue) AS paid_search_revenue,
	SUM(paid_social_revenue) AS paid_social_revenue,
	SUM(display_revenue) AS display_revenue,
	SUM(email_revenue) AS email_revenue,
	SUM(affiliate_revenue) AS affiliate_revenue,
	SUM(tv_revenue) AS tv_revenue
  FROM proportional_revenue
  GROUP BY 1,2,3,4

-- Pivot channels into rows using UNNEST	
), channel_totals AS (
  SELECT month,
	quarter,
	is_weekend,
	promotion_active,
	UNNEST(ARRAY['paid_search','paid_social','display','email','affiliate','tv']) AS channel,
	UNNEST(ARRAY[paid_search_spend, paid_social_spend, display_spend, email_spend, affiliate_spend, tv_spend]) AS total_spend,
	UNNEST(ARRAY[paid_search_revenue, paid_social_revenue, display_revenue, email_revenue, affiliate_revenue, tv_revenue]) AS total_revenue
  FROM aggregated

)
  SELECT month,
	quarter,
	is_weekend,
	promotion_active,
	channel,
	total_spend,
	total_revenue,
	ROUND(total_revenue / NULLIF(total_spend, 0), 4) AS roas
  FROM channel_totals
  ORDER BY month, quarter, is_weekend DESC, promotion_active DESC, total_revenue DESC;