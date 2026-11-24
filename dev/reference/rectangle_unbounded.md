# Unbounded-outcome confidence rectangle

Construct a two-arm median-of-means variance rectangle for raw numeric
outcomes under bounded-kurtosis inputs.

## Usage

``` r
rectangle_unbounded(y, d, psi = NULL, alpha = 0.05, na.rm = TRUE)
```

## Arguments

- y:

  Pilot outcomes.

- d:

  Pilot treatment indicator; treatment is `1` and control is `0`.

- psi:

  Bounded-kurtosis parameter, either a scalar shared across arms or a
  treatment/control pair.

- alpha:

  Target joint error level. Each arm uses
  [`variance_bounds_unbounded_mom()`](https://juancyamin.github.io/cmrdesign/dev/reference/variance_bounds_unbounded_mom.md)
  with this same `alpha`, whose median-of-means block count gives
  one-arm error at most `alpha / 2`; the union bound over treatment and
  control yields the reported joint error bound `alpha`.

- na.rm:

  If `TRUE`, drop rows with missing `y` or `d`.

## Value

A list of class `cmr_unbounded_rectangle` with `rectangle` when active,
one-arm treatment and control bound objects, pilot summaries, block
diagnostics, `psi`, and `status`. If either arm is inactive, `rectangle`
is `NULL` and `status` explains why.

## See also

Other rectangle helpers:
[`binary_rectangle_corners()`](https://juancyamin.github.io/cmrdesign/dev/reference/binary_rectangle_corners.md),
[`cmr_multiarm_from_rectangle()`](https://juancyamin.github.io/cmrdesign/dev/reference/cmr_multiarm_from_rectangle.md),
[`cmr_stratified_from_rectangle()`](https://juancyamin.github.io/cmrdesign/dev/reference/cmr_stratified_from_rectangle.md),
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
[`stratified_variance_objective()`](https://juancyamin.github.io/cmrdesign/dev/reference/stratified_variance_objective.md),
[`variance_bounds_bernoulli_exact()`](https://juancyamin.github.io/cmrdesign/dev/reference/variance_bounds_bernoulli_exact.md),
[`variance_bounds_maurer_pontil()`](https://juancyamin.github.io/cmrdesign/dev/reference/variance_bounds_maurer_pontil.md),
[`variance_bounds_unbounded_mom()`](https://juancyamin.github.io/cmrdesign/dev/reference/variance_bounds_unbounded_mom.md)

## Examples

``` r
set.seed(3)
d <- rep(c(1, 0), each = 1000)
y <- c(rnorm(1000, sd = 1.3), rnorm(1000, sd = 0.8))
rectangle_unbounded(y, d, psi = 3)
#> <cmr_unbounded_rectangle>
#>   rectangle: v_l1=0.9407, v_u1=5.483, v_l0=0.384, v_u0=2.238
#>   method: unbounded_mom
#>   n: 2000
#>   joint_error_bound: 0.05
```
