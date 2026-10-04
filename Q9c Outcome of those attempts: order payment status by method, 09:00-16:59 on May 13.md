SELECT pm.method_name,
       count(*) FILTER (WHERE o.payment_status = 'paid')   AS paid,
       count(*) FILTER (WHERE o.payment_status = 'failed') AS failed
FROM ecom.orders o
JOIN ecom.payment_intents i  ON i.order_id = o.order_id
JOIN ecom.payment_methods pm ON pm.payment_method_id = i.payment_method_id
WHERE o.created_at >= '2026-05-13 09:00' AND o.created_at < '2026-05-13 17:00'
GROUP BY 1
ORDER BY failed DESC;
