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
win AS (
  SELECT sum(revenue) AS tot_rev,
         sum(revenue) FILTER (WHERE tier <> 'rest') AS paradox_rev,
         sum(units)   FILTER (WHERE tier <> 'rest') AS paradox_units,
         sum(n_views) FILTER (WHERE tier <> 'rest') AS paradox_views
  FROM pdp_base
)
SELECT round(paradox_rev / 57.0)                    AS paradox_paid_rev_per_day,
       round(100.0 * paradox_rev / tot_rev, 2)       AS paradox_pct_of_paid_rev,
       round(paradox_rev / nullif(paradox_units, 0)) AS revenue_per_unit,
       paradox_views, paradox_units
FROM win;
