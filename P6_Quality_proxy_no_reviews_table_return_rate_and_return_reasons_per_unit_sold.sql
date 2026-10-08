WITH pdp_base AS (
  WITH v AS (
    SELECT product_id::bigint AS pid, count(*) AS n_views
    FROM ecom.session_events WHERE event_type = 'product_view' GROUP BY 1
  ), c AS (
    SELECT product_id::bigint AS pid, count(*) AS n_carts
    FROM ecom.session_events WHERE event_type = 'add_to_cart' GROUP BY 1
  ), p AS (
    SELECT pv.product_id AS pid, sum(oi.qty) AS units, sum(oi.line_total) AS revenue
    FROM ecom.order_items oi
    JOIN ecom.orders o ON o.order_id = oi.order_id
    JOIN ecom.product_variants pv ON pv.variant_id = oi.variant_id
    WHERE lower(o.payment_status) = 'paid' AND o.created_at >= '2026-04-19'
    GROUP BY 1
  ), j AS (
    SELECT v.pid, v.n_views, coalesce(c.n_carts, 0) AS n_carts,
           coalesce(p.units, 0) AS units, coalesce(p.revenue, 0) AS revenue
    FROM v LEFT JOIN c ON c.pid = v.pid LEFT JOIN p ON p.pid = v.pid
  )
  SELECT j.*,
         j.n_views::float8 / sum(j.n_views) OVER ()                                    AS view_share,
         j.units::float8 / sum(j.units) OVER ()                                        AS purchase_share,
         (j.n_views::float8 / sum(j.n_views) OVER ())
           / nullif(j.units::float8 / sum(j.units) OVER (), 0)                         AS ratio,
         CASE WHEN j.n_views >= 30
               AND (j.n_views::float8 / sum(j.n_views) OVER ())
                   / nullif(j.units::float8 / sum(j.units) OVER (), 0) >= 5 THEN '5x+'
              WHEN j.n_views >= 30
               AND (j.n_views::float8 / sum(j.n_views) OVER ())
                   / nullif(j.units::float8 / sum(j.units) OVER (), 0) >= 3 THEN '3-5x'
              ELSE 'rest' END                                                          AS tier
  FROM j
),
r AS (
  SELECT pv.product_id AS pid,
         count(*) AS n_returns,
         count(*) FILTER (WHERE rr.reason_text = 'Not as described') AS not_as_described,
         count(*) FILTER (WHERE rr.reason_text IN ('Defective', 'Damaged item')) AS defective_or_damaged
  FROM ecom.return_items ri
  JOIN ecom.product_variants pv ON pv.variant_id = ri.variant_id
  JOIN ecom.return_reasons rr ON rr.reason_id = ri.reason_id
  GROUP BY 1
)
SELECT b.tier, sum(b.units) AS units,
       round(coalesce(sum(r.n_returns), 0)::numeric / sum(b.units), 3)           AS return_rate,
       round(coalesce(sum(r.not_as_described), 0)::numeric / sum(b.units), 4)    AS not_as_described_rate,
       round(coalesce(sum(r.defective_or_damaged), 0)::numeric / sum(b.units), 4) AS defect_damage_rate
FROM pdp_base b LEFT JOIN r ON r.pid = b.pid
GROUP BY b.tier ORDER BY b.tier;


-- Reviews by tier: coverage, average rating and share of 1-2 star and 5 star reviews

WITH pdp_base AS (
  WITH v AS (
    SELECT product_id::bigint AS pid, count(*) AS n_views
    FROM ecom.session_events WHERE event_type = 'product_view' GROUP BY 1
  ), c AS (
    SELECT product_id::bigint AS pid, count(*) AS n_carts
    FROM ecom.session_events WHERE event_type = 'add_to_cart' GROUP BY 1
  ), p AS (
    SELECT pv.product_id AS pid, sum(oi.qty) AS units, sum(oi.line_total) AS revenue
    FROM ecom.order_items oi
    JOIN ecom.orders o ON o.order_id = oi.order_id
    JOIN ecom.product_variants pv ON pv.variant_id = oi.variant_id
    WHERE lower(o.payment_status) = 'paid' AND o.created_at >= '2026-04-19'
    GROUP BY 1
  ), j AS (
    SELECT v.pid, v.n_views, coalesce(c.n_carts, 0) AS n_carts,
           coalesce(p.units, 0) AS units, coalesce(p.revenue, 0) AS revenue
    FROM v LEFT JOIN c ON c.pid = v.pid LEFT JOIN p ON p.pid = v.pid
  )
  SELECT j.*,
         j.n_views::float8 / sum(j.n_views) OVER ()                                    AS view_share,
         j.units::float8 / sum(j.units) OVER ()                                        AS purchase_share,
         (j.n_views::float8 / sum(j.n_views) OVER ())
           / nullif(j.units::float8 / sum(j.units) OVER (), 0)                         AS ratio,
         CASE WHEN j.n_views >= 30
               AND (j.n_views::float8 / sum(j.n_views) OVER ())
                   / nullif(j.units::float8 / sum(j.units) OVER (), 0) >= 5 THEN '5x+'
              WHEN j.n_views >= 30
               AND (j.n_views::float8 / sum(j.n_views) OVER ())
                   / nullif(j.units::float8 / sum(j.units) OVER (), 0) >= 3 THEN '3-5x'
              ELSE 'rest' END                                                          AS tier
  FROM j
),
r AS (
  SELECT product_id AS pid, count(*) AS n_reviews, avg(rating) AS avg_rating,
         count(*) FILTER (WHERE rating <= 2) AS n_low, count(*) FILTER (WHERE rating = 5) AS n_five
  FROM ecom.product_reviews GROUP BY 1
)
SELECT b.tier, count(*) AS products,
       count(*) FILTER (WHERE r.n_reviews > 0) AS products_with_reviews,
       round(avg(coalesce(r.n_reviews, 0))::numeric, 2) AS avg_reviews_per_product,
       round(sum(r.n_reviews)::numeric / sum(b.units), 3) AS reviews_per_unit_sold,
       round((sum(r.avg_rating * r.n_reviews) / sum(r.n_reviews))::numeric, 2) AS avg_rating,
       round(sum(r.n_low)::numeric / sum(r.n_reviews), 3) AS share_1_2_star,
       round(sum(r.n_five)::numeric / sum(r.n_reviews), 3) AS share_5_star
