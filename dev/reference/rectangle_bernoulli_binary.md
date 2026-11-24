# Two-arm confidence rectangles

Construct a two-arm variance confidence rectangle from pilot data. These
are expert helpers used by
[`cmr_two_arm()`](https://juancyamin.github.io/cmrdesign/dev/reference/cmr_two_arm.md)
and related extension functions.

## Usage

``` r
rectangle_bernoulli_binary(
  y,
  d,
  alpha = 0.05,
  beta = NULL,
  correction = c("bonferroni", "sidak_arms"),
  na.rm = TRUE,
  tol = 1e-11
)

rectangle_binary(
  y,
  d,
  alpha = 0.05,
  method = c("auto", "bounded", "bernoulli", "maurer_pontil", "mp", "bernoulli_exact",
    "martinez_taboada_ramdas", "mtr", "unbounded", "unbounded_mom", "median_of_means",
    "mom"),
  beta = NULL,
  correction = c("bonferroni", "sidak_arms"),
  normalize = FALSE,
  lower = NULL,
  upper = NULL,
  psi = NULL,
  na.rm = TRUE,
  tol = 1e-11
)

rectangle_two_arm(
  y,
  d,
  alpha = 0.05,
  method = c("auto", "bounded", "bernoulli", "maurer_pontil", "mp", "bernoulli_exact",
    "martinez_taboada_ramdas", "mtr", "unbounded", "unbounded_mom", "median_of_means",
    "mom"),
  beta = NULL,
  correction = c("bonferroni", "sidak_arms"),
  normalize = FALSE,
  lower = NULL,
  upper = NULL,
  psi = NULL,
  na.rm = TRUE,
  tol = 1e-11
)

rectangle_bernoulli_two_arm(
  y,
  d,
  alpha = 0.05,
  beta = NULL,
  correction = c("bonferroni", "sidak_arms"),
  na.rm = TRUE,
  tol = 1e-11
)
```

## Arguments

- y:

  Pilot outcomes.

- d:

  Pilot treatment indicator; treatment is `1` and control is `0`.

- alpha:

  Target joint error level.

- beta:

  Optional endpoint error allocation. If `NULL`, error is split
  according to `correction`. A single number is used as the one-sided
  error of all four endpoints. A named vector with entries `beta_l1`,
  `beta_u1`, `beta_l0`, `beta_u0` sets each endpoint separately.

- correction:

  Endpoint error correction, either `"bonferroni"` or `"sidak_arms"` for
  two-arm workflows.

- na.rm:

  If `TRUE`, drop rows with missing `y` or `d`.

- tol:

  Numerical tolerance for exact Bernoulli bound inversion.

- method:

  Confidence-set method. `"auto"` chooses exact Bernoulli bounds for 0/1
  outcomes and bounded Maurer–Pontil bounds otherwise.

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

- psi:

  Bounded-kurtosis parameter used only when `method` is an
  unbounded-outcome method.

## Value

A rectangle object. Bounded and Bernoulli methods return a
`cmr_binary_rectangle`; unbounded methods return a
`cmr_unbounded_rectangle`. The object contains the numeric `rectangle`,
one-arm bound details, endpoint error allocation, pilot sample sizes and
variance estimates, and method metadata.

## See also

Other rectangle helpers:
[`binary_rectangle_corners()`](https://juancyamin.github.io/cmrdesign/dev/reference/binary_rectangle_corners.md),
[`cmr_multiarm_from_rectangle()`](https://juancyamin.github.io/cmrdesign/dev/reference/cmr_multiarm_from_rectangle.md),
[`cmr_stratified_from_rectangle()`](https://juancyamin.github.io/cmrdesign/dev/reference/cmr_stratified_from_rectangle.md),
[`cmr_unbounded_from_rectangle()`](https://juancyamin.github.io/cmrdesign/dev/reference/cmr_unbounded_from_rectangle.md),
[`folded_binomial_pmf()`](https://juancyamin.github.io/cmrdesign/dev/reference/folded_binomial_pmf.md),
[`multiarm_variance_objective()`](https://juancyamin.github.io/cmrdesign/dev/reference/multiarm_variance_objective.md),
[`print.cmr_pilot_plan()`](https://juancyamin.github.io/cmrdesign/dev/reference/print.cmr_pilot_plan.md),
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
d <- rep(c(1, 0), each = 6)
y <- c(1, 0, 1, 1, 0, 1, 0, 0, 1, 0, 0, 1)
rectangle_two_arm(y, d, method = "bernoulli")
#> <cmr_binary_rectangle>
#>   rectangle: v_l1=0.02915, v_u1=0.25, v_l0=0.02915, v_u0=0.25
#>   method: bernoulli
#>   n: 12
#>   joint_error_bound: 0.05
rectangle_binary(y, d, method = "auto")
#> <cmr_binary_rectangle>
#>   rectangle: v_l1=0.02915, v_u1=0.25, v_l0=0.02915, v_u0=0.25
#>   method: bernoulli
#>   n: 12
#>   joint_error_bound: 0.05
```
