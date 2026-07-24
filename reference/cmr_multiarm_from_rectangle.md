# Multi-arm CMR from a variance rectangle

Compute a shared-control multi-arm CMR allocation from a supplied
variance rectangle.

## Usage

``` r
cmr_multiarm_from_rectangle(rectangle, control = list(), max_vertices = 65536L)
```

## Arguments

- rectangle:

  Multi-arm variance rectangle, either a matrix/data frame with `lower`
  and `upper` columns or a named vector with entries like `v_l0`,
  `v_u0`, `v_l1`, `v_u1`.

- control:

  Optional list of solver controls for the general vertex epigraph
  solver.

- max_vertices:

  Maximum number of hyperrectangle vertices to enumerate.

## Value

A list of class `cmr_multiarm` with named assignment shares `pi`, regret
certificate `U_CMR`, checked rectangle, enumerated vertices, vertex
regrets, binding vertices, and solver diagnostics. For collapsed or full
rectangles, closed-form shortcuts are used.

## See also

Other CMR rules:
[`binary_rectangle_corners()`](https://juancyamin.github.io/cmrdesign/reference/binary_rectangle_corners.md),
[`cmr_multiarm()`](https://juancyamin.github.io/cmrdesign/reference/cmr_multiarm.md),
[`cmr_multiple_outcomes()`](https://juancyamin.github.io/cmrdesign/reference/cmr_multiple_outcomes.md),
[`cmr_proxy()`](https://juancyamin.github.io/cmrdesign/reference/cmr_proxy.md),
[`cmr_stratified()`](https://juancyamin.github.io/cmrdesign/reference/cmr_stratified.md),
[`cmr_stratified_from_rectangle()`](https://juancyamin.github.io/cmrdesign/reference/cmr_stratified_from_rectangle.md),
[`cmr_two_arm()`](https://juancyamin.github.io/cmrdesign/reference/cmr_two_arm.md),
[`cmr_unbounded()`](https://juancyamin.github.io/cmrdesign/reference/cmr_unbounded.md),
[`cmr_unbounded_from_rectangle()`](https://juancyamin.github.io/cmrdesign/reference/cmr_unbounded_from_rectangle.md),
[`print.cmr_two_arm()`](https://juancyamin.github.io/cmrdesign/reference/print.cmr_two_arm.md)

Other rectangle helpers:
[`binary_rectangle_corners()`](https://juancyamin.github.io/cmrdesign/reference/binary_rectangle_corners.md),
[`cmr_stratified_from_rectangle()`](https://juancyamin.github.io/cmrdesign/reference/cmr_stratified_from_rectangle.md),
[`cmr_unbounded_from_rectangle()`](https://juancyamin.github.io/cmrdesign/reference/cmr_unbounded_from_rectangle.md),
[`folded_binomial_pmf()`](https://juancyamin.github.io/cmrdesign/reference/folded_binomial_pmf.md),
[`multiarm_variance_objective()`](https://juancyamin.github.io/cmrdesign/reference/multiarm_variance_objective.md),
[`rectangle_bernoulli_binary()`](https://juancyamin.github.io/cmrdesign/reference/rectangle_bernoulli_binary.md),
[`rectangle_bounded_two_arm()`](https://juancyamin.github.io/cmrdesign/reference/rectangle_bounded_binary.md),
[`rectangle_multiarm()`](https://juancyamin.github.io/cmrdesign/reference/rectangle_multiarm.md),
[`rectangle_multiple_outcomes()`](https://juancyamin.github.io/cmrdesign/reference/rectangle_multiple_outcomes.md),
[`rectangle_proxy()`](https://juancyamin.github.io/cmrdesign/reference/rectangle_proxy.md),
[`rectangle_stratified()`](https://juancyamin.github.io/cmrdesign/reference/rectangle_stratified.md),
[`rectangle_unbounded()`](https://juancyamin.github.io/cmrdesign/reference/rectangle_unbounded.md),
[`stratified_variance_objective()`](https://juancyamin.github.io/cmrdesign/reference/stratified_variance_objective.md),
[`variance_bounds_bernoulli_exact()`](https://juancyamin.github.io/cmrdesign/reference/variance_bounds_bernoulli_exact.md),
[`variance_bounds_maurer_pontil()`](https://juancyamin.github.io/cmrdesign/reference/variance_bounds_maurer_pontil.md),
[`variance_bounds_unbounded_mom()`](https://juancyamin.github.io/cmrdesign/reference/variance_bounds_unbounded_mom.md)

## Examples

``` r
rect <- c(
  v_l0 = 0.02, v_u0 = 0.08,
  v_l1 = 0.04, v_u1 = 0.12,
  v_l2 = 0.01, v_u2 = 0.07
)
cmr_multiarm_from_rectangle(rect)
#> <cmr_multiarm>
#>   pi: 0=0.398867, 1=0.353341, 2=0.247792
#>   U_CMR: 0.0646975
```
