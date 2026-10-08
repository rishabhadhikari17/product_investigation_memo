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
vw AS (
  SELECT se.occurred_at::date AS d,
         count(*) AS total_views,
         count(*) FILTER (WHERE b.tier <> 'rest') AS paradox_views
  FROM ecom.session_events se JOIN pdp_base b ON b.pid = se.product_id::bigint
  WHERE se.event_type = 'product_view'
    AND se.occurred_at >= '2026-05-08' AND se.occurred_at < '2026-05-19'
  GROUP BY 1
), ln AS (
  SELECT o.created_at::date AS d,
         sum(oi.line_total) FILTER (WHERE lower(o.payment_status) = 'paid') AS paid_rev,
         sum(oi.line_total) FILTER (WHERE lower(o.payment_status) = 'paid' AND b.tier <> 'rest') AS paradox_paid_rev,
         sum(oi.line_total) FILTER (WHERE lower(o.payment_status) = 'failed') AS failed_val,
         sum(oi.line_total) FILTER (WHERE lower(o.payment_status) = 'failed' AND b.tier <> 'rest') AS paradox_failed_val
  FROM ecom.order_items oi
  JOIN ecom.orders o ON o.order_id = oi.order_id
  JOIN ecom.product_variants pv ON pv.variant_id = oi.variant_id
  JOIN pdp_base b ON b.pid = pv.product_id
  WHERE o.created_at >= '2026-05-08' AND o.created_at < '2026-05-19'
  GROUP BY 1
)
SELECT vw.d, vw.total_views, vw.paradox_views,
       round(100.0 * vw.paradox_views / vw.total_views, 1)          AS paradox_pct_of_views,
       ln.paid_rev, ln.paradox_paid_rev,
       round(100.0 * ln.paradox_paid_rev / nullif(ln.paid_rev, 0), 1)     AS paradox_pct_of_paid_rev,
       round(100.0 * ln.paradox_failed_val / nullif(ln.failed_val, 0), 1) AS paradox_pct_of_failed_val
FROM vw JOIN ln ON ln.d = vw.d
ORDER BY vw.d;
