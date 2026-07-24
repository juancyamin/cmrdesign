# Bounded two-arm confidence rectangle

Construct a two-arm variance confidence rectangle for bounded outcomes
using Maurer–Pontil or Martinez-Taboada–Ramdas one-arm bounds.

## Usage

``` r
rectangle_bounded_two_arm(
  y,
  d,
  alpha = 0.05,
  method = c("bounded", "maurer_pontil", "mp", "martinez_taboada_ramdas", "mtr"),
  beta = NULL,
  correction = c("bonferroni", "sidak_arms"),
  normalize = FALSE,
  lower = NULL,
  upper = NULL,
  na.rm = TRUE
)

rectangle_bounded_binary(
  y,
  d,
  alpha = 0.05,
  method = c("bounded", "maurer_pontil", "mp", "martinez_taboada_ramdas", "mtr"),
  beta = NULL,
  correction = c("bonferroni", "sidak_arms"),
  normalize = FALSE,
  lower = NULL,
  upper = NULL,
  na.rm = TRUE
)
```

## Arguments

- y:

  Pilot outcomes.

- d:

  Pilot treatment indicator; treatment is `1` and control is `0`.

- alpha:

  Target joint error level.

- method:

  Bounded-outcome method. `"bounded"`, `"maurer_pontil"`, and `"mp"` are
  synonyms; `"martinez_taboada_ramdas"` and `"mtr"` use MTR bounds.

- beta:

  Optional endpoint error allocation. If `NULL`, error is split
  according to `correction`.

- correction:

  Endpoint error correction, either `"bonferroni"` or `"sidak_arms"`.

- normalize:

  If `TRUE`, normalize outcomes to `[0, 1]` before computing variances.

- lower, upper:

  Optional lower and upper outcome bounds used when `normalize = TRUE`.

- na.rm:

  If `TRUE`, drop rows with missing `y` or `d`.

## Value

A `cmr_binary_rectangle` list with `rectangle`, one-arm bound objects
for treatment and control, endpoint error allocation, sample sizes,
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
d <- rep(c(1, 0), each = 5)
y <- c(0.20, 0.40, 0.30, 0.10, 0.60, 0.50, 0.30, 0.20, 0.40, 0.10)
rectangle_bounded_binary(y, d, method = "bounded")
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
#> [1] 0.037
#> 
#> $treatment$method
#> [1] "bounded"
#> 
#> $treatment$n
#> [1] 5
#> 
#> $treatment$statistic
#> $treatment$statistic$vhat
#> [1] 0.037
#> 
#> $treatment$statistic$sdhat
#> [1] 0.1923538
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
#> [1] 0.025
#> 
#> $control$method
#> [1] "bounded"
#> 
#> $control$n
#> [1] 5
#> 
#> $control$statistic
#> $control$statistic$vhat
#> [1] 0.025
#> 
#> $control$statistic$sdhat
#> [1] 0.1581139
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
#>  5  5 
#> 
#> $vhat
#> vhat1 vhat0 
#> 0.037 0.025 
#> 
#> $normalization
#> NULL
#> 
#> attr(,"class")
#> [1] "cmr_binary_rectangle" "list"                
```
