WITH v AS (
  SELECT variant_id::bigint AS vid, count(*) AS n_views
  FROM ecom.session_events WHERE event_type = 'product_view' GROUP BY 1
), u AS (
  SELECT oi.variant_id AS vid, sum(oi.qty) AS units
  FROM ecom.order_items oi JOIN ecom.orders o ON o.order_id = oi.order_id
  WHERE lower(o.payment_status) = 'paid' AND o.created_at >= '2026-04-19'
  GROUP BY 1
), s AS (
  SELECT v.vid, v.n_views, coalesce(u.units, 0) AS units,
         v.n_views::float8 / sum(v.n_views) OVER ()                                  AS vshare,
         coalesce(u.units, 0)::float8 / sum(coalesce(u.units, 0)) OVER ()            AS pshare
  FROM v LEFT JOIN u ON u.vid = v.vid
)
SELECT pv.sku, pv.product_id, s.n_views, s.units,
       round((s.vshare / nullif(s.pshare, 0))::numeric, 1) AS ratio
FROM s JOIN ecom.product_variants pv ON pv.variant_id = s.vid
WHERE s.n_views >= 30 AND s.vshare / nullif(s.pshare, 0) >= 3
ORDER BY s.n_views DESC
LIMIT 25;
