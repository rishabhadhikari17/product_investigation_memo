WITH f AS (
  SELECT customer_id, min(created_at) AS first_failed_at
  FROM ecom.orders
  WHERE created_at >= '2026-05-13' AND created_at < '2026-05-14' AND payment_status = 'failed'
  GROUP BY 1
)
SELECT count(*) AS customers_with_failed_order,
       count(*) FILTER (WHERE EXISTS (
            SELECT 1 FROM ecom.orders p
            WHERE p.customer_id = f.customer_id AND p.payment_status = 'paid'
              AND p.created_at > f.first_failed_at AND p.created_at < '2026-05-14'))  AS paid_after_failure_same_day,
       count(*) FILTER (WHERE EXISTS (
            SELECT 1 FROM ecom.orders p
            WHERE p.customer_id = f.customer_id AND p.payment_status = 'paid'
              AND p.created_at > f.first_failed_at AND p.created_at < '2026-05-21'))  AS paid_within_7_days,
       count(*) FILTER (WHERE NOT EXISTS (
            SELECT 1 FROM ecom.orders p
            WHERE p.customer_id = f.customer_id AND p.payment_status = 'paid'
              AND p.created_at > f.first_failed_at AND p.created_at < '2026-05-21'))  AS not_recovered
FROM f;
