# Bounded-outcome variance bounds

One-arm distribution-free variance confidence bounds for outcomes in
`[0, 1]`.

## Usage

``` r
variance_bounds_maurer_pontil(y, beta_l, beta_u, na.rm = TRUE)

variance_bounds_martinez_taboada_ramdas(
  y,
  beta_l,
  beta_u,
  na.rm = TRUE,
  lower_alpha_split = 0.5,
  c1 = 0.5,
  c2 = 0.25^2,
  c3 = 0.25,
  c4 = 0.5,
  c5 = 2,
  cs = FALSE,
  tilde_cs = TRUE
)
```

## Arguments

- y:

  Pilot outcomes for one arm.

- beta_l:

  One-sided endpoint error for the lower variance bound.

- beta_u:

  One-sided endpoint error for the upper variance bound.

- na.rm:

  If `TRUE`, drop missing outcomes.

- lower_alpha_split:

  MTR split of the lower-tail error between variance and mean
  components.

- c1, c2, c3, c4, c5:

  Martinez-Taboada–Ramdas tuning constants.

- cs, tilde_cs:

  Logical flags for the MTR predictable-mixture variants.

## Value

A list with lower bound `L`, upper bound `U`, sample variance `vhat`,
method name, arm sample size `n`, and method-specific `statistic`
details.

## See also

Other rectangle helpers:
[`binary_rectangle_corners()`](https://juancyamin.github.io/cmrdesign/reference/binary_rectangle_corners.md),
[`cmr_multiarm_from_rectangle()`](https://juancyamin.github.io/cmrdesign/reference/cmr_multiarm_from_rectangle.md),
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
[`variance_bounds_unbounded_mom()`](https://juancyamin.github.io/cmrdesign/reference/variance_bounds_unbounded_mom.md)

## Examples

``` r
y <- c(0.10, 0.30, 0.40, 0.20, 0.70, 0.50)
variance_bounds_maurer_pontil(y, beta_l = 0.025, beta_u = 0.025)
#> $L
#> [1] 0
#> 
#> $U
#> [1] 0.25
#> 
#> $vhat
#> [1] 0.04666667
#> 
#> $method
#> [1] "bounded"
#> 
#> $n
#> [1] 6
#> 
#> $statistic
#> $statistic$vhat
#> [1] 0.04666667
#> 
#> $statistic$sdhat
#> [1] 0.2160247
#> 
#> $statistic$beta_l
#> [1] 0.025
#> 
#> $statistic$beta_u
#> [1] 0.025
#> 
#> 
```
