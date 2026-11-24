# Stratified CMR from a variance rectangle

Compute a stratified CMR allocation from a supplied cell-level variance
rectangle.

## Usage

``` r
cmr_stratified_from_rectangle(
  rectangle,
  strata_share,
  control = list(),
  max_vertices = 65536L
)
```

## Arguments

- rectangle:

  Stratified variance rectangle, a list with `lower` and `upper` `2 x S`
  matrices.

- strata_share:

  Named stratum population shares that sum to one.

- control:

  Optional list of solver controls for general rectangles. `gap_tol` is
  the target optimality gap relative to the problem scale (default
  `1e-9`). `barrier = FALSE` skips the barrier Newton method and uses
  the multi-start search directly. `max_starts`, `smooth_taus`, `maxit`,
  and `mirror_iterations` tune that fallback search.

- max_vertices:

  Maximum number of hyperrectangle vertices to enumerate.

## Value

A list of class `cmr_stratified` with assignment shares `pi`,
`pi_matrix`, stratum sampling margins, within-stratum treatment margins,
CMR certificate `U_CMR`, checked rectangle, vertex diagnostics, and
solver diagnostics. A stratum that receives no sample has an `NA`
treatment margin. `diagnostics$optimality_gap` bounds how far `U_CMR`
can be from the minimax value.

## See also

Other CMR rules:
[`binary_rectangle_corners()`](https://juancyamin.github.io/cmrdesign/dev/reference/binary_rectangle_corners.md),
[`cmr_multiarm()`](https://juancyamin.github.io/cmrdesign/dev/reference/cmr_multiarm.md),
[`cmr_multiarm_from_rectangle()`](https://juancyamin.github.io/cmrdesign/dev/reference/cmr_multiarm_from_rectangle.md),
[`cmr_multiple_outcomes()`](https://juancyamin.github.io/cmrdesign/dev/reference/cmr_multiple_outcomes.md),
[`cmr_proxy()`](https://juancyamin.github.io/cmrdesign/dev/reference/cmr_proxy.md),
[`cmr_stratified()`](https://juancyamin.github.io/cmrdesign/dev/reference/cmr_stratified.md),
[`cmr_two_arm()`](https://juancyamin.github.io/cmrdesign/dev/reference/cmr_two_arm.md),
[`cmr_unbounded()`](https://juancyamin.github.io/cmrdesign/dev/reference/cmr_unbounded.md),
[`cmr_unbounded_from_rectangle()`](https://juancyamin.github.io/cmrdesign/dev/reference/cmr_unbounded_from_rectangle.md),
[`print.cmr_two_arm()`](https://juancyamin.github.io/cmrdesign/dev/reference/print.cmr_two_arm.md)

Other rectangle helpers:
[`binary_rectangle_corners()`](https://juancyamin.github.io/cmrdesign/dev/reference/binary_rectangle_corners.md),
[`cmr_multiarm_from_rectangle()`](https://juancyamin.github.io/cmrdesign/dev/reference/cmr_multiarm_from_rectangle.md),
[`cmr_unbounded_from_rectangle()`](https://juancyamin.github.io/cmrdesign/dev/reference/cmr_unbounded_from_rectangle.md),
[`folded_binomial_pmf()`](https://juancyamin.github.io/cmrdesign/dev/reference/folded_binomial_pmf.md),
[`multiarm_variance_objective()`](https://juancyamin.github.io/cmrdesign/dev/reference/multiarm_variance_objective.md),
[`print.cmr_pilot_plan()`](https://juancyamin.github.io/cmrdesign/dev/reference/print.cmr_pilot_plan.md),
[`rectangle_bernoulli_binary()`](https://juancyamin.github.io/cmrdesign/dev/reference/rectangle_bernoulli_binary.md),
[`rectangle_bounded_two_arm()`](https://juancyamin.github.io/cmrdesign/dev/reference/rectangle_bounded_binary.md),
[`rectangle_multiarm()`](https://juancyamin.github.io/cmrdesign/dev/reference/rectangle_multiarm.md),
[`rectangle_multiple_outcomes()`](https://juancyamin.github.io/cmrdesign/dev/reference/rectangle_multiple_outcomes.md),
[`rectangle_proxy()`](https://juancyamin.github.io/cmrdesign/dev/reference/rectangle_proxy.md),
[`rectangle_stratified()`](https://juancyamin.github.io/cmrdesign/dev/reference/rectangle_stratified.md),
[`rectangle_unbounded()`](https://juancyamin.github.io/cmrdesign/dev/reference/rectangle_unbounded.md),
[`stratified_variance_objective()`](https://juancyamin.github.io/cmrdesign/dev/reference/stratified_variance_objective.md),
[`variance_bounds_bernoulli_exact()`](https://juancyamin.github.io/cmrdesign/dev/reference/variance_bounds_bernoulli_exact.md),
[`variance_bounds_maurer_pontil()`](https://juancyamin.github.io/cmrdesign/dev/reference/variance_bounds_maurer_pontil.md),
[`variance_bounds_unbounded_mom()`](https://juancyamin.github.io/cmrdesign/dev/reference/variance_bounds_unbounded_mom.md)

## Examples

``` r
strata_share <- c(A = 0.4, B = 0.6)
rect <- list(
  lower = rbind(treatment = c(A = 0.01, B = 0.04),
                control = c(A = 0.02, B = 0.03)),
  upper = rbind(treatment = c(A = 0.08, B = 0.12),
                control = c(A = 0.09, B = 0.10))
)
cmr_stratified_from_rectangle(rect, strata_share)
#> <cmr_stratified>
#>   pi: 1:A=0.161469, 0:A=0.186198, 1:B=0.344152, 0:B=0.30818
#>   U_CMR: 0.02525
```
