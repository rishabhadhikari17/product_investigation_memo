WITH daily AS (
  SELECT created_at::date AS d,
         count(*)                                                    AS orders,
         count(*) FILTER (WHERE payment_status = 'paid')             AS paid_orders,
         sum(total)                                                  AS revenue_all,
         sum(total) FILTER (WHERE payment_status = 'paid')           AS revenue_paid
  FROM ecom.orders
  GROUP BY 1
),
m  AS (SELECT * FROM daily WHERE d = '2026-05-13'),
b7 AS (SELECT avg(orders) AS orders, avg(paid_orders) AS paid_orders,
              avg(revenue_all) AS revenue_all, avg(revenue_paid) AS revenue_paid
       FROM daily WHERE d BETWEEN '2026-05-06' AND '2026-05-12'),
w4 AS (SELECT avg(orders) AS orders, avg(paid_orders) AS paid_orders,
              avg(revenue_all) AS revenue_all, avg(revenue_paid) AS revenue_paid
       FROM daily WHERE d IN ('2026-04-15', '2026-04-22', '2026-04-29', '2026-05-06'))
SELECT 'orders created' AS metric,
       m.orders::numeric AS may13,
       round(b7.orders::numeric, 1)  AS avg_prev_7d,  round((m.orders / b7.orders - 1)::numeric * 100, 1) AS pct_vs_7d,
       round(w4.orders::numeric, 1)  AS avg_prev_4_wed, round((m.orders / w4.orders - 1)::numeric * 100, 1) AS pct_vs_wed
FROM m, b7, w4
UNION ALL
SELECT 'paid orders', m.paid_orders::numeric,
       round(b7.paid_orders::numeric, 1), round((m.paid_orders / b7.paid_orders - 1)::numeric * 100, 1),
       round(w4.paid_orders::numeric, 1), round((m.paid_orders / w4.paid_orders - 1)::numeric * 100, 1)
FROM m, b7, w4
UNION ALL
SELECT 'revenue, all orders (dashboard)', round(m.revenue_all::numeric, 0),
       round(b7.revenue_all::numeric, 0), round((m.revenue_all / b7.revenue_all - 1)::numeric * 100, 1),
       round(w4.revenue_all::numeric, 0), round((m.revenue_all / w4.revenue_all - 1)::numeric * 100, 1)
FROM m, b7, w4
UNION ALL
SELECT 'revenue, paid orders only', round(m.revenue_paid::numeric, 0),
       round(b7.revenue_paid::numeric, 0), round((m.revenue_paid / b7.revenue_paid - 1)::numeric * 100, 1),
       round(w4.revenue_paid::numeric, 0), round((m.revenue_paid / w4.revenue_paid - 1)::numeric * 100, 1)
FROM m, b7, w4;
