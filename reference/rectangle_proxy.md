# Proxy or delayed-outcome confidence rectangle

Construct a primary-outcome variance rectangle by estimating a
proxy-outcome rectangle and widening each arm's standard-deviation
interval by `zeta`.

## Usage

``` r
rectangle_proxy(
  proxy_y,
  d,
  zeta,
  alpha = 0.05,
  method = c("auto", "bounded", "bernoulli", "maurer_pontil", "mp", "bernoulli_exact",
    "martinez_taboada_ramdas", "mtr"),
  beta = NULL,
  correction = c("bonferroni", "sidak_arms"),
  normalize = FALSE,
  lower = NULL,
  upper = NULL,
  na.rm = TRUE,
  tol = 1e-11
)

rectangle_delayed_outcome(
  proxy_y,
  d,
  zeta,
  alpha = 0.05,
  method = c("auto", "bounded", "bernoulli", "maurer_pontil", "mp", "bernoulli_exact",
    "martinez_taboada_ramdas", "mtr"),
  beta = NULL,
  correction = c("bonferroni", "sidak_arms"),
  normalize = FALSE,
  lower = NULL,
  upper = NULL,
  na.rm = TRUE,
  tol = 1e-11
)
```

## Arguments

- proxy_y:

  Pilot proxy or delayed-primary outcomes.

- d:

  Pilot treatment indicator; treatment is `1` and control is `0`.

- zeta:

  Nonnegative standard-deviation bridge radius. Provide a scalar shared
  across arms or a treatment/control pair.

- alpha:

  Target joint error level.

- method:

  Confidence-set method. `"auto"` chooses exact Bernoulli bounds for 0/1
  outcomes and bounded Maurer-Pontil bounds otherwise.

- beta:

  Optional endpoint error allocation. If `NULL`, error is split
  according to `correction`.

- correction:

  Endpoint error correction, either `"bonferroni"` or `"sidak_arms"`.

- normalize:

  If `TRUE`, normalize bounded proxy outcomes to `[0, 1]` before
  computing variances.

- lower, upper:

  Optional lower and upper outcome bounds used when `normalize = TRUE`.

- na.rm:

  If `TRUE`, drop rows with missing `proxy_y` or `d`.

- tol:

  Numerical tolerance for exact Bernoulli bound inversion.

## Value

A list of class `cmr_proxy_rectangle` and `cmr_binary_rectangle` with
the widened primary-outcome rectangle, the underlying proxy confidence
set, `zeta`, bridge metadata, endpoint error allocation, pilot
summaries, and method metadata.

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
[`rectangle_stratified()`](https://juancyamin.github.io/cmrdesign/reference/rectangle_stratified.md),
[`rectangle_unbounded()`](https://juancyamin.github.io/cmrdesign/reference/rectangle_unbounded.md),
[`stratified_variance_objective()`](https://juancyamin.github.io/cmrdesign/reference/stratified_variance_objective.md),
[`variance_bounds_bernoulli_exact()`](https://juancyamin.github.io/cmrdesign/reference/variance_bounds_bernoulli_exact.md),
[`variance_bounds_maurer_pontil()`](https://juancyamin.github.io/cmrdesign/reference/variance_bounds_maurer_pontil.md),
[`variance_bounds_unbounded_mom()`](https://juancyamin.github.io/cmrdesign/reference/variance_bounds_unbounded_mom.md)

## Examples

``` r
set.seed(11)
d <- rep(c(1, 0), each = 30)
proxy_y <- c(rbeta(30, 2, 6), rbeta(30, 4, 4))
rectangle_proxy(proxy_y, d, zeta = 0.05)
#> $rectangle
#> v_l1 v_u1 v_l0 v_u0 
#> 0.00 0.25 0.00 0.25 
#> 
#> $treatment
#> $treatment$L
#> [1] 0
#> 
#> $treatment$U
#> [1] 0.25
#> 
#> $treatment$vhat
#> [1] 0.01197773
#> 
#> $treatment$method
#> [1] "bounded"
#> 
#> $treatment$n
#> [1] 30
#> 
#> $treatment$statistic
#> $treatment$statistic$vhat
#> [1] 0.01197773
#> 
#> $treatment$statistic$sdhat
#> [1] 0.1094428
#> 
#> $treatment$statistic$beta_l
#> [1] 0.0125
#> 
#> $treatment$statistic$beta_u
#> [1] 0.0125
#> 
#> 
#> $treatment$L_proxy
#> [1] 0
#> 
#> $treatment$U_proxy
#> [1] 0.25
#> 
#> 
#> $control
#> $control$L
#> [1] 0
#> 
#> $control$U
#> [1] 0.25
#> 
#> $control$vhat
#> [1] 0.02927848
#> 
#> $control$method
#> [1] "bounded"
#> 
#> $control$n
#> [1] 30
#> 
#> $control$statistic
#> $control$statistic$vhat
#> [1] 0.02927848
#> 
#> $control$statistic$sdhat
#> [1] 0.1711096
#> 
#> $control$statistic$beta_l
#> [1] 0.0125
#> 
#> $control$statistic$beta_u
#> [1] 0.0125
#> 
#> 
#> $control$L_proxy
#> [1] 0
#> 
#> $control$U_proxy
#> [1] 0.25
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
#> [1] "proxy_bounded"
#> 
#> $n
#> n1 n0 
#> 30 30 
#> 
#> $vhat
#>      vhat1      vhat0 
#> 0.01197773 0.02927848 
#> 
#> $normalization
#> NULL
#> 
#> $proxy_confidence_set
#> $rectangle
#> v_l1 v_u1 v_l0 v_u0 
#> 0.00 0.25 0.00 0.25 
#> 
#> $treatment
#> $treatment$L
#> [1] 0
#> 
#> $treatment$U
#> [1] 0.25
#> 
#> $treatment$vhat
#> [1] 0.01197773
#> 
#> $treatment$method
#> [1] "bounded"
#> 
#> $treatment$n
#> [1] 30
#> 
#> $treatment$statistic
#> $treatment$statistic$vhat
#> [1] 0.01197773
#> 
#> $treatment$statistic$sdhat
#> [1] 0.1094428
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
#> [1] 0
#> 
#> $control$U
#> [1] 0.25
#> 
#> $control$vhat
#> [1] 0.02927848
#> 
#> $control$method
#> [1] "bounded"
#> 
#> $control$n
#> [1] 30
#> 
#> $control$statistic
#> $control$statistic$vhat
#> [1] 0.02927848
#> 
#> $control$statistic$sdhat
#> [1] 0.1711096
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
#> [1] "bounded"
#> 
#> $n
#> n1 n0 
#> 30 30 
#> 
#> $vhat
#>      vhat1      vhat0 
#> 0.01197773 0.02927848 
#> 
#> $normalization
#> NULL
#> 
#> attr(,"class")
#> [1] "cmr_binary_rectangle" "list"                
#> 
#> $zeta
#>    1    0 
#> 0.05 0.05 
#> 
#> $bridge
#> $bridge$assumption
#> [1] "abs(primary_sd - proxy_sd) <= zeta by arm"
#> 
#> $bridge$proxy_rectangle
#> v_l1 v_u1 v_l0 v_u0 
#> 0.00 0.25 0.00 0.25 
#> 
#> $bridge$primary_rectangle
#> v_l1 v_u1 v_l0 v_u0 
#> 0.00 0.25 0.00 0.25 
#> 
#> 
#> attr(,"class")
#> [1] "cmr_proxy_rectangle"  "cmr_binary_rectangle" "list"                
```
