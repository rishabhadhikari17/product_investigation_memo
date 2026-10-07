SELECT o.payment_status, o.status AS order_status, count(*) AS orders
FROM ecom.orders o
WHERE o.created_at >= '2026-05-13' AND o.created_at < '2026-05-14'
GROUP BY 1, 2
ORDER BY 3 DESC;
