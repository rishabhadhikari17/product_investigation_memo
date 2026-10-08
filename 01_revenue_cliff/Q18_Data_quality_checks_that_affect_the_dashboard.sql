--orders.status has mixed casing (case-sensitive filters undercount these)
SELECT status, count(*) AS orders
FROM ecom.orders
WHERE lower(status) IN ('shipped', 'delivered')
GROUP BY 1
ORDER BY 1;
 
-- Discount columns are always zero even where a coupon was applied
SELECT count(*) FILTER (WHERE applied_coupon_id IS NOT NULL) AS orders_with_coupon,
       count(*) FILTER (WHERE discount > 0)                  AS orders_with_discount_recorded
FROM ecom.orders;
 
-- Gateway label 'cash' appears on non-COD methods (gateway field is unreliable)
SELECT pm.method_name, pt.gateway, count(*) AS txns
FROM ecom.payment_transactions pt
JOIN ecom.payment_intents i  ON i.payment_intent_id = pt.payment_intent_id
JOIN ecom.payment_methods pm ON pm.payment_method_id = i.payment_method_id
WHERE pt.gateway = 'cash'
GROUP BY 1, 2
ORDER BY 3 DESC;
