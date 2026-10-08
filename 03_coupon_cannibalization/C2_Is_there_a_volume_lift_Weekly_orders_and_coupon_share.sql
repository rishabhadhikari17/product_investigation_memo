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
SELECT date_trunc('week', created_at)::date AS week_start,
       count(*) AS paid_orders,
       count(*) FILTER (WHERE applied_coupon_id IS NOT NULL) AS coupon_orders,
       round(100.0 * count(*) FILTER (WHERE applied_coupon_id IS NOT NULL) / count(*), 1) AS coupon_share_pct
FROM po
GROUP BY 1 ORDER BY 1;
 
-- C2b. Daily correlation between order volume and coupon share (a lift would be positive)
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
SELECT round(corr(orders, coupon_share)::numeric, 3) AS corr_orders_vs_coupon_share, count(*) AS days
FROM (SELECT created_at::date AS d, count(*) AS orders,
             100.0 * count(*) FILTER (WHERE applied_coupon_id IS NOT NULL) / count(*) AS coupon_share
      FROM po GROUP BY 1) x;
 
