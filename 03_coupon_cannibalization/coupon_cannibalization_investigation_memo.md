# Coupon Cannibalization: Investigation


## Problem statement

Marketing says coupons bring in net-new customers and extra volume. Finance says coupons erode margin by subsidising purchases that would have happened anyway. Which one does the data support?

## Summary

The data supports Finance's view, with one limit: there is no holdout group, so true incrementality cannot be proven either way.

- **No lift in basket size.** A paid coupon order averages 6,334 and a non-coupon order 6,335. The same customers spend only 1.8% more on coupon orders.
- **No lift in retention or purchase pace.** Customers whose first order used a coupon repeat at the same rate as those whose did not, and coupon orders come as soon after the previous order as non-coupon orders do.
- **Coupons are not targeted.** About 22% of orders use a coupon regardless of week, segment or whether it is the customer's first order.
- **First-order codes go to repeat buyers.** 78% of WELCOME10, WELCOME15 and FIRSTBUY redemptions are on a repeat order.
- **The cost is real.** Modeled discounts are about 6.4M, 2.7% of paid order value, and 79% of that goes to customers who had already bought before.

## How discount cost was measured

`orders.discount` is 0 on every row, so the discount actually given is not recorded. Cost is **modeled** from the coupon table:

| Discount type | Modeled discount |
| --- | --- |
| `percent` | subtotal x discount_value / 100 |
| `fixed` | discount_value (currency units) |
| `free_shipping` | the order's shipping fee |
| `BOGO` | subtotal x discount_value / 100 (value treated as an effective percent) |

There is no product cost (COGS) in the schema, so margin erosion is shown as discount as a share of order subtotal. The BOGO treatment is an assumption.

## Hypotheses and verdicts

| Hypothesis | Verdict |
| --- | --- |
| Coupons lift basket size | Not supported |
| Coupons lift order volume | Not supported |
| Coupon-acquired customers retain better | Not supported |
| Coupons pull purchases forward | Not supported |
| Intro codes are limited to first-time buyers | Not supported (78% are repeat buyers) |
| Coupons are targeted at the right customers | Not supported |
| Some discount types lift baskets more than they cost | Mixed (see below) |

## Angle 1: incremental vs cannibalized demand

Paid orders only (SQL C1-C5).

| | Coupon orders | Non-coupon orders |
| --- | --- | --- |
| Orders | 8,459 (22.4%) | 29,363 (77.6%) |
| Average order value | 6,334 | 6,335 |
| Average modeled discount | 756 | 0 |

- **Volume.** Coupon share of paid orders stays between 21.5% and 23.6% every week (C2), and daily order volume does not rise on high-coupon days (correlation -0.20 across 91 days, C2b). A lift would show up as a positive link.
- **Basket.** Among the 2,801 customers who bought both with and without a coupon, coupon orders are 6,354 against 6,242 without, a lift of 112 (1.8%). The average discount on those orders is far larger than the lift (C5).
- **Retention.** Customers whose first order was on or before April 15, so each has 60 days of follow-up (C3):

| First order | Customers | Repeat within 30 days | Repeat within 60 days | Lifetime orders |
| --- | --- | --- | --- | --- |
| With coupon | 1,062 | 59.6% | 63.1% | 6.58 |
| Without coupon | 4,057 | 61.6% | 64.8% | 6.51 |

- **Timing.** On repeat orders, the median gap since the previous order is 1 day and 85% fall within 14 days, with or without a coupon (C4). Coupons are not pulling purchases forward.

## Angle 2: first-time coupon leak

`ROW_NUMBER() OVER (PARTITION BY customer_id ORDER BY created_at, order_id)` ranks each customer's paid orders (SQL C6).

| Code | Redemptions | On first order | On repeat order | Share from repeat buyers |
| --- | --- | --- | --- | --- |
| WELCOME10 | 169 | 31 | 138 | 81.7% |
| WELCOME15 | 160 | 37 | 123 | 76.9% |
| FIRSTBUY | 161 | 40 | 121 | 75.2% |
| All three | 490 | 108 | 382 | 78.0% |

- **Limit breaches.** Each code allows 1 use per customer, yet 14 customers redeemed an intro code more than once, one of them 3 times (C6b). Across all coupons, 171 of 8,071 customer-coupon pairs (2.1%) exceed their limit (C6d).
- **No targeting.** 21.2% of first orders use a coupon against 22.7% of repeat orders (C6c). Intro codes are being spread across the customer base instead of reserved for new customers.
- **Size of the leak.** The intro-code leak is small in money (about 169K of modeled discount, 0.07% of paid order value) but it shows the controls are not enforced.

