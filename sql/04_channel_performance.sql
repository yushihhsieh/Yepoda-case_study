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
	
), channel_allocations AS (
 SELECT 'paid_search' AS channel,
	SUM(paid_search_spend) AS total_spend,
-- NULLIF() to prevent division by zero
	SUM(revenue * (paid_search_spend / NULLIF(total_spend, 0))) AS total_revenue
 FROM daily_data
 UNION ALL
 SELECT 'paid_social',
	SUM(paid_social_spend),
    SUM(revenue * (paid_social_spend / NULLIF(total_spend, 0)))
 FROM daily_data
 UNION ALL
 SELECT 'display',
	SUM(display_spend),
    SUM(revenue * (display_spend / NULLIF(total_spend, 0)))
 FROM daily_data
 UNION ALL
 SELECT 'email',
    SUM(email_spend),
    SUM(revenue * (email_spend / NULLIF(total_spend, 0)))
 FROM daily_data
 UNION ALL
 SELECT 'affiliate',
    SUM(affiliate_spend),
    SUM(revenue * (affiliate_spend / NULLIF(total_spend, 0)))
 FROM daily_data
 UNION ALL
 SELECT 'tv',
	SUM(tv_spend),
    SUM(revenue * (tv_spend / NULLIF(total_spend, 0)))
 FROM daily_data
)
 SELECT channel, 
	total_spend, 
	total_revenue
 FROM channel_allocations
 ORDER BY total_revenue DESC;


-- 2. Compute ROAS (Return on Ad Spend) for each channel 
-- Use 7-day, 14-day, and 30-day attribution windows	
-- Create 30-day lookhead window per spend date
-- Add total_spend for proportional attribution
WITH base_data AS (
  SELECT s.date AS spend_date,
	r.date AS revenue_date,
    r.revenue,
    s.paid_search_spend,
    s.paid_social_spend,
    s.display_spend,
    s.email_spend,
    s.affiliate_spend,
    s.tv_spend,
    (s.paid_search_spend + s.paid_social_spend + s.display_spend +
     s.email_spend + s.affiliate_spend + s.tv_spend) AS total_spend
  FROM marketing_spend s
  JOIN revenue r
    ON r.date BETWEEN s.date AND s.date + INTERVAL '30 day'

-- Aggregate revenue by 7-, 14- and 30-day windows for each spend date	
), attributed_revenue AS (
  SELECT spend_date,
    paid_search_spend,
    paid_social_spend,
    display_spend,
    email_spend,
    affiliate_spend,
    tv_spend,
    total_spend,
    SUM(CASE WHEN revenue_date <= spend_date + INTERVAL '7 day' THEN revenue ELSE 0 END) AS revenue_7d,
    SUM(CASE WHEN revenue_date <= spend_date + INTERVAL '14 day' THEN revenue ELSE 0 END) AS revenue_14d,
    SUM(CASE WHEN revenue_date <= spend_date + INTERVAL '30 day' THEN revenue ELSE 0 END) AS revenue_30d	
  FROM base_data
  GROUP BY 1,2,3,4,5,6,7,8

-- Sum total spend and total attributed revenue across all dates	
), channel_totals AS (
  SELECT
    SUM(paid_search_spend) AS paid_search_spend,
    SUM(paid_social_spend) AS paid_social_spend,
    SUM(display_spend) AS display_spend,
    SUM(email_spend) AS email_spend,
    SUM(affiliate_spend) AS affiliate_spend,
    SUM(tv_spend) AS tv_spend,
    SUM(revenue_7d) AS revenue_7d,
    SUM(revenue_14d) AS revenue_14d,
    SUM(revenue_30d) AS revenue_30d
  FROM attributed_revenue

-- Calculate ROAS for each channel and attribution windown
-- Formula: Revenue/Spend
-- Union all channels	
), roas_by_channel AS (
  SELECT 'paid_search' AS channel,
	paid_search_spend AS total_spend,
	revenue_7d / NULLIF(paid_search_spend, 0) AS roas_7d,
	revenue_14d / NULLIF(paid_search_spend, 0) AS roas_14d,
	revenue_30d / NULLIF(paid_search_spend, 0) AS roas_30d
  FROM channel_totals
  UNION ALL
  SELECT 'paid_social',
	paid_social_spend,
	revenue_7d / NULLIF(paid_social_spend, 0),
    revenue_14d / NULLIF(paid_social_spend, 0),
    revenue_30d / NULLIF(paid_social_spend, 0)
  FROM channel_totals
  UNION ALL
  SELECT 'display',
	display_spend,
	revenue_7d / NULLIF(display_spend, 0),
	revenue_14d / NULLIF(display_spend, 0),
	revenue_30d / NULLIF(display_spend, 0)
  FROM channel_totals
  UNION ALL
  SELECT 'email',
	email_spend,
	revenue_7d / NULLIF(email_spend, 0),
	revenue_14d / NULLIF(email_spend, 0),
	revenue_30d / NULLIF(email_spend, 0)
  FROM channel_totals
  UNION ALL
  SELECT 'affiliate',
	affiliate_spend,
	revenue_7d / NULLIF(affiliate_spend, 0),
	revenue_14d / NULLIF(affiliate_spend, 0),
	revenue_30d / NULLIF(affiliate_spend, 0)
  FROM channel_totals
  UNION ALL
  SELECT 'tv',
	tv_spend,
	revenue_7d / NULLIF(tv_spend, 0),
	revenue_14d / NULLIF(tv_spend, 0),
	revenue_30d / NULLIF(tv_spend, 0)
  FROM channel_totals
)
  SELECT *
  FROM roas_by_channel
  ORDER BY channel;


