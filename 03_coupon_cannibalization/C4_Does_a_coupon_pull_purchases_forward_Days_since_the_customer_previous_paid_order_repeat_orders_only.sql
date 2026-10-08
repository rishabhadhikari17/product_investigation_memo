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
)
SELECT (applied_coupon_id IS NOT NULL) AS used_coupon, count(*) AS repeat_orders,
       round(avg(created_at::date - prev_order_at::date)::numeric, 1) AS avg_gap_days,
       percentile_cont(0.5) WITHIN GROUP (ORDER BY (created_at::date - prev_order_at::date)) AS median_gap_days,
       round(100.0 * avg(CASE WHEN created_at::date - prev_order_at::date <= 14 THEN 1 ELSE 0 END), 1) AS pct_within_14_days
FROM po WHERE order_seq > 1
GROUP BY 1 ORDER BY 1;
