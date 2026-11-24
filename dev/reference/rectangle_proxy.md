# Proxy or delayed-outcome confidence rectangle

Construct a primary-outcome variance rectangle by estimating a
proxy-outcome rectangle and widening each arm's standard-deviation
interval by `zeta`.

## Usage

``` r
rectangle_proxy(
  proxy_y,
  d,
  zeta,
  alpha = 0.05,
  method = c("auto", "bounded", "bernoulli", "maurer_pontil", "mp", "bernoulli_exact",
    "martinez_taboada_ramdas", "mtr"),
  beta = NULL,
  correction = c("bonferroni", "sidak_arms"),
  normalize = FALSE,
  lower = NULL,
  upper = NULL,
  na.rm = TRUE,
  tol = 1e-11
)

rectangle_delayed_outcome(
  proxy_y,
  d,
  zeta,
  alpha = 0.05,
  method = c("auto", "bounded", "bernoulli", "maurer_pontil", "mp", "bernoulli_exact",
    "martinez_taboada_ramdas", "mtr"),
  beta = NULL,
  correction = c("bonferroni", "sidak_arms"),
  normalize = FALSE,
  lower = NULL,
  upper = NULL,
  na.rm = TRUE,
  tol = 1e-11
)
```

## Arguments

- proxy_y:

  Pilot proxy or delayed primary outcomes.

- d:

  Pilot treatment indicator; treatment is `1` and control is `0`.

- zeta:

  Nonnegative standard-deviation bridge radius. Provide a scalar shared
  across arms or a treatment/control pair.

- alpha:

  Target joint error level.

- method:

  Confidence-set method. `"auto"` chooses exact Bernoulli bounds for 0/1
  outcomes and bounded Maurer–Pontil bounds otherwise.

- beta:

  Optional endpoint error allocation. If `NULL`, error is split
  according to `correction`. A single number is used as the one-sided
  error of all four endpoints. A named vector with entries `beta_l1`,
  `beta_u1`, `beta_l0`, `beta_u0` sets each endpoint separately.

- correction:

  Endpoint error correction, either `"bonferroni"` or `"sidak_arms"`.

- normalize:

  If `TRUE`, normalize bounded proxy outcomes to `[0, 1]` before
  computing variances. For guarantee-bearing bounded CMR on a non-unit
  scale, provide known `lower` and `upper` bounds. With
  `method = "auto"` and raw 0/1 outcomes, exact Bernoulli bounds are
  used on the raw scale and normalization is skipped.

- lower, upper:

  Optional lower and upper outcome bounds used when `normalize = TRUE`.
  If either is omitted, the pilot minimum and/or maximum is used with a
  warning; that data-dependent normalization is exploratory and does not
  carry the finite-sample bounded-outcome CMR guarantee.

- na.rm:

  If `TRUE`, drop rows with missing `proxy_y` or `d`.

- tol:

  Numerical tolerance for exact Bernoulli bound inversion.

## Value

A list of class `cmr_proxy_rectangle` and `cmr_binary_rectangle` with
the widened primary-outcome rectangle, the underlying proxy confidence
set, `zeta`, bridge metadata, endpoint error allocation, pilot
summaries, and method metadata.

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
[`rectangle_stratified()`](https://juancyamin.github.io/cmrdesign/dev/reference/rectangle_stratified.md),
[`rectangle_unbounded()`](https://juancyamin.github.io/cmrdesign/dev/reference/rectangle_unbounded.md),
[`stratified_variance_objective()`](https://juancyamin.github.io/cmrdesign/dev/reference/stratified_variance_objective.md),
[`variance_bounds_bernoulli_exact()`](https://juancyamin.github.io/cmrdesign/dev/reference/variance_bounds_bernoulli_exact.md),
[`variance_bounds_maurer_pontil()`](https://juancyamin.github.io/cmrdesign/dev/reference/variance_bounds_maurer_pontil.md),
[`variance_bounds_unbounded_mom()`](https://juancyamin.github.io/cmrdesign/dev/reference/variance_bounds_unbounded_mom.md)

## Examples

``` r
set.seed(11)
d <- rep(c(1, 0), each = 30)
proxy_y <- c(rbeta(30, 2, 6), rbeta(30, 4, 4))
rectangle_proxy(proxy_y, d, zeta = 0.05)
#> <cmr_proxy_rectangle>
#>   rectangle: v_l1=0, v_u1=0.25, v_l0=0, v_u0=0.25
#>   method: proxy_bounded
#>   n: 60
#>   joint_error_bound: 0.05
```
