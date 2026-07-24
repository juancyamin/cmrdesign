# Unbounded-outcome median-of-means variance bounds

Compute one-arm median-of-means variance bounds for raw numeric outcomes
under a bounded-kurtosis input `psi`.

## Usage

``` r
variance_bounds_unbounded_mom(y, alpha = 0.05, psi = NULL, na.rm = TRUE)
```

## Arguments

- y:

  One-arm pilot outcomes.

- alpha:

  Target one-arm error level.

- psi:

  Bounded-kurtosis parameter. Must be at least 1.

- na.rm:

  If `TRUE`, drop missing outcomes.

## Value

A list with lower bound `L`, upper bound `U`, median-of-means variance
estimate `vhat`, method name, sample size `n`, activation flag `active`,
status string, and block-level statistic details. If the pilot is too
small or the relative-error radius is too large, `active = FALSE`,
`L = NA`, and `U = Inf`.

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
[`variance_bounds_maurer_pontil()`](https://juancyamin.github.io/cmrdesign/reference/variance_bounds_maurer_pontil.md)

## Examples

``` r
set.seed(2)
y <- rnorm(200)
variance_bounds_unbounded_mom(y, alpha = 0.05, psi = 3)
#> $L
#> [1] NA
#> 
#> $U
#> [1] Inf
#> 
#> $vhat
#> [1] 1.161367
#> 
#> $method
#> [1] "unbounded_mom"
#> 
#> $n
#> [1] 200
#> 
#> $active
#> [1] FALSE
#> 
#> $status
#> [1] "relative_error_at_least_one"
#> 
#> $statistic
#> $statistic$alpha
#> [1] 0.05
#> 
#> $statistic$psi
#> [1] 3
#> 
#> $statistic$k
#> [1] 30
#> 
#> $statistic$b
#> [1] 3
#> 
#> $statistic$n_pairs
#> [1] 100
#> 
#> $statistic$used_pairs
#> [1] 90
#> 
#> $statistic$discarded_pairs
#> [1] 10
#> 
#> $statistic$rho
#> [1] 1.632993
#> 
#> $statistic$vhat
#> [1] 1.161367
#> 
#> $statistic$block_means
#>    block_1    block_2    block_3    block_4    block_5    block_6    block_7 
#> 1.43402793 0.95408232 2.98066200 1.88321528 1.24011840 0.34327070 0.54298676 
#>    block_8    block_9   block_10   block_11   block_12   block_13   block_14 
#> 1.57584544 2.14069446 0.45189755 2.84820045 0.80593466 0.22389359 2.33558086 
#>   block_15   block_16   block_17   block_18   block_19   block_20   block_21 
#> 2.82928592 0.01741169 0.75497464 1.63354810 0.23256685 0.13511303 1.38372080 
#>   block_22   block_23   block_24   block_25   block_26   block_27   block_28 
#> 0.30683258 1.39951199 2.41393087 0.33460069 1.77208837 0.22078660 3.00324613 
#>   block_29   block_30 
#> 0.85022915 1.08261555 
#> 
#> 
```
