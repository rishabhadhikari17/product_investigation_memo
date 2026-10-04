WITH h AS (
  SELECT created_at::date                         AS d,
         EXTRACT(HOUR FROM created_at)::int       AS hr,
         count(*)                                 AS orders,
         count(*) FILTER (WHERE payment_status = 'failed') AS failed
  FROM ecom.orders
  WHERE created_at >= '2026-05-06' AND created_at < '2026-05-14'
  GROUP BY 1, 2
)
SELECT hr,
       round(sum(orders) FILTER (WHERE d < '2026-05-13') / 7.0, 1) AS base_orders_per_day,
       round(sum(failed) FILTER (WHERE d < '2026-05-13') / 7.0, 1) AS base_failed_per_day,
       coalesce(sum(orders) FILTER (WHERE d = '2026-05-13'), 0)    AS may13_orders,
       coalesce(sum(failed) FILTER (WHERE d = '2026-05-13'), 0)    AS may13_failed
FROM h
GROUP BY hr
ORDER BY hr;
