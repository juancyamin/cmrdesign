# cmrdesign 0.1.1

## Bug fixes

- `cmr_multiarm()` and `rectangle_multiarm()` no longer fail when a treatment
  arm label starts with "v", such as `"variant_a"` or `"v1"`. Arm labels are
  never renamed. The `v` prefix is removed only from variance names of the
  form `v0`, `v1`, and so on.
- `cmr_stratified()` and `rectangle_stratified()` accept stratum labels that
  contain a colon, such as `"age:18-30"`.
- `method = "auto"` looks at the raw outcome values in multi-arm and
  stratified designs, as it already did in two-arm designs and as documented.
  A two-valued outcome that is not coded 0/1 is treated as bounded in every
  design.
- `cmr_plan()` no longer classifies a pilot as inside the viability band when
  the band is empty.
- A stratum that receives no sample has an `NA` treatment margin, not `NaN`.
- `cmr_multiarm_from_rectangle()` accepts a matrix rectangle without row
  names and labels its rows `0`, `1`, and so on.

## Changes in behavior

- `pilot_viability_band()` and `cmr_plan()` default to `strict_upper = FALSE`.
  A pilot equal to the design-only break-even cap is feasible, which
  reproduces the band `m_act <= m <= cap` and the worked examples of the
  accompanying paper. Set `strict_upper = TRUE` for the 0.1.0 behavior.
- General multi-arm and stratified rectangles are solved by a barrier Newton
  method with a certified optimality gap. `U_CMR` can be slightly smaller than
  in 0.1.0, by up to about `2e-4` in relative terms in our checks.
  `diagnostics$solver` reads `"barrier_newton"`, `diagnostics$optimality_gap`
  bounds the distance to the minimax value, and a warning is raised if the
  solver does not reach its tolerance. The multi-start search of 0.1.0 is the
  fallback and remains available with `solver_control = list(barrier = FALSE)`.
- With `method = "auto"`, raw 0/1 outcomes, and `normalize = TRUE` with support
  bounds other than `[0, 1]`, a warning says that normalization was skipped.
  An explicit `method = "bernoulli"` is applied to the normalized outcome.
- A constant outcome under data-dependent normalization is mapped to `0.5`,
  as in the Python package. It was mapped to `0`.

## New features

- A scalar `beta` is accepted by `cmr_two_arm()`, `rectangle_two_arm()`,
  `cmr_proxy()`, and the index mode of `cmr_multiple_outcomes()`.
- `cmr_plan()` returns `two_thirds_status`, which says where the
  two-thirds-power pilot size falls relative to the viability band.
- `regret()`, `variance_objective()`, `oracle_variance()`, `assign_neyman()`,
  `coverage_indicator()`, `certificate_valid()`, `saving_vs_balance()`, and
  `share_of_oracle_gain()` gain `scale = "nonnegative"` for auditing
  `cmr_unbounded()` results.
- Compact `print()` methods for pilot plans, viability bands, and confidence
  rectangles.
- Errors raised while processing one arm, cell, or outcome name it.

## Documentation

- The examples of the main functions use pilots large enough to move the
  allocation, and explain the balanced result that a small pilot returns.

# cmrdesign 0.1.0

First CRAN release of `cmrdesign`, published on 2026-08-05.

- Added applied Conditional Minimax Regret rules for two-arm, unbounded
  two-arm, shared-control multi-arm, stratified, multiple-outcome, and proxy
  outcome designs.
- Added pilot/main-wave sample-size planning tools from Appendix E of the
  accompanying paper.
- Added R/Python cross-language fixtures, reference validation, vignettes, and
  compact print/summary methods for core CMR results.
- Added `realize_allocation()` to turn CMR target shares into integer
  main-wave counts and recompute the rounded-design certificate when possible.
- Added allocation cross-language fixtures and vignette/examples coverage for
  integer count realization.
- Hardened `realize_allocation()` input validation for named length-one
  targets, fixed stratum counts, zero-count realized arms, and certificate
  recomputation diagnostics.
- Maurer–Pontil bounded-outcome fits now report the raw Bessel sample variance
  in `vhat` and keep projected unit-interval variances in the method-specific
  `statistic$projected_vhat` field.
- Added explicit warnings when `normalize = TRUE` uses pilot min/max support
  bounds, clarifying that this convenience path is exploratory rather than
  finite-sample guarantee-bearing.
