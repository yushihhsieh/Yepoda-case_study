-- 1. Identify spending patterns of consistency and variability
WITH unpivoted AS (
  SELECT date,
	unnest(array['paid_search_spend','paid_social_spend','display_spend','email_spend','affiliate_spend','tv_spend']) AS channel,
	unnest(array[paid_search_spend, paid_social_spend, display_spend, email_spend, affiliate_spend, tv_spend]) AS spend
  FROM marketing_spend

-- Compute Coefficient of variation
-- Formula: STDDEV/AVG
-- more Smaller CV, more consistent; larger CV, more variable	
)
  SELECT channel,
	AVG(spend) AS avg_spend,
	STDDEV(spend) AS stddev_spend,
	STDDEV(spend)/NULLIF(AVG(spend),0) AS cv
  FROM unpivoted
  GROUP BY 1
  ORDER BY cv ASC;


-- 2. Calculate efficiency curves
WITH unpivoted AS (
  SELECT m.date,
	unnest(array['paid_search_spend','paid_social_spend','display_spend','email_spend','affiliate_spend','tv_spend']) AS channel,
	unnest(array[paid_search_spend, paid_social_spend, display_spend, email_spend, affiliate_spend, tv_spend]) AS spend,
	r.revenue
  FROM marketing_spend m
  LEFT JOIN revenue r 
	USING(date)

-- NTILE() window function to assign deciles per channel
-- Lower decile, lower spend days
), spend_deciles AS (
  SELECT channel,
	spend,
	revenue,
	NTILE(10) OVER (PARTITION BY channel ORDER BY spend) AS spend_decile
  FROM unpivoted

-- Compute average ROAS per decile
), roas_per_decile AS (
  SELECT channel,
	spend_decile,
	AVG(spend) AS avg_spend,
	AVG(CASE WHEN spend > 0 THEN revenue/spend ELSE NULL END) AS avg_roas
  FROM spend_deciles
  GROUP BY 1, 2

)
  SELECT *
  FROM roas_per_decile
  ORDER BY channel, spend_decile;
  
-- 3. Provide budget reallocation recommendations
WITH combined AS (
  SELECT r.revenue,
	m.paid_search_spend,
	m.paid_social_spend,
	m.display_spend,
 	m.email_spend,
	m.affiliate_spend,
	m.tv_spend
  FROM marketing_spend m
  LEFT JOIN revenue r
	USING(date)

-- Aggregate overall totals
), totals AS (
  SELECT SUM(paid_search_spend) AS paid_search_spend,
	SUM(paid_social_spend) AS paid_social_spend,
	SUM(display_spend) AS display_spend,
	SUM(email_spend) AS email_spend,
	SUM(affiliate_spend) AS affiliate_spend,
	SUM(tv_spend) AS tv_spend,
	SUM(revenue) AS total_revenue
  FROM combined

-- Unpivot channel and spend
), unpivoted AS (
  SELECT
	UNNEST(ARRAY['paid_search', 'paid_social', 'display', 'email', 'affiliate', 'tv']) AS channel,
	UNNEST(ARRAY[paid_search_spend, paid_social_spend, display_spend, email_spend, affiliate_spend, tv_spend]) AS spend
  FROM totals

-- Calculate ROAS
), calc AS (
  SELECT u.channel,
	u.spend AS current_spend,
	SUM(t.total_revenue) OVER () / NULLIF(u.spend, 0) AS roas,
	SUM(u.spend) OVER () AS total_spend
  FROM unpivoted u
	CROSS JOIN totals t

-- Compute recommended share and revenue change
)
  SELECT channel,
	ROUND(current_spend, 2) AS current_spend,
	ROUND(current_spend / total_spend, 4) AS current_share,
	ROUND(roas, 4) AS current_roas,

	-- Recommended share proportional to ROAS
	ROUND(roas / SUM(roas) OVER (), 4) AS recommended_share,

	-- Reallocate same total spend based on efficiency
	ROUND(total_spend * (roas / SUM(roas) OVER ()), 2) AS recommended_spend,

	-- Expected revenue from new allocation
	ROUND(total_spend * (roas / SUM(roas) OVER ()) * roas, 2) AS expected_revenue,

	-- Expected revenue lift/loss per channel
	ROUND((total_spend * (roas / SUM(roas) OVER ()) * roas) - (current_spend * roas), 2) AS revenue_change
  FROM calc
  ORDER BY channel;
