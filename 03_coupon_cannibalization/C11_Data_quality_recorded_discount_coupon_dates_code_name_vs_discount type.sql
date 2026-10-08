SELECT 'orders.discount recorded as non-zero' AS check_name, count(*) FILTER (WHERE discount <> 0) AS rows_flagged, count(*) AS rows_checked FROM ecom.orders
UNION ALL
SELECT 'coupon used outside its start/end dates', count(*) FILTER (WHERE o.created_at < c.starts_at OR o.created_at > c.ends_at), count(*)
FROM ecom.orders o JOIN ecom.coupons c ON c.coupon_id = o.applied_coupon_id
UNION ALL
SELECT 'intro codes whose type is not percent or fixed (name implies a percent or flat discount)', count(*) FILTER (WHERE discount_type NOT IN ('percent', 'fixed')), count(*)
FROM ecom.coupons WHERE code IN ('WELCOME10', 'WELCOME15', 'FIRSTBUY')
UNION ALL
SELECT 'paid orders with no segment membership at order time',
       count(*) FILTER (WHERE NOT EXISTS (SELECT 1 FROM ecom.segment_memberships sm WHERE sm.customer_id = o.customer_id AND sm.valid_from <= o.created_at AND (sm.valid_to IS NULL OR o.created_at <= sm.valid_to))),
       count(*)
FROM ecom.orders o WHERE lower(o.payment_status) = 'paid';
