SELECT pt.gateway,
       count(*)                                                  AS upi_txns,
       count(*) FILTER (WHERE pt.status = 'failed')              AS failed,
       count(*) FILTER (WHERE pt.error_code = 'GATEWAY_TIMEOUT') AS gateway_timeouts,
       min(pt.txn_time)                                          AS first_txn,
       max(pt.txn_time)                                          AS last_txn
FROM ecom.payment_transactions pt
JOIN ecom.payment_intents i  ON i.payment_intent_id = pt.payment_intent_id
JOIN ecom.payment_methods pm ON pm.payment_method_id = i.payment_method_id
WHERE pm.method_name = 'upi'
  AND pt.txn_time >= '2026-05-13 09:00' AND pt.txn_time < '2026-05-13 17:00'
GROUP BY 1
ORDER BY 2 DESC;
