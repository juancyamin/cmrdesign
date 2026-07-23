# Choosing A Method

The main applied functions default to `method = "auto"`. That is the right
starting point for most users, but the confidence rectangle should match the
outcome scale and the intended interpretation.

## Recommended Defaults

- Use `method = "auto"` for ordinary applied use.
- Use `method = "bounded"` when the outcome is bounded but not exactly 0/1.
- Use `method = "bernoulli"` when the outcome is a true binary outcome and is
  coded as 0/1.
- Use `method = "mtr"` when you specifically want the
  Martinez-Taboada-Ramdas sequential bounded-outcome bounds.

## `auto`

`auto` dispatches to exact Bernoulli folded-binomial bounds only when the raw
pilot outcomes are exactly 0 and 1. Otherwise it uses the Maurer-Pontil
bounded-outcome bounds.

If `normalize = TRUE` in R or `normalize=True` in Python, the dispatch decision
still uses the raw outcome values before normalization. For example, an outcome
coded as 2/5 is treated as bounded, not Bernoulli. If that variable is truly
binary, recode it to 0/1 or set `method = "bernoulli"` intentionally.

## Bounded Outcomes

`method = "bounded"` and its aliases `maurer_pontil` and `mp` use
Maurer-Pontil variance bounds for outcomes on `[0, 1]`. This is the default
non-binary route. Use `normalize = TRUE`/`normalize=True` when the raw outcome
is bounded on another known scale.

## Bernoulli Outcomes

`method = "bernoulli"` and `bernoulli_exact` use exact folded-binomial variance
confidence intervals. This is the clean choice for binary outcomes coded as
0/1. It is also available for multiple-outcome co-primary workflows when each
outcome column is binary.

## MTR

`method = "mtr"` and `martinez_taboada_ramdas` use the
Martinez-Taboada-Ramdas sequential bounded-outcome bounds. MTR treats the pilot
observations as an ordered sequence. Pass the natural pilot order,
randomization order, or data-collection order; do not sort observations by
outcome before calling the function.

The current MTR fixtures verify R/Python parity for this package's
implementation. They should be supplemented with provenance checks against the
paper code before a journal or public release milestone.

## Direct Rectangles

Applied users should usually pass `y` and assignment labels. Direct rectangle
functions such as `cmr_two_arm_from_rectangle()`,
`cmr_multiarm_from_rectangle()`, and `cmr_stratified_from_rectangle()` are
intended for auditing, teaching, and replication checks.
