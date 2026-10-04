SELECT variant_id, warehouse_id, movement_time::date AS d,
       count(*) AS movements, sum(qty) AS units_out,
       min(movement_time) AS first_move, max(movement_time) AS last_move
FROM ecom.inventory_movements
WHERE reference ILIKE '%cliff%'
GROUP BY 1, 2, 3;


-- Variants with zero stock everywhere and what they actually sold
SELECT ii.variant_id,
       sum(ii.on_hand)                                                    AS on_hand,
       count(oi.order_id)                                                 AS order_lines_all_time,
       coalesce(sum(oi.line_total), 0)                                    AS revenue_all_time
FROM ecom.inventory_items ii
LEFT JOIN ecom.order_items oi ON oi.variant_id = ii.variant_id
GROUP BY 1
HAVING sum(ii.on_hand) = 0
ORDER BY revenue_all_time DESC;


-- Paid revenue by category: May 13 vs prior-7-day daily average (every category falls, ratios 0.26-0.56)
WITH x AS (
  SELECT c.category_name, o.created_at::date AS d, sum(oi.line_total) AS rev
  FROM ecom.order_items oi
  JOIN ecom.orders o            ON o.order_id = oi.order_id AND o.payment_status = 'paid'
  JOIN ecom.product_variants pv ON pv.variant_id = oi.variant_id
  JOIN ecom.products p          ON p.product_id = pv.product_id
  JOIN ecom.categories c        ON c.category_id = p.category_id
  WHERE o.created_at >= '2026-05-06' AND o.created_at < '2026-05-14'
  GROUP BY 1, 2
)
SELECT category_name,
       round(sum(rev) FILTER (WHERE d < '2026-05-13') / 7.0)  AS avg_daily_prev_7d,
       coalesce(sum(rev) FILTER (WHERE d = '2026-05-13'), 0)   AS may13,
       round((coalesce(sum(rev) FILTER (WHERE d = '2026-05-13'), 0)
              / nullif(sum(rev) FILTER (WHERE d < '2026-05-13') / 7.0, 0))::numeric, 2) AS ratio
FROM x
GROUP BY 1
ORDER BY ratio;
