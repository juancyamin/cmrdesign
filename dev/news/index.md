# Changelog

## cmrdesign (development version)

### Bug fixes

- [`cmr_multiarm()`](https://juancyamin.github.io/cmrdesign/dev/reference/cmr_multiarm.md)
  and
  [`rectangle_multiarm()`](https://juancyamin.github.io/cmrdesign/dev/reference/rectangle_multiarm.md)
  no longer fail when a treatment arm label starts with “v”, such as
  `"variant_a"` or `"v1"`. Arm labels are never renamed. The `v` prefix
  is removed only from variance names of the form `v0`, `v1`, and so on.
- [`cmr_stratified()`](https://juancyamin.github.io/cmrdesign/dev/reference/cmr_stratified.md)
  and
  [`rectangle_stratified()`](https://juancyamin.github.io/cmrdesign/dev/reference/rectangle_stratified.md)
  accept stratum labels that contain a colon, such as `"age:18-30"`.
- `method = "auto"` looks at the raw outcome values in multi-arm and
  stratified designs, as it already did in two-arm designs and as
  documented. A two-valued outcome that is not coded 0/1 is treated as
  bounded in every design.
- [`cmr_plan()`](https://juancyamin.github.io/cmrdesign/dev/reference/pilot_plan.md)
  no longer classifies a pilot as inside the viability band when the
  band is empty.
- A stratum that receives no sample has an `NA` treatment margin, not
  `NaN`.
- [`cmr_multiarm_from_rectangle()`](https://juancyamin.github.io/cmrdesign/dev/reference/cmr_multiarm_from_rectangle.md)
  accepts a matrix rectangle without row names and labels its rows `0`,
  `1`, and so on.

### Changes in behavior

- [`pilot_viability_band()`](https://juancyamin.github.io/cmrdesign/dev/reference/pilot_viability_band.md)
  and
  [`cmr_plan()`](https://juancyamin.github.io/cmrdesign/dev/reference/pilot_plan.md)
  default to `strict_upper = FALSE`. A pilot equal to the design-only
  break-even cap is feasible, which reproduces the band
  `m_act <= m <= cap` and the worked examples of the accompanying paper.
  Set `strict_upper = TRUE` for the 0.1.0 behavior.
- General multi-arm and stratified rectangles are solved by a barrier
  Newton method with a certified optimality gap. `U_CMR` can be slightly
  smaller than in 0.1.0, by up to about `2e-4` in relative terms in our
  checks. `diagnostics$solver` reads `"barrier_newton"`,
  `diagnostics$optimality_gap` bounds the distance to the minimax value,
  and a warning is raised if the solver does not reach its tolerance.
  The multi-start search of 0.1.0 is the fallback and remains available
  with `solver_control = list(barrier = FALSE)`.
- With `method = "auto"`, raw 0/1 outcomes, and `normalize = TRUE` with
  support bounds other than `[0, 1]`, a warning says that normalization
  was skipped. An explicit `method = "bernoulli"` is applied to the
  normalized outcome.
- A constant outcome under data-dependent normalization is mapped to
  `0.5`, as in the Python package. It was mapped to `0`.

### New features

- A scalar `beta` is accepted by
  [`cmr_two_arm()`](https://juancyamin.github.io/cmrdesign/dev/reference/cmr_two_arm.md),
  [`rectangle_two_arm()`](https://juancyamin.github.io/cmrdesign/dev/reference/rectangle_bernoulli_binary.md),
  [`cmr_proxy()`](https://juancyamin.github.io/cmrdesign/dev/reference/cmr_proxy.md),
  and the index mode of
  [`cmr_multiple_outcomes()`](https://juancyamin.github.io/cmrdesign/dev/reference/cmr_multiple_outcomes.md).
- [`cmr_plan()`](https://juancyamin.github.io/cmrdesign/dev/reference/pilot_plan.md)
  returns `two_thirds_status`, which says where the two-thirds-power
  pilot size falls relative to the viability band.
- [`regret()`](https://juancyamin.github.io/cmrdesign/dev/reference/variance_objective.md),
  [`variance_objective()`](https://juancyamin.github.io/cmrdesign/dev/reference/variance_objective.md),
  [`oracle_variance()`](https://juancyamin.github.io/cmrdesign/dev/reference/variance_objective.md),
  [`assign_neyman()`](https://juancyamin.github.io/cmrdesign/dev/reference/variance_objective.md),
  [`coverage_indicator()`](https://juancyamin.github.io/cmrdesign/dev/reference/coverage_indicator.md),
  [`certificate_valid()`](https://juancyamin.github.io/cmrdesign/dev/reference/coverage_indicator.md),
  [`saving_vs_balance()`](https://juancyamin.github.io/cmrdesign/dev/reference/coverage_indicator.md),
  and
  [`share_of_oracle_gain()`](https://juancyamin.github.io/cmrdesign/dev/reference/coverage_indicator.md)
  gain `scale = "nonnegative"` for auditing
  [`cmr_unbounded()`](https://juancyamin.github.io/cmrdesign/dev/reference/cmr_unbounded.md)
  results.
- Compact [`print()`](https://rdrr.io/r/base/print.html) methods for
  pilot plans, viability bands, and confidence rectangles.
- Errors raised while processing one arm, cell, or outcome name it.

### Documentation

- The examples of the main functions use pilots large enough to move the
  allocation, and explain the balanced result that a small pilot
  returns.

## cmrdesign 0.1.0

CRAN release: 2026-08-05

First CRAN release of `cmrdesign`, published on 2026-08-05.

- Added applied Conditional Minimax Regret rules for two-arm, unbounded
  two-arm, shared-control multi-arm, stratified, multiple-outcome, and
  proxy outcome designs.
- Added pilot/main-wave sample-size planning tools from Appendix E of
  the accompanying paper.
- Added R/Python cross-language fixtures, reference validation,
  vignettes, and compact print/summary methods for core CMR results.
- Added
  [`realize_allocation()`](https://juancyamin.github.io/cmrdesign/dev/reference/realize_allocation.md)
  to turn CMR target shares into integer main-wave counts and recompute
  the rounded-design certificate when possible.
- Added allocation cross-language fixtures and vignette/examples
  coverage for integer count realization.
- Hardened
  [`realize_allocation()`](https://juancyamin.github.io/cmrdesign/dev/reference/realize_allocation.md)
  input validation for named length-one targets, fixed stratum counts,
  zero-count realized arms, and certificate recomputation diagnostics.
- Maurer–Pontil bounded-outcome fits now report the raw Bessel sample
  variance in `vhat` and keep projected unit-interval variances in the
  method-specific `statistic$projected_vhat` field.
- Added explicit warnings when `normalize = TRUE` uses pilot min/max
  support bounds, clarifying that this convenience path is exploratory
  rather than finite-sample guarantee-bearing.
