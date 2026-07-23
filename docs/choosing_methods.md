# Choosing A Method

In `cmrdesign`, `method` chooses how the package computes confidence intervals
for outcome variances. The CMR optimization then uses those intervals to build
a variance confidence rectangle and choose the main-wave assignment.

The main applied functions default to `method = "auto"`. That is the right
starting point for many bounded or binary pilot outcomes, but the method should
match the outcome scale and the assumptions you want to report.

## Recommended Defaults

| Situation | Recommended method |
| --- | --- |
| You want the applied default | `method = "auto"` |
| Outcome is bounded but not exactly 0/1 | `method = "bounded"` |
| Outcome is a true binary variable coded 0/1 | `method = "bernoulli"` |
| You specifically want Martinez-Taboada-Ramdas bounds | `method = "mtr"` |
| Two-arm raw finite outcomes without a known bound | `cmr_unbounded(..., psi = ...)` |

## Method Support

| Method family | Computes variance CIs by... | Available for... |
| --- | --- | --- |
| `auto` | Exact Bernoulli for raw 0/1 outcomes, otherwise bounded Maurer-Pontil | Two-arm, multi-arm, stratified, multiple outcomes, proxy |
| `bounded`, `mp`, `maurer_pontil` | Maurer-Pontil bounded-outcome variance bounds | Two-arm, multi-arm, stratified, multiple outcomes, proxy |
| `bernoulli`, `bernoulli_exact` | Exact folded-binomial inversion for Bernoulli variance | Binary two-arm, binary multi-arm/cells, binary co-primary outcomes, binary proxy |
| `mtr`, `martinez_taboada_ramdas` | Martinez-Taboada-Ramdas sequential bounded-outcome bounds | Bounded two-arm, multi-arm, stratified, multiple outcomes, proxy |
| `unbounded`, `unbounded_mom`, `median_of_means`, `mom` | Median-of-means variance bounds under bounded kurtosis | Two-arm only, via `cmr_unbounded()` or `cmr_two_arm(..., method = "unbounded")` |

`cmr_plan()` is a pre-pilot planning helper. It does not use pilot outcomes and
currently supports the bounded and Bernoulli activation screens.

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
is bounded on another known scale. The resulting variance endpoints are clipped
to the feasible `[0, 1/4]` range for unit-bounded outcomes.

## Bernoulli Outcomes

`method = "bernoulli"` and `bernoulli_exact` use exact folded-binomial variance
confidence intervals. This is the clean choice for binary outcomes coded as
0/1. It is also available in extensions when every arm, cell, or outcome column
being bounded is genuinely binary.

For multiple outcomes, use care: an index made from binary outcomes is usually
not itself binary, so the weighted-index route usually uses bounded intervals.
The co-primary route can use Bernoulli intervals outcome by outcome when each
column is 0/1.

## MTR

`method = "mtr"` and `martinez_taboada_ramdas` use the
Martinez-Taboada-Ramdas sequential bounded-outcome bounds. MTR treats the pilot
observations as an ordered sequence. Pass the natural pilot order,
randomization order, or data-collection order; do not sort observations by
outcome before calling the function.

In multi-arm, stratified, multiple-outcome, and proxy workflows, the package
applies the MTR one-arm variance bounds separately to the relevant arm, cell,
or outcome-specific pilot series before solving the corresponding CMR rule.

The parity fixtures verify that the R and Python implementations agree. The
separate scripts in `validation/` add provenance checks against archived MTR
reference values and formula-based extension checks. Keep both layers green
before a journal, CRAN, or PyPI release milestone.

## Unbounded Outcomes

`method = "unbounded"` and aliases `unbounded_mom`, `median_of_means`, and
`mom` use the two-arm unbounded-outcome extension. Unlike bounded methods, this
path does not normalize the outcome to `[0, 1]` and does not cap variance
endpoints at `1/4`.

You must pass `psi`, a scalar or treatment/control pair of kurtosis bounds with
values at least `1`. The calculation preserves the pilot row order within each
arm because consecutive observations are paired. If the pilot is too small or
the relative radius is too large, the function returns the balanced assignment
and marks that no finite CMR certificate is available.

The unbounded method is intentionally two-arm only in the current package. Use
bounded-scale methods for multi-arm, stratified, multiple-outcome, or proxy
extensions.

## Direct Rectangles

Applied users should usually pass `y` and assignment labels. Direct rectangle
functions such as `cmr_two_arm_from_rectangle()`,
`cmr_multiarm_from_rectangle()`, and `cmr_stratified_from_rectangle()` are
intended for auditing, teaching, and replication checks.
