# Multi-arm confidence rectangle

Construct arm-specific variance confidence intervals for a
shared-control multi-arm design.

## Usage

``` r
rectangle_multiarm(
  y,
  arm,
  alpha = 0.05,
  method = c("auto", "bounded", "bernoulli", "maurer_pontil", "mp", "bernoulli_exact",
    "martinez_taboada_ramdas", "mtr"),
  beta = NULL,
  control_arm = 0,
  normalize = FALSE,
  lower = NULL,
  upper = NULL,
  na.rm = TRUE,
  tol = 1e-11
)
```

## Arguments

- y:

  Pilot outcomes.

- arm:

  Pilot arm labels. The control arm is identified by `control_arm` and
  internally standardized to `"0"`.

- alpha:

  Target joint error level.

- method:

  Confidence-set method. `"auto"` chooses exact Bernoulli bounds for 0/1
  outcomes and bounded Maurer-Pontil bounds otherwise.

- beta:

  Optional endpoint error allocation. If `NULL`, Bonferroni error is
  split across all lower and upper arm endpoints. A scalar, matrix, or
  named vector allocation may also be supplied.

- control_arm:

  Label identifying the control arm in `arm`.

- normalize:

  If `TRUE`, normalize bounded outcomes to `[0, 1]` before computing
  variances.

- lower, upper:

  Optional lower and upper outcome bounds used when `normalize = TRUE`.

- na.rm:

  If `TRUE`, drop rows with missing `y` or `arm`.

- tol:

  Numerical tolerance for exact Bernoulli bound inversion.

## Value

A list of class `cmr_multiarm_rectangle` with checked rectangle, arm
labels, one-arm bound results, endpoint error allocation, sample sizes,
pilot variance estimates, normalization details, and method metadata.

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
[`rectangle_multiple_outcomes()`](https://juancyamin.github.io/cmrdesign/reference/rectangle_multiple_outcomes.md),
[`rectangle_proxy()`](https://juancyamin.github.io/cmrdesign/reference/rectangle_proxy.md),
[`rectangle_stratified()`](https://juancyamin.github.io/cmrdesign/reference/rectangle_stratified.md),
[`rectangle_unbounded()`](https://juancyamin.github.io/cmrdesign/reference/rectangle_unbounded.md),
[`stratified_variance_objective()`](https://juancyamin.github.io/cmrdesign/reference/stratified_variance_objective.md),
[`variance_bounds_bernoulli_exact()`](https://juancyamin.github.io/cmrdesign/reference/variance_bounds_bernoulli_exact.md),
[`variance_bounds_maurer_pontil()`](https://juancyamin.github.io/cmrdesign/reference/variance_bounds_maurer_pontil.md),
[`variance_bounds_unbounded_mom()`](https://juancyamin.github.io/cmrdesign/reference/variance_bounds_unbounded_mom.md)

## Examples

``` r
set.seed(6)
arm <- rep(c(0, 1, 2), each = 12)
y <- c(rbeta(12, 4, 4), rbeta(12, 2, 6), rbeta(12, 5, 3))
rectangle_multiarm(y, arm, method = "bounded")
#> $rectangle
#>   lower upper
#> 0     0  0.25
#> 1     0  0.25
#> 2     0  0.25
#> 
#> $arms
#> [1] "0" "1" "2"
#> 
#> $arm_results
#> $arm_results$`0`
#> $arm_results$`0`$L
#> [1] 0
#> 
#> $arm_results$`0`$U
#> [1] 0.25
#> 
#> $arm_results$`0`$vhat
#> [1] 0.01942598
#> 
#> $arm_results$`0`$method
#> [1] "bounded"
#> 
#> $arm_results$`0`$n
#> [1] 12
#> 
#> $arm_results$`0`$statistic
#> $arm_results$`0`$statistic$vhat
#> [1] 0.01942598
#> 
#> $arm_results$`0`$statistic$sdhat
#> [1] 0.1393771
#> 
#> $arm_results$`0`$statistic$beta_l
#> [1] 0.008333333
#> 
#> $arm_results$`0`$statistic$beta_u
#> [1] 0.008333333
#> 
#> 
#> 
#> $arm_results$`1`
#> $arm_results$`1`$L
#> [1] 0
#> 
#> $arm_results$`1`$U
#> [1] 0.25
#> 
#> $arm_results$`1`$vhat
#> [1] 0.02244602
#> 
#> $arm_results$`1`$method
#> [1] "bounded"
#> 
#> $arm_results$`1`$n
#> [1] 12
#> 
#> $arm_results$`1`$statistic
#> $arm_results$`1`$statistic$vhat
#> [1] 0.02244602
#> 
#> $arm_results$`1`$statistic$sdhat
#> [1] 0.14982
#> 
#> $arm_results$`1`$statistic$beta_l
#> [1] 0.008333333
#> 
#> $arm_results$`1`$statistic$beta_u
#> [1] 0.008333333
#> 
#> 
#> 
#> $arm_results$`2`
#> $arm_results$`2`$L
#> [1] 0
#> 
#> $arm_results$`2`$U
#> [1] 0.25
#> 
#> $arm_results$`2`$vhat
#> [1] 0.03277218
#> 
#> $arm_results$`2`$method
#> [1] "bounded"
#> 
#> $arm_results$`2`$n
#> [1] 12
#> 
#> $arm_results$`2`$statistic
#> $arm_results$`2`$statistic$vhat
#> [1] 0.03277218
#> 
#> $arm_results$`2`$statistic$sdhat
#> [1] 0.1810309
#> 
#> $arm_results$`2`$statistic$beta_l
#> [1] 0.008333333
#> 
#> $arm_results$`2`$statistic$beta_u
#> [1] 0.008333333
#> 
#> 
#> 
#> 
#> $alpha
#> [1] 0.05
#> 
#> $beta
#>         lower       upper
#> 0 0.008333333 0.008333333
#> 1 0.008333333 0.008333333
#> 2 0.008333333 0.008333333
#> 
#> $joint_error_bound
#> [1] 0.05
#> 
#> $method
#> [1] "bounded"
#> 
#> $n
#>  0  1  2 
#> 12 12 12 
#> 
#> $vhat
#>          0          1          2 
#> 0.01942598 0.02244602 0.03277218 
#> 
#> $normalization
#> NULL
#> 
#> $control_arm
#> [1] 0
#> 
#> attr(,"class")
#> [1] "cmr_multiarm_rectangle" "list"                  
```