-- 3. Identify the top and bottom performing channels
-- by Total revenue generated; by Effi ciency (revenue per dollar spent)
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
	
), channel_allocations AS (
 SELECT 'paid_search' AS channel,
	SUM(paid_search_spend) AS total_spend,
-- NULLIF() to prevent division by zero
	SUM(revenue * (paid_search_spend / NULLIF(total_spend, 0))) AS total_revenue
 FROM daily_data
 UNION ALL
 SELECT 'paid_social',
	SUM(paid_social_spend),
    SUM(revenue * (paid_social_spend / NULLIF(total_spend, 0)))
 FROM daily_data
 UNION ALL
 SELECT 'display',
	SUM(display_spend),
    SUM(revenue * (display_spend / NULLIF(total_spend, 0)))
 FROM daily_data
 UNION ALL
 SELECT 'email',
    SUM(email_spend),
    SUM(revenue * (email_spend / NULLIF(total_spend, 0)))
 FROM daily_data
 UNION ALL
 SELECT 'affiliate',
    SUM(affiliate_spend),
    SUM(revenue * (affiliate_spend / NULLIF(total_spend, 0)))
 FROM daily_data
 UNION ALL
 SELECT 'tv',
	SUM(tv_spend),
    SUM(revenue * (tv_spend / NULLIF(total_spend, 0)))
 FROM daily_data
)
 SELECT channel, 
	total_spend, 
	total_revenue,
	total_revenue/ total_spend AS efficiency
 FROM channel_allocations
 ORDER BY total_revenue DESC;


-- 4. Analyze channel performance
-- Joins marketing spend, revenue and external factors on date. Adds month, quarter, weekend, and promotion flags dimensions.
WITH base_data AS (
  SELECT s.date,
	DATE_TRUNC('month', s.date)::date AS month,
	DATE_TRUNC('quarter', s.date)::date AS quarter,
	ef.is_weekend,
	ef.promotion_active,
	r.revenue,
	s.paid_search_spend,
	s.paid_social_spend,
	s.display_spend,
	s.email_spend,
	s.affiliate_spend,
	s.tv_spend,
	(s.paid_search_spend + s.paid_social_spend + s.display_spend +
	s.email_spend + s.affiliate_spend + s.tv_spend) AS total_spend
  FROM marketing_spend s
  LEFT JOIN revenue r 
	ON s.date = r.date
  LEFT JOIN external_factors ef 
	ON s.date = ef.date

-- Pivot the spend columns into channel rows
), channel_data AS (
  SELECT bd.month,
	bd.quarter,
	bd.is_weekend,
	bd.promotion_active,
	ch.channel,
	ch.spend,
	bd.revenue,
	bd.total_spend
  FROM base_data bd
  CROSS JOIN LATERAL (
	VALUES
		('paid_search', bd.paid_search_spend),
	    ('paid_social', bd.paid_social_spend),
        ('display', bd.display_spend),
        ('email', bd.email_spend),
        ('affiliate', bd.affiliate_spend),
        ('tv', bd.tv_spend)
    ) AS ch(channel, spend)

-- Aggregate spend and revenue by channel and segments
), aggregated AS (
  SELECT month,
	quarter,
	is_weekend,
	promotion_active,
	channel,
	SUM(spend) AS total_spend,
	SUM(revenue * (spend / NULLIF(total_spend, 0))) AS total_revenue,
	SUM(spend) AS total_channel_spend
  FROM channel_data
  GROUP BY 1,2,3,4,5

)
  SELECT month,
	quarter,
    is_weekend,
    promotion_active,
    channel,
    total_spend,
    total_revenue,
    total_revenue / NULLIF(total_spend, 0) AS roas
  FROM aggregated
  ORDER BY month, channel, promotion_active, is_weekend;
