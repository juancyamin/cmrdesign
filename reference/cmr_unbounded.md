# Unbounded-outcome CMR assignment

Estimate a median-of-means variance rectangle from raw pilot outcomes
and return the unbounded-outcome CMR assignment.

## Usage

``` r
cmr_unbounded(y, d, psi = NULL, alpha = 0.05, na.rm = TRUE)
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
  [`variance_bounds_unbounded_mom()`](https://juancyamin.github.io/cmrdesign/reference/variance_bounds_unbounded_mom.md)
  with this same `alpha`, whose median-of-means block count gives
  one-arm error at most `alpha / 2`; the union bound over treatment and
  control yields the reported joint error bound `alpha`.

- na.rm:

  If `TRUE`, drop rows with missing `y` or `d`.

## Value

A list of class `cmr_unbounded` and `cmr_two_arm`. If both one-arm
bounds are active, the object contains `pi`, finite `U_CMR`, rectangle,
pilot summaries, and diagnostics. If the pilot is inactive, the function
returns balance (`pi = 0.5`) with `U_CMR = Inf` and diagnostics
explaining the fallback.

## See also

Other CMR rules:
[`binary_rectangle_corners()`](https://juancyamin.github.io/cmrdesign/reference/binary_rectangle_corners.md),
[`cmr_multiarm()`](https://juancyamin.github.io/cmrdesign/reference/cmr_multiarm.md),
[`cmr_multiarm_from_rectangle()`](https://juancyamin.github.io/cmrdesign/reference/cmr_multiarm_from_rectangle.md),
[`cmr_multiple_outcomes()`](https://juancyamin.github.io/cmrdesign/reference/cmr_multiple_outcomes.md),
[`cmr_proxy()`](https://juancyamin.github.io/cmrdesign/reference/cmr_proxy.md),
[`cmr_stratified()`](https://juancyamin.github.io/cmrdesign/reference/cmr_stratified.md),
[`cmr_stratified_from_rectangle()`](https://juancyamin.github.io/cmrdesign/reference/cmr_stratified_from_rectangle.md),
[`cmr_two_arm()`](https://juancyamin.github.io/cmrdesign/reference/cmr_two_arm.md),
[`cmr_unbounded_from_rectangle()`](https://juancyamin.github.io/cmrdesign/reference/cmr_unbounded_from_rectangle.md),
[`print.cmr_two_arm()`](https://juancyamin.github.io/cmrdesign/reference/print.cmr_two_arm.md)

## Examples

``` r
set.seed(4)
d <- rep(c(1, 0), each = 220)
y <- c(rnorm(220, sd = 1.3), rnorm(220, sd = 0.8))
cmr_unbounded(y, d, psi = 3)
#> <cmr_unbounded>
#>   pi: 0.5
#>   U_CMR: Inf
#>   method: unbounded_mom
#>   n: 440
#>   status: treatment:relative_error_at_least_one;control:relative_error_at_least_one
```
