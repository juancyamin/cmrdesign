# Proxy or delayed-outcome CMR assignment

Estimate a proxy-outcome rectangle, widen it using the bridge radius
`zeta`, and return the CMR treatment share for the primary-outcome
design.

## Usage

``` r
cmr_proxy(
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

cmr_delayed_outcome(
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

A list of class `cmr_proxy` and `cmr_two_arm` with treatment share `pi`,
CMR certificate `U_CMR`, widened confidence rectangle, pilot summaries,
`zeta`, bridge diagnostics, endpoint error allocation, and method
metadata.

## See also

Other CMR rules:
[`binary_rectangle_corners()`](https://juancyamin.github.io/cmrdesign/dev/reference/binary_rectangle_corners.md),
[`cmr_multiarm()`](https://juancyamin.github.io/cmrdesign/dev/reference/cmr_multiarm.md),
[`cmr_multiarm_from_rectangle()`](https://juancyamin.github.io/cmrdesign/dev/reference/cmr_multiarm_from_rectangle.md),
[`cmr_multiple_outcomes()`](https://juancyamin.github.io/cmrdesign/dev/reference/cmr_multiple_outcomes.md),
[`cmr_stratified()`](https://juancyamin.github.io/cmrdesign/dev/reference/cmr_stratified.md),
[`cmr_stratified_from_rectangle()`](https://juancyamin.github.io/cmrdesign/dev/reference/cmr_stratified_from_rectangle.md),
[`cmr_two_arm()`](https://juancyamin.github.io/cmrdesign/dev/reference/cmr_two_arm.md),
[`cmr_unbounded()`](https://juancyamin.github.io/cmrdesign/dev/reference/cmr_unbounded.md),
[`cmr_unbounded_from_rectangle()`](https://juancyamin.github.io/cmrdesign/dev/reference/cmr_unbounded_from_rectangle.md),
[`print.cmr_two_arm()`](https://juancyamin.github.io/cmrdesign/dev/reference/print.cmr_two_arm.md)

## Examples

``` r
set.seed(12)
d <- rep(c(1, 0), each = 200)
proxy_y <- c(rbeta(200, 0.5, 0.5), rbeta(200, 8, 8))
cmr_proxy(proxy_y, d, zeta = 0.05)
#> <cmr_proxy>
#>   pi: 0.610985
#>   U_CMR: 0.159176
#>   method: proxy_bounded
#>   n: 400
```
