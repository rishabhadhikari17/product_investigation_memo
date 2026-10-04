WITH a AS (
  SELECT o.created_at::date AS d, pm.method_name, count(*) AS n
  FROM ecom.orders o
  JOIN ecom.payment_intents i  ON i.order_id = o.order_id
  JOIN ecom.payment_methods pm ON pm.payment_method_id = i.payment_method_id
  WHERE EXTRACT(HOUR FROM o.created_at) BETWEEN 9 AND 16
    AND o.created_at >= '2026-05-06' AND o.created_at < '2026-05-14'
  GROUP BY 1, 2
)
SELECT method_name,
       round(sum(n) FILTER (WHERE d < '2026-05-13') / 7.0, 1)                       AS avg_per_day_prev_7d,
       round(100.0 * sum(n) FILTER (WHERE d < '2026-05-13')
             / sum(sum(n) FILTER (WHERE d < '2026-05-13')) OVER (), 1)              AS share_pct_prev_7d,
       coalesce(sum(n) FILTER (WHERE d = '2026-05-13'), 0)                          AS may13,
       round(100.0 * coalesce(sum(n) FILTER (WHERE d = '2026-05-13'), 0)
             / sum(sum(n) FILTER (WHERE d = '2026-05-13')) OVER (), 1)              AS share_pct_may13
FROM a
GROUP BY method_name
ORDER BY 2 DESC;
