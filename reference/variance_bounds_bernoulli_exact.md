# Exact Bernoulli variance bounds

Exact one-arm variance confidence bounds for Bernoulli outcomes using
the folded-binomial distribution of the sample variance.

## Usage

``` r
variance_bounds_bernoulli_exact(y, beta_l, beta_u, na.rm = TRUE, tol = 1e-11)
```

## Arguments

- y:

  One-arm Bernoulli outcomes coded as `0` and `1`.

- beta_l:

  One-sided endpoint error for the lower variance bound.

- beta_u:

  One-sided endpoint error for the upper variance bound.

- na.rm:

  If `TRUE`, drop missing outcomes.

- tol:

  Numerical tolerance for endpoint inversion.

## Value

A list with lower bound `L`, upper bound `U`, folded-binomial variance
estimate `vhat`, method name, sample size `n`, and folded-count details
in `statistic`.

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
[`variance_bounds_maurer_pontil()`](https://juancyamin.github.io/cmrdesign/reference/variance_bounds_maurer_pontil.md),
[`variance_bounds_unbounded_mom()`](https://juancyamin.github.io/cmrdesign/reference/variance_bounds_unbounded_mom.md)

## Examples

``` r
y <- c(1, 0, 1, 1, 0, 0, 1, 0)
variance_bounds_bernoulli_exact(y, beta_l = 0.025, beta_u = 0.025)
#> $L
#> [1] 0.1374708
#> 
#> $U
#> [1] 0.25
#> 
#> $vhat
#> [1] 0.25
#> 
#> $method
#> [1] "bernoulli"
#> 
#> $n
#> [1] 8
#> 
#> $statistic
#> $statistic$j
#> [1] 4
#> 
#> $statistic$x
#> [1] 4
#> 
#> $statistic$m
#> [1] 8
#> 
#> $statistic$raw_sample_variance
#> [1] 0.2857143
#> 
#> $statistic$beta_l
#> [1] 0.025
#> 
#> $statistic$beta_u
#> [1] 0.025
#> 
#> 
```
