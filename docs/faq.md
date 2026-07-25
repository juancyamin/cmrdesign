# FAQ

## Why do examples build `y` with two or three simulated pieces?

That is only a simulation device. For example,
`c(rbeta(40, 2, 5), rbeta(40, 4, 4))` creates one outcome vector where the
first 40 entries were generated from one arm-specific distribution and the next
40 from another. The matching assignment vector, such as
`d <- c(rep(1, 40), rep(0, 40))`, tells `cmrdesign` which row belongs to which
arm.

With real pilot data, pass the observed outcome column and the observed
assignment column. You do not need to split the outcome by arm yourself.

## Should I pass pilot data or variance estimates?

Use the applied functions with pilot data whenever possible:
`cmr_two_arm(y, d, ...)`, `cmr_multiarm(y, arm, ...)`, and
`cmr_stratified(y, d, strata, strata_share, ...)`. The package then handles
sample sizes, variance estimates, confidence rectangles, and CMR assignment in
one reproducible path.

Direct rectangle functions are available for expert checks and teaching.

## What if my outcome is not on `[0, 1]`?

If the outcome is bounded on a known scale, pass `normalize = TRUE` in R or
`normalize=True` in Python with known `lower` and `upper` bounds. This is the
guarantee-bearing bounded-outcome route for non-unit scales.

If you omit either bound, `cmrdesign` uses the pilot minimum and/or maximum and
prints a warning. That convenience path can be useful for exploratory work, but
it is data-dependent and does not carry the finite-sample bounded-outcome CMR
guarantee.

If the outcome is not assumed bounded, use the two-arm unbounded extension:
`cmr_unbounded(y, d, psi, ...)` or `cmr_two_arm(..., method = "unbounded",
psi = ...)`. This requires a bounded-kurtosis input `psi >= 1`, is currently
two-arm only, and may return balance with no finite certificate when the pilot
is too small for the requested confidence level.

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

## Which methods work with the extensions?

Bounded, Bernoulli, and MTR variance intervals are available across the
bounded-scale extensions: two-arm, multi-arm, stratified, multiple outcomes,
and proxy outcomes. The exact Bernoulli method requires truly binary 0/1 data
for every arm, cell, or outcome column it is applied to.

The unbounded median-of-means method is currently two-arm only.

## What does `U_CMR` mean?

`U_CMR` is the computed worst-case regret certificate over the variance
confidence rectangle. Smaller values mean the chosen allocation is closer, in
the minimax-regret sense, to the infeasible oracle allocation that would know
the true variances.

`U_CMR` is not a treatment-effect estimate and not a confidence interval for a
treatment effect.

## What does `pi` mean outside the two-arm case?

In two-arm designs, `pi` is the treatment share. In multi-arm designs, `pi` is
a named vector of assignment shares over all arms, including the standardized
control arm `"0"`. In stratified designs, `pi` gives total shares for each
treatment/control by stratum cell; use `pi_matrix`, `sampling_margin`, and
`treatment_margin` for easier applied interpretation.

## How do I turn `pi` into integer main-wave counts?

Use `realize_allocation(fit, n_main = ...)` in R or
`cmr.realize_allocation(fit, n_main=...)` in Python. The helper uses
deterministic largest-remainder rounding, returns integer `counts`, and reports
the realized shares. When the input is a CMR result object, it also recomputes
the regret certificate at the rounded shares when possible.

For stratified designs with fixed field totals by stratum, pass named
`strata_counts`. The helper preserves each stratum total exactly and rounds the
treatment/control split within stratum.

`realize_allocation()` does not generate a randomized assignment vector or
randomization list. It returns auditable counts. Use your usual randomization
workflow to assign units within the requested arms or strata.

## Are R and Python expected to match exactly?

Not bit-for-bit, but yes up to documented numerical tolerances. Closed-form
two-arm, collapsed-rectangle, full-rectangle, planning, and variance-bound
cases use tight cross-language tolerances. General multi-arm and stratified
rectangles involve numerical optimization and use explicit case-level
tolerances in the shared fixtures.
