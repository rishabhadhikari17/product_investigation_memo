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
SELECT 'all coupon orders' AS slice, count(*) AS orders, round(sum(assumed_discount)) AS assumed_discount,
       round(100.0 * sum(assumed_discount) / (SELECT sum(subtotal) FROM po), 2) AS pct_of_paid_subtotal
FROM po WHERE applied_coupon_id IS NOT NULL
UNION ALL
SELECT 'on repeat orders (customer already had a paid order)', count(*), round(sum(assumed_discount)),
       round(100.0 * sum(assumed_discount) / (SELECT sum(subtotal) FROM po), 2)
FROM po WHERE applied_coupon_id IS NOT NULL AND order_seq > 1
UNION ALL
SELECT 'intro codes on repeat orders', count(*), round(sum(assumed_discount)),
       round(100.0 * sum(assumed_discount) / (SELECT sum(subtotal) FROM po), 2)
FROM po WHERE code IN ('WELCOME10', 'WELCOME15', 'FIRSTBUY') AND order_seq > 1
UNION ALL
SELECT 'on repeat orders within 14 days of the previous one', count(*), round(sum(assumed_discount)),
       round(100.0 * sum(assumed_discount) / (SELECT sum(subtotal) FROM po), 2)
FROM po WHERE applied_coupon_id IS NOT NULL AND order_seq > 1 AND created_at::date - prev_order_at::date <= 14;
