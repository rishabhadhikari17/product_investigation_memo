SELECT created_at::date                                              AS d	,
       EXTRACT(DOW FROM created_at::date)::int                       AS dow,   -- 0 = Sunday
       count(*)                                                      AS orders,
       count(*) FILTER (WHERE payment_status = 'paid')               AS paid_orders,
       count(*) FILTER (WHERE payment_status = 'failed')             AS failed_orders,
       round(avg((payment_status = 'paid')::int)::numeric, 3)        AS paid_rate,
       round(sum(total)::numeric, 0)                                 AS revenue_all_orders,  -- what q1 shows
       round(sum(total) FILTER (WHERE payment_status = 'paid')::numeric, 0) AS revenue_paid
FROM ecom.orders
WHERE created_at >= '2026-05-01' AND created_at < '2026-05-21'
GROUP BY 1, 2
ORDER BY 1;
