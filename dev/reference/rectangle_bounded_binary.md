# Bounded two-arm confidence rectangle

Construct a two-arm variance confidence rectangle for bounded outcomes
using Maurer–Pontil or Martinez-Taboada–Ramdas one-arm bounds.

## Usage

``` r
rectangle_bounded_two_arm(
  y,
  d,
  alpha = 0.05,
  method = c("bounded", "maurer_pontil", "mp", "martinez_taboada_ramdas", "mtr"),
  beta = NULL,
  correction = c("bonferroni", "sidak_arms"),
  normalize = FALSE,
  lower = NULL,
  upper = NULL,
  na.rm = TRUE
)

rectangle_bounded_binary(
  y,
  d,
  alpha = 0.05,
  method = c("bounded", "maurer_pontil", "mp", "martinez_taboada_ramdas", "mtr"),
  beta = NULL,
  correction = c("bonferroni", "sidak_arms"),
  normalize = FALSE,
  lower = NULL,
  upper = NULL,
  na.rm = TRUE
)
```

## Arguments

- y:

  Pilot outcomes.

- d:

  Pilot treatment indicator; treatment is `1` and control is `0`.

- alpha:

  Target joint error level.

- method:

  Bounded-outcome method. `"bounded"`, `"maurer_pontil"`, and `"mp"` are
  synonyms; `"martinez_taboada_ramdas"` and `"mtr"` use MTR bounds.

- beta:

  Optional endpoint error allocation. If `NULL`, error is split
  according to `correction`. A single number is used as the one-sided
  error of all four endpoints. A named vector with entries `beta_l1`,
  `beta_u1`, `beta_l0`, `beta_u0` sets each endpoint separately.

- correction:

  Endpoint error correction, either `"bonferroni"` or `"sidak_arms"`.

- normalize:

  If `TRUE`, normalize outcomes to `[0, 1]` before computing variances.
  For guarantee-bearing bounded CMR on a non-unit scale, provide known
  `lower` and `upper` bounds.

- lower, upper:

  Optional lower and upper outcome bounds used when `normalize = TRUE`.
  If either is omitted, the pilot minimum and/or maximum is used with a
  warning; that data-dependent normalization is exploratory and does not
  carry the finite-sample bounded-outcome CMR guarantee.

- na.rm:

  If `TRUE`, drop rows with missing `y` or `d`.

## Value

A `cmr_binary_rectangle` list with `rectangle`, one-arm bound objects
for treatment and control, endpoint error allocation, sample sizes,
pilot variance estimates, normalization details, and method metadata.
For Maurer–Pontil bounds, the top-level `vhat` entries are raw Bessel
sample variances and can exceed `0.25`; the projected unit-interval
values are in `treatment$statistic$projected_vhat` and
`control$statistic$projected_vhat`.

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
d <- rep(c(1, 0), each = 5)
y <- c(0.20, 0.40, 0.30, 0.10, 0.60, 0.50, 0.30, 0.20, 0.40, 0.10)
rectangle_bounded_binary(y, d, method = "bounded")
#> <cmr_binary_rectangle>
#>   rectangle: v_l1=0, v_u1=0.25, v_l0=0, v_u0=0.25
#>   method: bounded
#>   n: 10
#>   joint_error_bound: 0.05
```
