# Multi-arm confidence rectangle

Construct arm-specific variance confidence intervals for a
shared-control multi-arm design.

## Usage

``` r
rectangle_multiarm(
  y,
  arm,
  alpha = 0.05,
  method = c("auto", "bounded", "bernoulli", "maurer_pontil", "mp", "bernoulli_exact",
    "martinez_taboada_ramdas", "mtr"),
  beta = NULL,
  control_arm = 0,
  normalize = FALSE,
  lower = NULL,
  upper = NULL,
  na.rm = TRUE,
  tol = 1e-11
)
```

## Arguments

- y:

  Pilot outcomes.

- arm:

  Pilot arm labels. The control arm is identified by `control_arm` and
  internally standardized to `"0"`.

- alpha:

  Target joint error level.

- method:

  Confidence-set method. `"auto"` chooses exact Bernoulli bounds for 0/1
  outcomes and bounded Maurer–Pontil bounds otherwise.

- beta:

  Optional endpoint error allocation. If `NULL`, Bonferroni error is
  split across all lower and upper arm endpoints. A scalar, matrix, or
  named vector allocation may also be supplied.

- control_arm:

  Label identifying the control arm in `arm`.

- normalize:

  If `TRUE`, normalize bounded outcomes to `[0, 1]` before computing
  variances. For guarantee-bearing bounded CMR on a non-unit scale,
  provide known `lower` and `upper` bounds. With `method = "auto"` and
  raw 0/1 outcomes, exact Bernoulli bounds are used on the raw scale and
  normalization is skipped.

- lower, upper:

  Optional lower and upper outcome bounds used when `normalize = TRUE`.
  If either is omitted, the pilot minimum and/or maximum is used with a
  warning; that data-dependent normalization is exploratory and does not
  carry the finite-sample bounded-outcome CMR guarantee.

- na.rm:

  If `TRUE`, drop rows with missing `y` or `arm`.

- tol:

  Numerical tolerance for exact Bernoulli bound inversion.

## Value

A list of class `cmr_multiarm_rectangle` with checked rectangle, arm
labels, one-arm bound results, endpoint error allocation, sample sizes,
pilot variance estimates, normalization details, and method metadata.

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
set.seed(6)
arm <- rep(c(0, 1, 2), each = 12)
y <- c(rbeta(12, 4, 4), rbeta(12, 2, 6), rbeta(12, 5, 3))
rectangle_multiarm(y, arm, method = "bounded")
#> <cmr_multiarm_rectangle>
#>   lower: 0=0, 1=0, 2=0
#>   upper: 0=0.25, 1=0.25, 2=0.25
#>   method: bounded
#>   n: 36
#>   joint_error_bound: 0.05
```