FROM pdp_base b LEFT JOIN r ON r.pid = b.pid
GROUP BY b.tier ORDER BY b.tier;


-- Do reviews drive conversion? View-to-cart by review count and by average rating (all products)
WITH pdp_base AS (
  WITH v AS (
    SELECT product_id::bigint AS pid, count(*) AS n_views
    FROM ecom.session_events WHERE event_type = 'product_view' GROUP BY 1
  ), c AS (
    SELECT product_id::bigint AS pid, count(*) AS n_carts
    FROM ecom.session_events WHERE event_type = 'add_to_cart' GROUP BY 1
  ), p AS (
    SELECT pv.product_id AS pid, sum(oi.qty) AS units, sum(oi.line_total) AS revenue
    FROM ecom.order_items oi
    JOIN ecom.orders o ON o.order_id = oi.order_id
    JOIN ecom.product_variants pv ON pv.variant_id = oi.variant_id
    WHERE lower(o.payment_status) = 'paid' AND o.created_at >= '2026-04-19'
    GROUP BY 1
  ), j AS (
    SELECT v.pid, v.n_views, coalesce(c.n_carts, 0) AS n_carts,
           coalesce(p.units, 0) AS units, coalesce(p.revenue, 0) AS revenue
    FROM v LEFT JOIN c ON c.pid = v.pid LEFT JOIN p ON p.pid = v.pid
  )
  SELECT j.*,
         j.n_views::float8 / sum(j.n_views) OVER ()                                    AS view_share,
         j.units::float8 / sum(j.units) OVER ()                                        AS purchase_share,
         (j.n_views::float8 / sum(j.n_views) OVER ())
           / nullif(j.units::float8 / sum(j.units) OVER (), 0)                         AS ratio,
         CASE WHEN j.n_views >= 30
               AND (j.n_views::float8 / sum(j.n_views) OVER ())
                   / nullif(j.units::float8 / sum(j.units) OVER (), 0) >= 5 THEN '5x+'
              WHEN j.n_views >= 30
               AND (j.n_views::float8 / sum(j.n_views) OVER ())
                   / nullif(j.units::float8 / sum(j.units) OVER (), 0) >= 3 THEN '3-5x'
              ELSE 'rest' END                                                          AS tier
  FROM j
),
r AS (
  SELECT product_id AS pid, count(*) AS n_reviews, avg(rating) AS avg_rating
  FROM ecom.product_reviews GROUP BY 1
)
SELECT CASE WHEN r.n_reviews IS NULL THEN 'a. no reviews'
            WHEN r.n_reviews = 1 THEN 'b. 1 review'
            WHEN r.n_reviews = 2 THEN 'c. 2 reviews'
            ELSE 'd. 3+ reviews' END AS review_count_band,
       count(*) AS products,
       round(sum(b.n_carts)::numeric / sum(b.n_views), 3) AS view_to_cart,
       round(sum(b.units)::numeric / sum(b.n_views), 3) AS units_per_view
FROM pdp_base b LEFT JOIN r ON r.pid = b.pid
GROUP BY 1 ORDER BY 1;
 
