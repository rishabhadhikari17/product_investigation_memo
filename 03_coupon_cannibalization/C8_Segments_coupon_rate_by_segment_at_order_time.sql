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
seg AS (
  SELECT po.order_id, po.applied_coupon_id, po.subtotal, cs.segment_name
  FROM po
  JOIN ecom.segment_memberships sm
    ON sm.customer_id = po.customer_id
   AND sm.valid_from <= po.created_at
   AND (sm.valid_to IS NULL OR po.created_at <= sm.valid_to)
  JOIN ecom.customer_segments cs ON cs.segment_id = sm.segment_id
)
SELECT segment_name, count(*) AS order_segment_rows,
       round(100.0 * count(*) FILTER (WHERE applied_coupon_id IS NOT NULL) / count(*), 1) AS coupon_share_pct,
       round(avg(subtotal)) AS avg_order_value
FROM seg GROUP BY segment_name
ORDER BY coupon_share_pct DESC;
