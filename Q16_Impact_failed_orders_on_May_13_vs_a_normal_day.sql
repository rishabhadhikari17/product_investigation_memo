WITH daily AS (
  SELECT created_at::date AS d,
         count(*) FILTER (WHERE payment_status = 'failed')           AS failed_orders,
         sum(total) FILTER (WHERE payment_status = 'failed')         AS failed_value
  FROM ecom.orders
  WHERE created_at >= '2026-05-06' AND created_at < '2026-05-14'
  GROUP BY 1
)
SELECT m.failed_orders                                                   AS may13_failed_orders,
       round(m.failed_value::numeric, 0)                                 AS may13_failed_value,
       round(avg(b.failed_orders)::numeric, 1)                           AS normal_failed_per_day,
       round((m.failed_orders - avg(b.failed_orders))::numeric, 1)       AS excess_failed_orders,
       round((m.failed_value * (1 - avg(b.failed_orders) / m.failed_orders))::numeric, 0) AS excess_failed_value
FROM daily m
JOIN daily b ON b.d BETWEEN '2026-05-06' AND '2026-05-12'
WHERE m.d = '2026-05-13'
GROUP BY m.failed_orders, m.failed_value;
 
