# FAQ

## Should I pass pilot data or variance estimates?

Use the applied functions with pilot data whenever possible:
`cmr_two_arm(y, d, ...)`, `cmr_multiarm(y, arm, ...)`, and
`cmr_stratified(y, d, strata, strata_share, ...)`. The package then handles
sample sizes, variance estimates, confidence rectangles, and CMR assignment in
one reproducible path.

Direct rectangle functions are available for expert checks and teaching.

## What if my outcome is not on `[0, 1]`?

If the outcome is bounded on a known scale, pass `normalize = TRUE` in R or
`normalize=True` in Python. You may also provide the bounds explicitly with
`lower` and `upper`.

If the outcome is not assumed bounded, use the two-arm unbounded extension:
`cmr_unbounded(y, d, psi, ...)` or `cmr_two_arm(..., method = "unbounded",
psi = ...)`. This requires a kurtosis bound `psi >= 1` and may return balance
with no finite certificate when the pilot is too small for the requested
confidence level.

## What if my binary outcome is coded as 1/2, Yes/No, or 2/5?

Recode it to 0/1 before using `method = "auto"`, or explicitly use
`method = "bernoulli"` after verifying the function accepts the coded values in
your workflow. The `auto` rule chooses Bernoulli exact bounds only for raw 0/1
outcomes.

## Does MTR depend on row order?

Yes. MTR is sequential. Use the pilot's natural, randomization, or collection
order. Do not sort rows by outcome before calling an MTR method.

The unbounded method also depends on row order within each arm because it forms
consecutive outcome pairs for the median-of-means variance estimate.

## What does `U_CMR` mean?

`U_CMR` is the computed worst-case regret certificate over the variance
confidence rectangle. Smaller values mean the chosen allocation is closer, in
the minimax-regret sense, to the infeasible oracle allocation that would know
the true variances.

## Are R and Python expected to match exactly?

Closed-form two-arm, collapsed-rectangle, full-rectangle, planning, and
variance-bound cases use tight cross-language tolerances. General multi-arm and
stratified rectangles involve numerical optimization and use explicit
case-level tolerances in the shared fixtures.
