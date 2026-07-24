# Two-arm confidence rectangles

Construct a two-arm variance confidence rectangle from pilot data. These
are expert helpers used by
[`cmr_two_arm()`](https://juancyamin.github.io/cmrdesign/reference/cmr_two_arm.md)
and related extension functions.

## Usage

``` r
rectangle_bernoulli_binary(
  y,
  d,
  alpha = 0.05,
  beta = NULL,
  correction = c("bonferroni", "sidak_arms"),
  na.rm = TRUE,
  tol = 1e-11
)

rectangle_binary(
  y,
  d,
  alpha = 0.05,
  method = c("auto", "bounded", "bernoulli", "maurer_pontil", "mp", "bernoulli_exact",
    "martinez_taboada_ramdas", "mtr", "unbounded", "unbounded_mom", "median_of_means",
    "mom"),
  beta = NULL,
  correction = c("bonferroni", "sidak_arms"),
  normalize = FALSE,
  lower = NULL,
  upper = NULL,
  psi = NULL,
  na.rm = TRUE,
  tol = 1e-11
)

rectangle_two_arm(
  y,
  d,
  alpha = 0.05,
  method = c("auto", "bounded", "bernoulli", "maurer_pontil", "mp", "bernoulli_exact",
    "martinez_taboada_ramdas", "mtr", "unbounded", "unbounded_mom", "median_of_means",
    "mom"),
  beta = NULL,
  correction = c("bonferroni", "sidak_arms"),
  normalize = FALSE,
  lower = NULL,
  upper = NULL,
  psi = NULL,
  na.rm = TRUE,
  tol = 1e-11
)

rectangle_bernoulli_two_arm(
  y,
  d,
  alpha = 0.05,
  beta = NULL,
  correction = c("bonferroni", "sidak_arms"),
  na.rm = TRUE,
  tol = 1e-11
)
```

## Arguments

- y:

  Pilot outcomes.

- d:

  Pilot treatment indicator; treatment is `1` and control is `0`.

- alpha:

  Target joint error level.

- beta:

  Optional endpoint error allocation. If `NULL`, error is split
  according to `correction`.

- correction:

  Endpoint error correction, either `"bonferroni"` or `"sidak_arms"` for
  two-arm workflows.

- na.rm:

  If `TRUE`, drop rows with missing `y` or `d`.

- tol:

  Numerical tolerance for exact Bernoulli bound inversion.

- method:

  Confidence-set method. `"auto"` chooses exact Bernoulli bounds for 0/1
  outcomes and bounded Maurer–Pontil bounds otherwise.

- normalize:

  If `TRUE`, normalize bounded outcomes to `[0, 1]` before computing
  variances.

- lower, upper:

  Optional lower and upper outcome bounds used when `normalize = TRUE`.

- psi:

  Bounded-kurtosis parameter used only when `method` is an
  unbounded-outcome method.

## Value

A rectangle object. Bounded and Bernoulli methods return a
`cmr_binary_rectangle`; unbounded methods return a
`cmr_unbounded_rectangle`. The object contains the numeric `rectangle`,
one-arm bound details, endpoint error allocation, pilot sample sizes and
variance estimates, and method metadata.

## See also

Other rectangle helpers:
[`binary_rectangle_corners()`](https://juancyamin.github.io/cmrdesign/reference/binary_rectangle_corners.md),
[`cmr_multiarm_from_rectangle()`](https://juancyamin.github.io/cmrdesign/reference/cmr_multiarm_from_rectangle.md),
[`cmr_stratified_from_rectangle()`](https://juancyamin.github.io/cmrdesign/reference/cmr_stratified_from_rectangle.md),
[`cmr_unbounded_from_rectangle()`](https://juancyamin.github.io/cmrdesign/reference/cmr_unbounded_from_rectangle.md),
[`folded_binomial_pmf()`](https://juancyamin.github.io/cmrdesign/reference/folded_binomial_pmf.md),
[`multiarm_variance_objective()`](https://juancyamin.github.io/cmrdesign/reference/multiarm_variance_objective.md),
[`rectangle_bounded_two_arm()`](https://juancyamin.github.io/cmrdesign/reference/rectangle_bounded_binary.md),
[`rectangle_multiarm()`](https://juancyamin.github.io/cmrdesign/reference/rectangle_multiarm.md),
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
d <- rep(c(1, 0), each = 6)
y <- c(1, 0, 1, 1, 0, 1, 0, 0, 1, 0, 0, 1)
rectangle_two_arm(y, d, method = "bernoulli")
#> $rectangle
#>       v_l1       v_u1       v_l0       v_u0 
#> 0.02915219 0.25000000 0.02915219 0.25000000 
#> 
#> $treatment
#> $treatment$L
#> [1] 0.02915219
#> 
#> $treatment$U
#> [1] 0.25
#> 
#> $treatment$vhat
#> [1] 0.25
#> 
#> $treatment$method
#> [1] "bernoulli"
#> 
#> $treatment$n
#> [1] 6
#> 
#> $treatment$statistic
#> $treatment$statistic$j
#> [1] 2
#> 
#> $treatment$statistic$x
#> [1] 4
#> 
#> $treatment$statistic$m
#> [1] 6
#> 
#> $treatment$statistic$raw_sample_variance
#> [1] 0.2666667
#> 
#> $treatment$statistic$beta_l
#> [1] 0.0125
#> 
#> $treatment$statistic$beta_u
#> [1] 0.0125
#> 
#> 
#> 
#> $control
#> $control$L
#> [1] 0.02915219
#> 
#> $control$U
#> [1] 0.25
#> 
#> $control$vhat
#> [1] 0.25
#> 
#> $control$method
#> [1] "bernoulli"
#> 
#> $control$n
#> [1] 6
#> 
#> $control$statistic
#> $control$statistic$j
#> [1] 2
#> 
#> $control$statistic$x
#> [1] 2
#> 
#> $control$statistic$m
#> [1] 6
#> 
#> $control$statistic$raw_sample_variance
#> [1] 0.2666667
#> 
#> $control$statistic$beta_l
#> [1] 0.0125
#> 
#> $control$statistic$beta_u
#> [1] 0.0125
#> 
#> 
#> 
#> $alpha
#> [1] 0.05
#> 
#> $beta
#> beta_l1 beta_u1 beta_l0 beta_u0 
#>  0.0125  0.0125  0.0125  0.0125 
#> 
#> $correction
#> [1] "bonferroni"
#> 
#> $joint_error_bound
#> [1] 0.05
#> 
#> $method
#> [1] "bernoulli"
#> 
#> $n
#> n1 n0 
#>  6  6 
#> 
#> $vhat
#> vhat1 vhat0 
#>  0.25  0.25 
#> 
#> $normalization
#> NULL
#> 
#> attr(,"class")
#> [1] "cmr_binary_rectangle" "list"                
rectangle_binary(y, d, method = "auto")
#> $rectangle
#>       v_l1       v_u1       v_l0       v_u0 
#> 0.02915219 0.25000000 0.02915219 0.25000000 
#> 
#> $treatment
#> $treatment$L
#> [1] 0.02915219
#> 
#> $treatment$U
#> [1] 0.25
#> 
#> $treatment$vhat
#> [1] 0.25
#> 
#> $treatment$method
#> [1] "bernoulli"
#> 
#> $treatment$n
#> [1] 6
#> 
#> $treatment$statistic
#> $treatment$statistic$j
#> [1] 2
#> 
#> $treatment$statistic$x
#> [1] 4
#> 
#> $treatment$statistic$m
#> [1] 6
#> 
#> $treatment$statistic$raw_sample_variance
#> [1] 0.2666667
#> 
#> $treatment$statistic$beta_l
#> [1] 0.0125
#> 
#> $treatment$statistic$beta_u
#> [1] 0.0125
#> 
#> 
#> 
#> $control
#> $control$L
#> [1] 0.02915219
#> 
#> $control$U
#> [1] 0.25
#> 
#> $control$vhat
#> [1] 0.25
#> 
#> $control$method
#> [1] "bernoulli"
#> 
#> $control$n
#> [1] 6
#> 
#> $control$statistic
#> $control$statistic$j
#> [1] 2
#> 
#> $control$statistic$x
#> [1] 2
#> 
#> $control$statistic$m
#> [1] 6
#> 
#> $control$statistic$raw_sample_variance
#> [1] 0.2666667
#> 
#> $control$statistic$beta_l
#> [1] 0.0125
#> 
#> $control$statistic$beta_u
#> [1] 0.0125
#> 
#> 
#> 
#> $alpha
#> [1] 0.05
#> 
#> $beta
#> beta_l1 beta_u1 beta_l0 beta_u0 
#>  0.0125  0.0125  0.0125  0.0125 
#> 
#> $correction
#> [1] "bonferroni"
#> 
#> $joint_error_bound
#> [1] 0.05
#> 
#> $method
#> [1] "bernoulli"
#> 
#> $n
#> n1 n0 
#>  6  6 
#> 
#> $vhat
#> vhat1 vhat0 
#>  0.25  0.25 
#> 
#> $normalization
#> NULL
#> 
#> attr(,"class")
#> [1] "cmr_binary_rectangle" "list"                
```
