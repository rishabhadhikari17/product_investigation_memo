# May 13 Revenue Cliff: Investigation Memo

## Summary

Failed UPI payments between 09:00 and 17:00 on May 13 caused the drop: paid orders fell 55% and paid revenue 63% against the May 6-12 daily average.

Every UPI payment attempt in that window failed (171 of 171, 168 of them with a gateway timeout), on every gateway in the data. UPI also carried 88% of order attempts in those hours, against about 33% on a normal day.

Traffic, the funnel up to the payment step, marketing and stock were all normal, and payments recovered on their own at 17:00. About 1.0M of order value failed, roughly 0.9M of it above the usual level.

## How big the drop was

Paid orders fell 55% and paid revenue 63% against the May 6-12 daily average. Against the last four Wednesdays the falls are 58% and 66%. The dashboard (q1) showed only -23% because its revenue column adds up every order, so the 157 failed orders still counted as revenue.

| Metric | May 13 | May 6-12 daily avg | Change | Last 4 Wednesdays avg | Change |
| --- | --- | --- | --- | --- | --- |
| Orders created | 298 | 328 | -9% | 351 | -15% |
| Paid orders | 141 | 313 | -55% | 333 | -58% |
| Revenue, all orders (dashboard) | 1.88M | 2.46M | -23% | 2.70M | -30% |
| Revenue, paid orders only | 0.88M | 2.36M | -63% | 2.56M | -66% |

Orders were still created at close to the normal rate, but only 47% were paid, against 93-97% on every other day from May 1 to May 20.

## Hypotheses tested

One of seven hypotheses explains the drop; the other six are ruled out by the data.

| Hypothesis | Verdict | Evidence | SQL |
| --- | --- | --- | --- |
| Payment gateway failure | Confirmed | 157 orders failed on May 13 against about 15 on a normal day. All UPI payments from 09:00 to 16:55 failed. | Q3-Q8 |
| Funnel drop-off before payment | Ruled out | Sessions reaching add-payment: 252, in line with other days. Only checkout to purchase fell, to 46% from 85-90%. | Q9 |
| Traffic or marketing drop | Ruled out | 934 sessions against 925-1,184 on May 8-18, with every channel inside its normal range. No campaign ended the day before. | Q10 |
| Stockout | Ruled out | One variant sold out on May 11 but has only 10 order lines (about 32K) in total. All 14 categories fell, none to zero. | Q11 |
| Pricing, promotions, coupons | Ruled out | All price rows were loaded once on March 16 with no end date. The same 20 promotions and 50 coupons were live all period, with coupon use at 23% of orders. | Q12 |
| Refunds, returns, cancellations | Ruled out | 4 refunds worth 9.9K and 18 return requests on May 13, both inside the daily range. | Q13 |
| Late-posting payments (reporting artefact) | Ruled out | All 157 failed-payment orders ended as cancelled, and only 14 of 130 affected customers paid again later that day. | Q14, Q17 |

## Root cause: UPI payments timed out from 09:00 to 17:00

UPI failed on every attempt between 09:00 and 16:55, and the failures were gateway timeouts, not bank declines. 168 of the 171 UPI payments in that window returned GATEWAY_TIMEOUT ("Gateway did not respond within 30s"); the other 3 were network or bank errors. That error code is essentially absent on a normal day.

**Hourly UPI payments on May 13**

| Hour | Succeeded | Failed |
| --- | --- | --- |
| 00:00-08:59 (normal) | 34 | 1 |
| 09:00 | 0 | 15 |
| 10:00 | 0 | 21 |
| 11:00 | 0 | 15 |
| 12:00 | 0 | 11 |
| 13:00 | 0 | 23 |
| 14:00 | 0 | 27 |
| 15:00 | 0 | 29 |
| 16:00 | 0 | 30 |
| 17:00-23:59 (recovered) | 21 | 2 |

- **Every gateway failed.** Razorpay 91 of 91, PayU 29 of 29, Stripe 24 of 24 and the gateway labelled "cash" 27 of 27. Four gateways failing together points to a shared dependency, either the UPI rail or our own integration layer.
- **Other methods were fine.** Only 10 payments failed across all non-UPI methods all day, and just 19 non-UPI orders were created in the window.
- **Shoppers were funnelled into UPI.** UPI took 88% of order attempts in the window (137 of 156) against about 33% on a normal day. Card attempts fell from about 51 to 11, while total attempts stayed flat. Something made UPI the default or the favoured option that morning.
- **Recovery was immediate.** All 25 checkouts in the 17:00 hour completed, so the fault cleared rather than decayed.

The drop is therefore a payment-completion failure, not a demand problem: shoppers kept arriving and trying to buy, but nearly all of them paid through the one method that was down.

## Business impact

- **157 orders failed payment on May 13, worth about 1.01M.** Against a normal day, roughly 142 of these are excess failures, worth about 0.91M.
- **130 customers had at least one failed order.** 14 paid later the same day, 64 paid within 7 days, and 66 had not paid again by May 21.
- **The 66 unrecovered customers are the clearest win-back list.** They tried to buy and were blocked by our checkout, not by their own choice.
- **Failed orders were later cancelled, not paid late.** Late-posting payments do not explain any of the gap.

## Open questions and data caveats

**Questions the data cannot answer**

- What sits behind the UPI timeouts? All four gateways failed together, so check the UPI rail status and our payment-routing layer for May 13, 09:00 to 17:00.
- Did a default-method or UPI-offer change go live that morning? UPI's share of attempts jumped from about 33% to 88% with no change in total attempts.
- Does "55%" mean a decline in paid orders? That is how it was read here: paid orders -55% against the May 6-12 average and -58% against the last four Wednesdays.

**Data caveats**

- About 8% of orders use the USD price list with totals similar to INR orders, so revenue sums may mix currencies.
- Order status is mixed-case in places, and was normalised in the queries.
- The gateway label "cash" appears on every payment method, so it is probably a default label rather than a real gateway.
- Discount columns are zero everywhere, so discount depth cannot be assessed. Coupon and promo usage were used instead.
- Some marketing_campaigns names do not match their channels, and some inventory_movements are future-dated.
- Timestamps are used as stored, with no time-zone conversion.

## Recommendations

1. **Add a UPI fallback.** Cut the gateway timeout well below 30 seconds and route UPI to another rail or prompt the shopper to switch method when it fails.
2. **Alert on hourly payment health.** Page on checkout-to-paid rate and per-method failure rate by hour. This outage ran eight hours and was visible in the first one.
3. **Report revenue as paid only.** The dashboard counts failed orders, which is why it showed -23% instead of -55%.
4. **Win back the 66 unrecovered customers** with a short apology and a direct re-checkout link.
5. **Check the May 13 morning release.** Confirm whether a UPI default or offer change shipped, since it concentrated shoppers into the failing method.

## Appendix: SQL index
All queries are in 01_revenue_cliff
- Q1-Q2: daily scorecard and sizing against both baselines
- Q3-Q8b: payment failures by hour, method, gateway and error code, and the UPI window
- Q9-Q10c: funnel, traffic, attribution touches and campaigns
- Q11-Q11c: stock and category revenue
- Q12-Q12c: pricing, promotions and coupons
- Q13-Q14: refunds, returns and failed-to-cancelled reconciliation
- Q15: currency and price lists
- Q16-Q17: impact and customer recovery
- Q18-Q18c: data quality checks
