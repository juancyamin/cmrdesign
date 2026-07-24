# Multiple-outcome confidence rectangle

Construct an effective two-arm variance rectangle for multiple outcomes.
For `estimand = "index"`, outcomes are first combined using `weights`.
For `estimand = "coprimary"`, one rectangle is built per outcome and
combined conservatively using the outcome weights.

## Usage

``` r
rectangle_multiple_outcomes(
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

  Optional scalar endpoint error allocation.

- na.rm:

  If `TRUE`, drop rows with missing `y` or `d`.

- tol:

  Numerical tolerance for exact Bernoulli bound inversion.

## Value

A list of class `cmr_multiple_outcomes_rectangle`. For
`estimand = "index"`, this wraps the ordinary two-arm rectangle for the
weighted index. For `estimand = "coprimary"`, it contains the effective
two-arm `rectangle`, weights, outcome-specific bounds, pilot summaries,
endpoint error allocation, and method metadata.

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
[`rectangle_proxy()`](https://juancyamin.github.io/cmrdesign/reference/rectangle_proxy.md),
[`rectangle_stratified()`](https://juancyamin.github.io/cmrdesign/reference/rectangle_stratified.md),
[`rectangle_unbounded()`](https://juancyamin.github.io/cmrdesign/reference/rectangle_unbounded.md),
[`stratified_variance_objective()`](https://juancyamin.github.io/cmrdesign/reference/stratified_variance_objective.md),
[`variance_bounds_bernoulli_exact()`](https://juancyamin.github.io/cmrdesign/reference/variance_bounds_bernoulli_exact.md),
[`variance_bounds_maurer_pontil()`](https://juancyamin.github.io/cmrdesign/reference/variance_bounds_maurer_pontil.md),
[`variance_bounds_unbounded_mom()`](https://juancyamin.github.io/cmrdesign/reference/variance_bounds_unbounded_mom.md)

## Examples

``` r
set.seed(9)
d <- rep(c(1, 0), each = 20)
y <- cbind(
  y1 = c(rbeta(20, 2, 6), rbeta(20, 4, 4)),
  y2 = c(rbeta(20, 5, 3), rbeta(20, 3, 5))
)
rectangle_multiple_outcomes(y, d, weights = c(0.6, 0.4))
#> $rectangle
#> v_l1 v_u1 v_l0 v_u0 
#> 0.00 0.25 0.00 0.25 
#> 
#> $estimand
#> [1] "coprimary"
#> 
#> $weights
#>  y1  y2 
#> 0.6 0.4 
#> 
#> $alpha
#> [1] 0.05
#> 
#> $beta
#> [1] 0.00625
#> 
#> $joint_error_bound
#> [1] 0.05
#> 
#> $method
#> [1] "bounded"
#> 
#> $n
#> n1 n0 
#> 20 20 
#> 
#> $vhat
#>      vhat1      vhat0 
#> 0.02317230 0.01787976 
#> 
#> $outcome_bounds
#> $outcome_bounds$y1
#> $outcome_bounds$y1$treatment
#> $outcome_bounds$y1$treatment$L
#> [1] 0
#> 
#> $outcome_bounds$y1$treatment$U
#> [1] 0.25
#> 
#> $outcome_bounds$y1$treatment$vhat
#> [1] 0.01749479
#> 
#> $outcome_bounds$y1$treatment$method
#> [1] "bounded"
#> 
#> $outcome_bounds$y1$treatment$n
#> [1] 20
#> 
#> $outcome_bounds$y1$treatment$statistic
#> $outcome_bounds$y1$treatment$statistic$vhat
#> [1] 0.01749479
#> 
#> $outcome_bounds$y1$treatment$statistic$sdhat
#> [1] 0.1322679
#> 
#> $outcome_bounds$y1$treatment$statistic$beta_l
#> [1] 0.00625
#> 
#> $outcome_bounds$y1$treatment$statistic$beta_u
#> [1] 0.00625
#> 
#> 
#> 
#> $outcome_bounds$y1$control
#> $outcome_bounds$y1$control$L
#> [1] 0
#> 
#> $outcome_bounds$y1$control$U
#> [1] 0.25
#> 
#> $outcome_bounds$y1$control$vhat
#> [1] 0.01650368
#> 
#> $outcome_bounds$y1$control$method
#> [1] "bounded"
#> 
#> $outcome_bounds$y1$control$n
#> [1] 20
#> 
#> $outcome_bounds$y1$control$statistic
#> $outcome_bounds$y1$control$statistic$vhat
#> [1] 0.01650368
#> 
#> $outcome_bounds$y1$control$statistic$sdhat
#> [1] 0.1284667
#> 
#> $outcome_bounds$y1$control$statistic$beta_l
#> [1] 0.00625
#> 
#> $outcome_bounds$y1$control$statistic$beta_u
#> [1] 0.00625
#> 
#> 
#> 
#> 
#> $outcome_bounds$y2
#> $outcome_bounds$y2$treatment
#> $outcome_bounds$y2$treatment$L
#> [1] 0
#> 
#> $outcome_bounds$y2$treatment$U
#> [1] 0.25
#> 
#> $outcome_bounds$y2$treatment$vhat
#> [1] 0.03168856
#> 
#> $outcome_bounds$y2$treatment$method
#> [1] "bounded"
#> 
#> $outcome_bounds$y2$treatment$n
#> [1] 20
#> 
#> $outcome_bounds$y2$treatment$statistic
#> $outcome_bounds$y2$treatment$statistic$vhat
#> [1] 0.03168856
#> 
#> $outcome_bounds$y2$treatment$statistic$sdhat
#> [1] 0.1780128
#> 
#> $outcome_bounds$y2$treatment$statistic$beta_l
#> [1] 0.00625
#> 
#> $outcome_bounds$y2$treatment$statistic$beta_u
#> [1] 0.00625
#> 
#> 
#> 
#> $outcome_bounds$y2$control
#> $outcome_bounds$y2$control$L
#> [1] 0
#> 
#> $outcome_bounds$y2$control$U
#> [1] 0.25
#> 
#> $outcome_bounds$y2$control$vhat
#> [1] 0.01994388
#> 
#> $outcome_bounds$y2$control$method
#> [1] "bounded"
#> 
#> $outcome_bounds$y2$control$n
#> [1] 20
#> 
#> $outcome_bounds$y2$control$statistic
#> $outcome_bounds$y2$control$statistic$vhat
#> [1] 0.01994388
#> 
#> $outcome_bounds$y2$control$statistic$sdhat
#> [1] 0.1412228
#> 
#> $outcome_bounds$y2$control$statistic$beta_l
#> [1] 0.00625
#> 
#> $outcome_bounds$y2$control$statistic$beta_u
#> [1] 0.00625
#> 
#> 
#> 
#> 
#> 
#> $outcome_vhat
#> $outcome_vhat$treatment
#> [1] 0.01749479 0.03168856
#> 
#> $outcome_vhat$control
#> [1] 0.01650368 0.01994388
#> 
#> 
#> attr(,"class")
#> [1] "cmr_multiple_outcomes_rectangle" "list"                           
```
