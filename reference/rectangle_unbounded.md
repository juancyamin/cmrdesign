# Unbounded-outcome confidence rectangle

Construct a two-arm median-of-means variance rectangle for raw numeric
outcomes under bounded-kurtosis inputs.

## Usage

``` r
rectangle_unbounded(y, d, psi = NULL, alpha = 0.05, na.rm = TRUE)
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

  Target joint error level.

- na.rm:

  If `TRUE`, drop rows with missing `y` or `d`.

## Value

A list of class `cmr_unbounded_rectangle` with `rectangle` when active,
one-arm treatment and control bound objects, pilot summaries, block
diagnostics, `psi`, and `status`. If either arm is inactive, `rectangle`
is `NULL` and `status` explains why.

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
[`stratified_variance_objective()`](https://juancyamin.github.io/cmrdesign/reference/stratified_variance_objective.md),
[`variance_bounds_bernoulli_exact()`](https://juancyamin.github.io/cmrdesign/reference/variance_bounds_bernoulli_exact.md),
[`variance_bounds_maurer_pontil()`](https://juancyamin.github.io/cmrdesign/reference/variance_bounds_maurer_pontil.md),
[`variance_bounds_unbounded_mom()`](https://juancyamin.github.io/cmrdesign/reference/variance_bounds_unbounded_mom.md)

## Examples

``` r
set.seed(3)
d <- rep(c(1, 0), each = 220)
y <- c(rnorm(220, sd = 1.3), rnorm(220, sd = 0.8))
rectangle_unbounded(y, d, psi = 3)
#> $rectangle
#> NULL
#> 
#> $treatment
#> $treatment$L
#> [1] NA
#> 
#> $treatment$U
#> [1] Inf
#> 
#> $treatment$vhat
#> [1] 1.283259
#> 
#> $treatment$method
#> [1] "unbounded_mom"
#> 
#> $treatment$n
#> [1] 220
#> 
#> $treatment$active
#> [1] FALSE
#> 
#> $treatment$status
#> [1] "relative_error_at_least_one"
#> 
#> $treatment$statistic
#> $treatment$statistic$alpha
#> [1] 0.05
#> 
#> $treatment$statistic$psi
#> [1] 3
#> 
#> $treatment$statistic$k
#> [1] 30
#> 
#> $treatment$statistic$b
#> [1] 3
#> 
#> $treatment$statistic$n_pairs
#> [1] 110
#> 
#> $treatment$statistic$used_pairs
#> [1] 90
#> 
#> $treatment$statistic$discarded_pairs
#> [1] 20
#> 
#> $treatment$statistic$rho
#> [1] 1.632993
#> 
#> $treatment$statistic$vhat
#> [1] 1.283259
#> 
#> $treatment$statistic$block_means
#>    block_1    block_2    block_3    block_4    block_5    block_6    block_7 
#> 0.69465903 2.08264668 0.35016676 0.93558259 0.34405964 0.31577007 1.67308402 
#>    block_8    block_9   block_10   block_11   block_12   block_13   block_14 
#> 4.14658942 1.85178056 2.69414590 0.80770470 1.21465098 0.43204658 1.50325144 
#>   block_15   block_16   block_17   block_18   block_19   block_20   block_21 
#> 1.02024610 0.85276184 0.94441681 1.35186633 1.55457122 0.04775352 1.84225004 
#>   block_22   block_23   block_24   block_25   block_26   block_27   block_28 
#> 2.73322806 6.07539774 0.43827220 0.82381398 4.58973456 5.02768931 2.02239195 
#>   block_29   block_30 
#> 0.38007422 5.07635643 
#> 
#> 
#> 
#> $control
#> $control$L
#> [1] NA
#> 
#> $control$U
#> [1] Inf
#> 
#> $control$vhat
#> [1] 0.5428872
#> 
#> $control$method
#> [1] "unbounded_mom"
#> 
#> $control$n
#> [1] 220
#> 
#> $control$active
#> [1] FALSE
#> 
#> $control$status
#> [1] "relative_error_at_least_one"
#> 
#> $control$statistic
#> $control$statistic$alpha
#> [1] 0.05
#> 
#> $control$statistic$psi
#> [1] 3
#> 
#> $control$statistic$k
#> [1] 30
#> 
#> $control$statistic$b
#> [1] 3
#> 
#> $control$statistic$n_pairs
#> [1] 110
#> 
#> $control$statistic$used_pairs
#> [1] 90
#> 
#> $control$statistic$discarded_pairs
#> [1] 20
#> 
#> $control$statistic$rho
#> [1] 1.632993
#> 
#> $control$statistic$vhat
#> [1] 0.5428872
#> 
#> $control$statistic$block_means
#>    block_1    block_2    block_3    block_4    block_5    block_6    block_7 
#> 1.47517737 0.10677586 0.48884775 0.42213846 0.53052481 0.66583628 0.77300332 
#>    block_8    block_9   block_10   block_11   block_12   block_13   block_14 
#> 0.21892974 0.44445700 0.52001800 1.63656463 0.93419958 0.55524955 0.58791024 
#>   block_15   block_16   block_17   block_18   block_19   block_20   block_21 
#> 2.85850668 1.03542570 0.40099084 0.46715881 0.62680193 0.39258926 0.80613673 
#>   block_22   block_23   block_24   block_25   block_26   block_27   block_28 
#> 0.82173939 1.30753721 0.09872223 0.74000753 0.57222159 0.34821973 0.30898416 
#>   block_29   block_30 
#> 0.09104453 0.46458797 
#> 
#> 
#> 
#> $alpha
#> [1] 0.05
#> 
#> $beta
#> NULL
#> 
#> $correction
#> NULL
#> 
#> $joint_error_bound
#> [1] 0.05
#> 
#> $method
#> [1] "unbounded_mom"
#> 
#> $n
#>  n1  n0 
#> 220 220 
#> 
#> $vhat
#>     vhat1     vhat0 
#> 1.2832587 0.5428872 
#> 
#> $rho
#>     rho1     rho0 
#> 1.632993 1.632993 
#> 
#> $k
#> k1 k0 
#> 30 30 
#> 
#> $b
#> b1 b0 
#>  3  3 
#> 
#> $psi
#> psi1 psi0 
#>    3    3 
#> 
#> $active
#> [1] FALSE
#> 
#> $status
#> [1] "treatment:relative_error_at_least_one;control:relative_error_at_least_one"
#> 
#> $normalization
#> NULL
#> 
#> attr(,"class")
#> [1] "cmr_unbounded_rectangle" "list"                   
```
