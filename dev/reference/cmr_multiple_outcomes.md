# Multiple-outcome CMR assignment

Estimate an effective two-arm variance rectangle for multiple outcomes
and return the CMR treatment share.

## Usage

``` r
cmr_multiple_outcomes(
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

A list of class `cmr_multiple_outcomes` and `cmr_two_arm` with treatment
share `pi`, CMR certificate `U_CMR`, effective confidence rectangle,
pilot summaries, outcome weights, estimand metadata, endpoint error
allocation, and diagnostics.

## See also

Other CMR rules:
[`binary_rectangle_corners()`](https://juancyamin.github.io/cmrdesign/dev/reference/binary_rectangle_corners.md),
[`cmr_multiarm()`](https://juancyamin.github.io/cmrdesign/dev/reference/cmr_multiarm.md),
[`cmr_multiarm_from_rectangle()`](https://juancyamin.github.io/cmrdesign/dev/reference/cmr_multiarm_from_rectangle.md),
[`cmr_proxy()`](https://juancyamin.github.io/cmrdesign/dev/reference/cmr_proxy.md),
[`cmr_stratified()`](https://juancyamin.github.io/cmrdesign/dev/reference/cmr_stratified.md),
[`cmr_stratified_from_rectangle()`](https://juancyamin.github.io/cmrdesign/dev/reference/cmr_stratified_from_rectangle.md),
[`cmr_two_arm()`](https://juancyamin.github.io/cmrdesign/dev/reference/cmr_two_arm.md),
[`cmr_unbounded()`](https://juancyamin.github.io/cmrdesign/dev/reference/cmr_unbounded.md),
[`cmr_unbounded_from_rectangle()`](https://juancyamin.github.io/cmrdesign/dev/reference/cmr_unbounded_from_rectangle.md),
[`print.cmr_two_arm()`](https://juancyamin.github.io/cmrdesign/dev/reference/print.cmr_two_arm.md)

## Examples

``` r
set.seed(10)
d <- rep(c(1, 0), each = 300)
y <- cbind(
  y1 = c(rbeta(300, 0.5, 0.5), rbeta(300, 8, 8)),
  y2 = c(rbeta(300, 0.6, 0.6), rbeta(300, 6, 6))
)
cmr_multiple_outcomes(y, d, weights = c(0.6, 0.4))
#> <cmr_multiple_outcomes>
#>   pi: 0.677916
#>   U_CMR: 0.118777
#>   method: bounded
#>   n: 600
```
