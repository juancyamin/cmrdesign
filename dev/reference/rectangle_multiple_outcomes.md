# Multiple-outcome confidence rectangle

Construct an effective two-arm variance rectangle for multiple outcomes.
For `estimand = "index"`, outcomes are first combined using `weights`.
For `estimand = "coprimary"`, one rectangle is built per outcome and
combined conservatively using the outcome weights.

## Usage

``` r
rectangle_multiple_outcomes(
  y,
  d,
  weights = NULL,
  estimand = c("coprimary", "index"),
  alpha = 0.05,
  method = c("auto", "bounded", "bernoulli", "maurer_pontil", "mp", "bernoulli_exact",
    "martinez_taboada_ramdas", "mtr"),
  beta = NULL,
  na.rm = TRUE,
  tol = 1e-11
)
```

## Arguments

- y:

  Pilot outcomes as a numeric matrix, data frame, or vector. Rows are
  units and columns are outcomes.

- d:

  Pilot treatment indicator; treatment is `1` and control is `0`.

- weights:

  Optional nonnegative outcome weights. If `NULL`, equal weights are
  used.

- estimand:

  Either `"coprimary"` or `"index"`.

- alpha:

  Target joint error level.

- method:

  Confidence-set method. `"auto"` chooses exact Bernoulli bounds for 0/1
  outcomes and bounded Maurer–Pontil bounds otherwise.

- beta:

  Optional scalar one-sided endpoint error. With
  `estimand = "coprimary"` it applies to every arm-by-outcome endpoint.
  With `estimand = "index"` it applies to the four endpoints of the
  index outcome, and a named vector as in
  [`cmr_two_arm()`](https://juancyamin.github.io/cmrdesign/dev/reference/cmr_two_arm.md)
  is also accepted.

- na.rm:

  If `TRUE`, drop rows with missing `y` or `d`.

- tol:

  Numerical tolerance for exact Bernoulli bound inversion.

## Value

A list of class `cmr_multiple_outcomes_rectangle`. For
`estimand = "index"`, this wraps the ordinary two-arm rectangle for the
weighted index. For `estimand = "coprimary"`, it contains the effective
two-arm `rectangle`, weights, outcome-specific bounds, pilot summaries,
endpoint error allocation, and method metadata.

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
[`rectangle_proxy()`](https://juancyamin.github.io/cmrdesign/dev/reference/rectangle_proxy.md),
[`rectangle_stratified()`](https://juancyamin.github.io/cmrdesign/dev/reference/rectangle_stratified.md),
[`rectangle_unbounded()`](https://juancyamin.github.io/cmrdesign/dev/reference/rectangle_unbounded.md),
[`stratified_variance_objective()`](https://juancyamin.github.io/cmrdesign/dev/reference/stratified_variance_objective.md),
[`variance_bounds_bernoulli_exact()`](https://juancyamin.github.io/cmrdesign/dev/reference/variance_bounds_bernoulli_exact.md),
[`variance_bounds_maurer_pontil()`](https://juancyamin.github.io/cmrdesign/dev/reference/variance_bounds_maurer_pontil.md),
[`variance_bounds_unbounded_mom()`](https://juancyamin.github.io/cmrdesign/dev/reference/variance_bounds_unbounded_mom.md)

## Examples

``` r
set.seed(9)
d <- rep(c(1, 0), each = 20)
y <- cbind(
  y1 = c(rbeta(20, 2, 6), rbeta(20, 4, 4)),
  y2 = c(rbeta(20, 5, 3), rbeta(20, 3, 5))
)
rectangle_multiple_outcomes(y, d, weights = c(0.6, 0.4))
#> <cmr_multiple_outcomes_rectangle>
#>   rectangle: v_l1=0, v_u1=0.25, v_l0=0, v_u0=0.25
#>   method: bounded
#>   n: 40
#>   joint_error_bound: 0.05
```