WITH pdp_base AS (
  WITH v AS (
    SELECT product_id::bigint AS pid, count(*) AS n_views
    FROM ecom.session_events WHERE event_type = 'product_view' GROUP BY 1
  ), c AS (
    SELECT product_id::bigint AS pid, count(*) AS n_carts
    FROM ecom.session_events WHERE event_type = 'add_to_cart' GROUP BY 1
  ), p AS (
    SELECT pv.product_id AS pid, sum(oi.qty) AS units, sum(oi.line_total) AS revenue
    FROM ecom.order_items oi
    JOIN ecom.orders o ON o.order_id = oi.order_id
    JOIN ecom.product_variants pv ON pv.variant_id = oi.variant_id
    WHERE lower(o.payment_status) = 'paid' AND o.created_at >= '2026-04-19'
    GROUP BY 1
  ), j AS (
    SELECT v.pid, v.n_views, coalesce(c.n_carts, 0) AS n_carts,
           coalesce(p.units, 0) AS units, coalesce(p.revenue, 0) AS revenue
    FROM v LEFT JOIN c ON c.pid = v.pid LEFT JOIN p ON p.pid = v.pid
  )
  SELECT j.*,
         j.n_views::float8 / sum(j.n_views) OVER ()                                    AS view_share,
         j.units::float8 / sum(j.units) OVER ()                                        AS purchase_share,
         (j.n_views::float8 / sum(j.n_views) OVER ())
           / nullif(j.units::float8 / sum(j.units) OVER (), 0)                         AS ratio,
         CASE WHEN j.n_views >= 30
               AND (j.n_views::float8 / sum(j.n_views) OVER ())
                   / nullif(j.units::float8 / sum(j.units) OVER (), 0) >= 5 THEN '5x+'
              WHEN j.n_views >= 30
               AND (j.n_views::float8 / sum(j.n_views) OVER ())
                   / nullif(j.units::float8 / sum(j.units) OVER (), 0) >= 3 THEN '3-5x'
              ELSE 'rest' END                                                          AS tier
  FROM j
),
r AS (
  SELECT product_id AS pid, avg(rating) AS avg_rating FROM ecom.product_reviews GROUP BY 1
)
SELECT CASE WHEN r.avg_rating >= 4.5 THEN 'd. 4.5-5'
            WHEN r.avg_rating >= 4   THEN 'c. 4-4.5'
            WHEN r.avg_rating >= 3   THEN 'b. 3-4'
            ELSE 'a. under 3' END AS rating_band,
       count(*) AS products,
       round(sum(b.n_carts)::numeric / sum(b.n_views), 3) AS view_to_cart,
       round(sum(b.units)::numeric / sum(b.n_views), 3) AS units_per_view,
       round(avg(CASE WHEN b.tier <> 'rest' THEN 1 ELSE 0 END)::numeric, 3) AS share_paradox
FROM pdp_base b JOIN r ON r.pid = b.pid
GROUP BY 1 ORDER BY 1;


-- Reviews on the top paradox products
WITH pdp_base AS (
  WITH v AS (
    SELECT product_id::bigint AS pid, count(*) AS n_views
    FROM ecom.session_events WHERE event_type = 'product_view' GROUP BY 1
  ), c AS (
    SELECT product_id::bigint AS pid, count(*) AS n_carts
    FROM ecom.session_events WHERE event_type = 'add_to_cart' GROUP BY 1
  ), p AS (
    SELECT pv.product_id AS pid, sum(oi.qty) AS units, sum(oi.line_total) AS revenue
    FROM ecom.order_items oi
    JOIN ecom.orders o ON o.order_id = oi.order_id
    JOIN ecom.product_variants pv ON pv.variant_id = oi.variant_id
    WHERE lower(o.payment_status) = 'paid' AND o.created_at >= '2026-04-19'
    GROUP BY 1
  ), j AS (
    SELECT v.pid, v.n_views, coalesce(c.n_carts, 0) AS n_carts,
           coalesce(p.units, 0) AS units, coalesce(p.revenue, 0) AS revenue
    FROM v LEFT JOIN c ON c.pid = v.pid LEFT JOIN p ON p.pid = v.pid
  )
  SELECT j.*,
         j.n_views::float8 / sum(j.n_views) OVER ()                                    AS view_share,
         j.units::float8 / sum(j.units) OVER ()                                        AS purchase_share,
         (j.n_views::float8 / sum(j.n_views) OVER ())
           / nullif(j.units::float8 / sum(j.units) OVER (), 0)                         AS ratio,
         CASE WHEN j.n_views >= 30
               AND (j.n_views::float8 / sum(j.n_views) OVER ())
                   / nullif(j.units::float8 / sum(j.units) OVER (), 0) >= 5 THEN '5x+'
              WHEN j.n_views >= 30
               AND (j.n_views::float8 / sum(j.n_views) OVER ())
                   / nullif(j.units::float8 / sum(j.units) OVER (), 0) >= 3 THEN '3-5x'
              ELSE 'rest' END                                                          AS tier
  FROM j
)
SELECT b.pid, p.product_name, b.n_views, b.units, round(b.ratio::numeric, 1) AS ratio,
       count(r.review_id) AS n_reviews, round(avg(r.rating)::numeric, 2) AS avg_rating
FROM pdp_base b
JOIN ecom.products p ON p.product_id = b.pid
LEFT JOIN ecom.product_reviews r ON r.product_id = b.pid
WHERE b.tier <> 'rest'
GROUP BY b.pid, p.product_name, b.n_views, b.units, b.ratio
ORDER BY b.n_views DESC
LIMIT 15;


-- Data quality: reviews attached to orders that were never paid
SELECT lower(o.payment_status) AS order_payment_status, count(*) AS reviews
FROM ecom.product_reviews r JOIN ecom.orders o ON o.order_id = r.order_id
GROUP BY 1 ORDER BY 2 DESC;
