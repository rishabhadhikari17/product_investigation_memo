SELECT s.started_at::date AS d,
       count(*)                                          AS sessions,
       count(*) FILTER (WHERE sc.channel = 'organic')    AS organic,
       count(*) FILTER (WHERE sc.channel = 'paid')       AS paid,
       count(*) FILTER (WHERE sc.channel = 'referral')   AS referral,
       count(*) FILTER (WHERE sc.channel = 'email')      AS email,
       count(*) FILTER (WHERE sc.channel = 'affiliate')  AS affiliate
FROM ecom.sessions s
LEFT JOIN ecom.session_channels sc ON sc.session_id = s.session_id
WHERE s.started_at >= '2026-05-08' AND s.started_at < '2026-05-19'
GROUP BY 1
ORDER BY 1;


SELECT touched_at::date AS d, channel, count(*) AS touches
FROM ecom.attribution_touches
WHERE touched_at >= '2026-05-08' AND touched_at < '2026-05-19'
GROUP BY 1, 2
ORDER BY 1, 2;

SELECT campaign_id, name, channel, budget, starts_at, ends_at
FROM ecom.marketing_campaigns
WHERE starts_at::date BETWEEN '2026-05-11' AND '2026-05-15'
   OR ends_at::date   BETWEEN '2026-05-11' AND '2026-05-15'
ORDER BY starts_at;
