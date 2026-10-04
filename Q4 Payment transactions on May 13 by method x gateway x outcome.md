SELECT pm.method_name,
       pt.gateway,
       count(*) FILTER (WHERE pt.status = 'succeeded') AS succeeded,
       count(*) FILTER (WHERE pt.status = 'failed')    AS failed
FROM ecom.payment_transactions pt
JOIN ecom.payment_intents i  ON i.payment_intent_id = pt.payment_intent_id
JOIN ecom.payment_methods pm ON pm.payment_method_id = i.payment_method_id
WHERE pt.txn_time >= '2026-05-13' AND pt.txn_time < '2026-05-14'
GROUP BY 1, 2
ORDER BY failed DESC, 1, 2;
