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

  Error budget used to size the number of blocks,
  `k = ceiling(8 * log(2 / alpha))`. The resulting one-arm two-sided
  coverage error is at most `alpha / 2`, so that two arms sized with the
  same `alpha` jointly satisfy the union bound at level `alpha`, as
  consumed by
  [`rectangle_unbounded()`](https://juancyamin.github.io/cmrdesign/reference/rectangle_unbounded.md).

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
y <- rnorm(2000, sd = 1.3)
variance_bounds_unbounded_mom(y, alpha = 0.05, psi = 3)
#> $L
#> [1] 1.173903
#> 
#> $U
#> [1] 3.451095
#> 
#> $vhat
#> [1] 1.751893
#> 
#> $method
#> [1] "unbounded_mom"
#> 
#> $n
#> [1] 2000
#> 
#> $active
#> [1] TRUE
#> 
#> $status
#> [1] "active"
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
#> [1] 33
#> 
#> $statistic$n_pairs
#> [1] 1000
#> 
#> $statistic$used_pairs
#> [1] 990
#> 
#> $statistic$discarded_pairs
#> [1] 10
#> 
#> $statistic$rho
#> [1] 0.492366
#> 
#> $statistic$vhat
#> [1] 1.751893
#> 
#> $statistic$block_means
#>  block_1  block_2  block_3  block_4  block_5  block_6  block_7  block_8 
#> 2.518868 1.637589 1.886652 2.212851 1.577163 1.346077 1.776847 1.818456 
#>  block_9 block_10 block_11 block_12 block_13 block_14 block_15 block_16 
#> 1.947647 1.414576 2.153929 1.210690 1.949323 1.307376 1.673664 1.305325 
#> block_17 block_18 block_19 block_20 block_21 block_22 block_23 block_24 
#> 1.353364 2.259950 1.856922 1.961559 2.038161 1.452617 1.246178 1.200749 
#> block_25 block_26 block_27 block_28 block_29 block_30 
#> 1.729985 1.773801 1.813644 1.786194 1.418878 1.366431 
#> 
#> 
```