## Angle 3: discount types

SQL C7. Paid coupon orders against the 6,335 non-coupon average order value.

| Type | Orders | Basket vs no coupon | Modeled erosion (% of subtotal) | Total modeled discount |
| --- | --- | --- | --- | --- |
| percent | 4,951 | +1.2% | 17.2% | 5.44M |
| BOGO | 874 | +0.3% | 16.7% | 0.93M |
| fixed | 1,353 | -1.7% | 0.2% | 0.02M |
| free_shipping | 1,281 | -3.0% | 0.1% | 0.01M |

- **Percent and BOGO are the problem.** They carry 99% of the modeled discount cost and lift baskets by 1% or less.
- **Fixed and free-shipping cost almost nothing but also lift nothing.** Their modeled cost is tiny because fixed values are 7-22 currency units and shipping fees average about 5, which looks small against a 6,300 basket. Treat their erosion figures with caution.
- **Most expensive codes.** MEGA20, CLEAR40 and LOYAL10 each cost over 300K in modeled discounts (C7b).

## Angle 4: segments and stacking

- **Segments (C8).** The join uses `sm.valid_from <= o.created_at AND (sm.valid_to IS NULL OR o.created_at <= sm.valid_to)`. Coupon share runs 21.4-24.4% in every segment. "Coupon Hunter" is 22.1%, no higher than "Premium" (24.4%) or "Champion" (22.9%), so the segments do not describe coupon behaviour. A customer can hold up to 3 segments at once, and 13,826 of 37,822 paid orders have no segment at order time, so segment results cover only part of the base.
- **Stacking (C9).** 1,514 paid orders (4.0%) carry both a coupon and a promotion. Their average order value is 6,400 against 6,315 for orders with neither, a 1.3% lift for a double discount.

## Cost summary

SQL C10, as a share of paid order value.

| Slice | Orders | Modeled discount | Share of paid value |
| --- | --- | --- | --- |
| All coupon orders | 8,459 | 6.40M | 2.67% |
| On repeat orders | 6,667 | 5.03M | 2.10% |
| On repeat orders within 14 days of the previous order | 5,691 | 4.32M | 1.80% |
| Intro codes on repeat orders | 382 | 0.17M | 0.07% |

## Data quality and limits

- **No holdout.** Every coupon was live all period, so there is no group that never saw a coupon. Incrementality is judged from behaviour, not from an experiment.
- **Discount not recorded.** `orders.discount` is 0 on all 40,000 orders (C11).
- **Code names do not match types.** WELCOME10 is stored as `free_shipping`, WELCOME15 as `BOGO`, FIRSTBUY as `free_shipping`. The stored type is used as given.
- **Out-of-window use.** 45 coupon orders fall outside their coupon's start and end dates.
- **No COGS.** True margin cannot be computed, only discount as a share of revenue.
- Timestamps are used as stored, with no time-zone conversion.

## Recommendations

1. **Enforce first-order-only codes.** Check order sequence and the per-customer limit at checkout, so WELCOME10, WELCOME15 and FIRSTBUY work only on a first paid order.
2. **Run a holdout test.** Withhold coupons from a random 10% of customers for 4-6 weeks. This is the only way to measure true lift.
3. **Stop broad percent and BOGO coupons.** They cost 17% of the order for about a 1% basket lift. Keep them for lapsed or at-risk customers.
4. **Target by behaviour.** Coupon share is flat across segments, so use segments such as "At Risk" or "Churned" to decide who gets an offer.
5. **Limit stacking.** Allow a coupon or a promotion on an order, not both.
6. **Fix the data.** Record the discount on each order, add product cost, and correct the coupon types so margin can be measured properly.

## Query index
All the queries are present in 03_coupon_cannibalization 
- C1: coupon vs non-coupon orders
- C2, C2b: weekly coupon share and daily correlation
- C3: first-order cohort retention
- C4: days between orders
- C5: within-customer basket check
- C6, C6b, C6c, C6d: first-time coupon leak, repeat redemptions, targeting and limit breaches
- C7, C7b: discount types and costliest codes
- C8: segments
- C9: stacking
- C10: cost summary
- C11: data quality
