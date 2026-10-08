WITH po AS (
  SELECT o.order_id, o.customer_id, o.created_at, o.subtotal, o.shipping_fee,
         o.applied_coupon_id, o.applied_promo_id,
         ROW_NUMBER() OVER (PARTITION BY o.customer_id ORDER BY o.created_at, o.order_id) AS order_seq,
         LAG(o.created_at) OVER (PARTITION BY o.customer_id ORDER BY o.created_at, o.order_id) AS prev_order_at,
         c.code, c.discount_type, c.discount_value, c.max_uses_per_customer,
         CASE c.discount_type
              WHEN 'percent'       THEN o.subtotal * c.discount_value / 100.0
              WHEN 'fixed'         THEN c.discount_value
              WHEN 'free_shipping' THEN o.shipping_fee
              WHEN 'BOGO'          THEN o.subtotal * c.discount_value / 100.0
              ELSE 0 END AS assumed_discount
  FROM ecom.orders o
  LEFT JOIN ecom.coupons c ON c.coupon_id = o.applied_coupon_id
  WHERE lower(o.payment_status) = 'paid'
),
f AS (
  SELECT customer_id, created_at AS first_at, (applied_coupon_id IS NOT NULL) AS first_used_coupon, subtotal AS first_subtotal
  FROM po WHERE order_seq = 1 AND created_at <= '2026-04-15'
), s AS (
  SELECT customer_id, created_at AS second_at FROM po WHERE order_seq = 2
), t AS (
  SELECT customer_id, count(*) AS lifetime_orders, sum(subtotal) AS lifetime_subtotal FROM po GROUP BY 1
)
SELECT f.first_used_coupon, count(*) AS customers,
       round(100.0 * avg(CASE WHEN s.second_at <= f.first_at + interval '30 days' THEN 1 ELSE 0 END), 1) AS repeat_within_30d_pct,
       round(100.0 * avg(CASE WHEN s.second_at <= f.first_at + interval '60 days' THEN 1 ELSE 0 END), 1) AS repeat_within_60d_pct,
       round(avg(t.lifetime_orders)::numeric, 2) AS avg_lifetime_orders,
       round(avg(t.lifetime_subtotal)) AS avg_lifetime_subtotal,
       round(avg(f.first_subtotal)) AS avg_first_order_value
FROM f LEFT JOIN s ON s.customer_id = f.customer_id JOIN t ON t.customer_id = f.customer_id
GROUP BY 1 ORDER BY 1;
