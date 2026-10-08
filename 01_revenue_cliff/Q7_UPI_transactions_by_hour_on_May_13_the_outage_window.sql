SELECT EXTRACT(HOUR FROM pt.txn_time)::int                              AS hr,
       count(*)                                                         AS upi_txns,
       count(*) FILTER (WHERE pt.status = 'failed')                     AS failed,
       count(*) FILTER (WHERE pt.error_code = 'GATEWAY_TIMEOUT')        AS gateway_timeouts,
       count(DISTINCT pt.gateway)                                       AS gateways_seen
FROM ecom.payment_transactions pt
JOIN ecom.payment_intents i  ON i.payment_intent_id = pt.payment_intent_id
JOIN ecom.payment_methods pm ON pm.payment_method_id = i.payment_method_id
WHERE pm.method_name = 'upi'
  AND pt.txn_time >= '2026-05-13' AND pt.txn_time < '2026-05-14'
GROUP BY 1
ORDER BY 1;
