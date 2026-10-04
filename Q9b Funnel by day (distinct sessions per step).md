SELECT occurred_at::date AS d,
       count(DISTINCT session_id) FILTER (WHERE event_type = 'product_view')    AS product_view,
       count(DISTINCT session_id) FILTER (WHERE event_type = 'add_to_cart')     AS add_to_cart,
       count(DISTINCT session_id) FILTER (WHERE event_type = 'begin_checkout')  AS begin_checkout,
       count(DISTINCT session_id) FILTER (WHERE event_type = 'add_payment')     AS add_payment,
       count(DISTINCT session_id) FILTER (WHERE event_type = 'purchase')        AS purchase,
       round(count(DISTINCT session_id) FILTER (WHERE event_type = 'add_to_cart')::numeric
             / nullif(count(DISTINCT session_id) FILTER (WHERE event_type = 'product_view'), 0), 3)   AS view_to_cart,
       round(count(DISTINCT session_id) FILTER (WHERE event_type = 'begin_checkout')::numeric
             / nullif(count(DISTINCT session_id) FILTER (WHERE event_type = 'add_to_cart'), 0), 3)    AS cart_to_checkout,
       round(count(DISTINCT session_id) FILTER (WHERE event_type = 'purchase')::numeric
             / nullif(count(DISTINCT session_id) FILTER (WHERE event_type = 'begin_checkout'), 0), 3) AS checkout_to_purchase
FROM ecom.session_events
WHERE occurred_at >= '2026-05-08' AND occurred_at < '2026-05-19'
GROUP BY 1
ORDER BY 1;
