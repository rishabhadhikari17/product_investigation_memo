# Ecommerce Revenue Investigations (`ecom`)

Two investigations on the same ecommerce dataset (PostgreSQL schema `ecom`): the May 13 revenue cliff, and the high-views, low-conversion paradox.

## 1. The May 13 revenue cliff

**Problem statement.** Daily revenue dropped sharply on May 13, 2026, described as roughly 60%. The measured fall in paid orders is 55%. Diagnose whether gateway failures, stockouts, marketing drops or funnel drop-offs caused it.

**Hypotheses tested**

| Hypothesis | Verdict |
| --- | --- |
| Payment gateway failure | Confirmed |
| Funnel drop-off before payment | Ruled out |
| Traffic or marketing drop | Ruled out |
| Stockout | Ruled out |
| Pricing, promotions or coupons | Ruled out |
| Refunds, returns or cancellations | Ruled out |
| Late-posting payments (reporting artifact) | Ruled out |

**Conclusions**

- A UPI payment outage from 09:00 to 16:55 caused the drop. All 171 UPI payments in that window failed, 168 of them with gateway timeouts, on every gateway.
- Paid orders fell 55% against the May 6-12 daily average (-58% against the last four Wednesdays). Paid revenue fell 63% (-66% against Wednesdays).
- The dashboard showed only -23% because it counted failed orders as revenue.
- UPI took 88% of order attempts during the window against about 33% normally, which suggests a default-method or offer change that morning. This needs checking.
- 157 orders failed, worth about 1.01M. Of 130 affected customers, 66 had not paid again within 7 days.
- Recommended: UPI fallback with a shorter timeout, hourly payment-health alerts, paid-only revenue reporting and a win-back for the 66 customers.

## 2. The high-views, low-conversion paradox

**Problem statement.** Find products whose share of views is 3-5x their share of purchases, and diagnose them using SKU-level conversion, pricing and reviews.

**Hypotheses tested**

| Hypothesis | Verdict |
| --- | --- |
| Overpriced against its category | Ruled out |
| Out of stock | Ruled out |
| Low-quality traffic (channel or device) | Ruled out |
| Poor quality (returns, "not as described") | Ruled out |
| Bad reviews or too few reviews | Ruled out |
| Product page problem (content, imagery, variants) | Likely, but not testable in this data |

**Conclusions**

- 154 products (75 in the 3-5x band, 79 above 5x) take about 26% of all views but only about 3% of paid units.
- The leak is at add-to-cart: 7-12% of views for these products against 34% for the rest.
- Price, stock, traffic mix, returns and reviews all look normal. Ratings average 4.0-4.2 stars, and most products have only 0-2 reviews.
- The two worst products are both Makeup, at about 70x. Together they drew 6,978 views and sold 27 units.
- Next step: audit the product pages of the highest-view products and compare them with high-converting pages in the same category.

## How the two relate

The paradox did not cause the May 13 cliff. These products held 26.1% of views on May 13, inside their normal 24.8-27.3% range. They are two separate leaks at opposite ends of the funnel.

| | Paradox | May 13 cliff |
| --- | --- | --- |
| Funnel stage | View to add-to-cart | Checkout to payment |
| Duration | Every day | 09:00-17:00 on one day |
| Cause | Not found in this data | UPI gateway timeouts |

Report view-to-cart and checkout-to-paid as separate metrics so each problem is read for what it is.

## Notes

- **Paid** means `orders.payment_status = 'paid'`. Timestamps are used as stored, with no time-zone conversion.
- The paradox analysis covers 2026-04-19 to 2026-06-14, the span of `session_events`. Conversion figures compare products with each other and are not absolute rates.
- Known data caveats: about 8% of orders use the USD price list, discount columns are all zero, and 32 reviews are attached to failed orders.
- Queries were validated in DuckDB against the CSV exports and written in PostgreSQL syntax.
