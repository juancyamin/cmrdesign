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

  Target joint error level. Each arm uses
  [`variance_bounds_unbounded_mom()`](https://juancyamin.github.io/cmrdesign/reference/variance_bounds_unbounded_mom.md)
  with this same `alpha`, whose median-of-means block count gives
  one-arm error at most `alpha / 2`; the union bound over treatment and
  control yields the reported joint error bound `alpha`.

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
d <- rep(c(1, 0), each = 1000)
y <- c(rnorm(1000, sd = 1.3), rnorm(1000, sd = 0.8))
rectangle_unbounded(y, d, psi = 3)
#> $rectangle
#>      v_l1      v_u1      v_l0      v_u0 
#> 0.9407061 5.4828371 0.3839866 2.2380380 
#> 
#> $treatment
#> $treatment$L
#> [1] 0.9407061
#> 
#> $treatment$U
#> [1] 5.482837
#> 
#> $treatment$vhat
#> [1] 1.605886
#> 
#> $treatment$method
#> [1] "unbounded_mom"
#> 
#> $treatment$n
#> [1] 1000
#> 
#> $treatment$active
#> [1] TRUE
#> 
#> $treatment$status
#> [1] "active"
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
#> [1] 16
#> 
#> $treatment$statistic$n_pairs
#> [1] 500
#> 
#> $treatment$statistic$used_pairs
#> [1] 480
#> 
#> $treatment$statistic$discarded_pairs
#> [1] 20
#> 
#> $treatment$statistic$rho
#> [1] 0.7071068
#> 
#> $treatment$statistic$vhat
#> [1] 1.605886
#> 
#> $treatment$statistic$block_means
#>   block_1   block_2   block_3   block_4   block_5   block_6   block_7   block_8 
#> 0.8264601 2.0093886 1.0864913 1.1346452 3.5017351 2.2018684 2.8042170 1.5707867 
#>   block_9  block_10  block_11  block_12  block_13  block_14  block_15  block_16 
#> 1.8907423 2.8673219 1.7179108 1.5184831 0.7679407 1.7217652 2.2088291 2.0652819 
#>  block_17  block_18  block_19  block_20  block_21  block_22  block_23  block_24 
#> 1.0846034 1.6664282 1.1932702 0.9336808 1.9419124 1.2485053 0.9534496 1.7825340 
#>  block_25  block_26  block_27  block_28  block_29  block_30 
#> 1.6409850 1.2130678 1.4135047 1.2645739 2.0956792 1.2728847 
#> 
#> 
#> 
#> $control
#> $control$L
#> [1] 0.3839866
#> 
#> $control$U
#> [1] 2.238038
#> 
#> $control$vhat
#> [1] 0.6555062
#> 
#> $control$method
#> [1] "unbounded_mom"
#> 
#> $control$n
#> [1] 1000
#> 
#> $control$active
#> [1] TRUE
#> 
#> $control$status
#> [1] "active"
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
#> [1] 16
#> 
#> $control$statistic$n_pairs
#> [1] 500
#> 
#> $control$statistic$used_pairs
#> [1] 480
#> 
#> $control$statistic$discarded_pairs
#> [1] 20
#> 
#> $control$statistic$rho
#> [1] 0.7071068
#> 
#> $control$statistic$vhat
#> [1] 0.6555062
#> 
#> $control$statistic$block_means
#>   block_1   block_2   block_3   block_4   block_5   block_6   block_7   block_8 
#> 0.8268059 0.7458264 1.2432026 0.6287564 0.2765483 0.8158482 0.3228943 0.4124302 
#>   block_9  block_10  block_11  block_12  block_13  block_14  block_15  block_16 
#> 0.6884171 0.2887391 0.4877767 0.6667648 0.6321034 0.6772357 0.5018557 0.9619070 
#>  block_17  block_18  block_19  block_20  block_21  block_22  block_23  block_24 
#> 0.8959868 0.4229129 1.0095914 0.6488968 0.9806863 0.4090034 0.5394744 0.4322529 
#>  block_25  block_26  block_27  block_28  block_29  block_30 
#> 0.9776204 0.6533702 0.6881875 0.5677840 0.6576421 0.6689542 
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
#>   n1   n0 
#> 1000 1000 
#> 
#> $vhat
#>     vhat1     vhat0 
#> 1.6058858 0.6555062 
#> 
#> $rho
#>      rho1      rho0 
#> 0.7071068 0.7071068 
#> 
#> $k
#> k1 k0 
#> 30 30 
#> 
#> $b
#> b1 b0 
#> 16 16 
#> 
#> $psi
#> psi1 psi0 
#>    3    3 
#> 
#> $active
#> [1] TRUE
#> 
#> $status
#> [1] "active"
#> 
#> $normalization
#> NULL
#> 
#> attr(,"class")
#> [1] "cmr_unbounded_rectangle" "list"                   
```
