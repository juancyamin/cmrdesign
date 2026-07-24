# Stratified confidence rectangle

Construct cell-specific variance confidence intervals for a stratified
two-arm design.

## Usage

``` r
rectangle_stratified(
  y,
  d,
  strata,
  strata_share,
  alpha = 0.05,
  method = c("auto", "bounded", "bernoulli", "maurer_pontil", "mp", "bernoulli_exact",
    "martinez_taboada_ramdas", "mtr"),
  beta = NULL,
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

- d:

  Pilot treatment indicator; treatment is `1` and control is `0`.

- strata:

  Pilot stratum labels.

- strata_share:

  Named stratum population shares that sum to one.

- alpha:

  Target joint error level.

- method:

  Confidence-set method. `"auto"` chooses exact Bernoulli bounds for 0/1
  outcomes and bounded Maurer-Pontil bounds otherwise.

- beta:

  Optional endpoint error allocation. If `NULL`, Bonferroni error is
  split across all lower and upper treatment/control by stratum
  endpoints.

- normalize:

  If `TRUE`, normalize bounded outcomes to `[0, 1]` before computing
  variances.

- lower, upper:

  Optional lower and upper outcome bounds used when `normalize = TRUE`.

- na.rm:

  If `TRUE`, drop rows with missing `y`, `d`, or `strata`.

- tol:

  Numerical tolerance for exact Bernoulli bound inversion.

## Value

A list of class `cmr_stratified_rectangle` with lower and upper
rectangle matrices, checked rectangle details, stratum shares,
cell-level one-arm bound results, endpoint error allocation, sample
sizes, pilot variance estimates, normalization details, and method
metadata.

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
[`rectangle_unbounded()`](https://juancyamin.github.io/cmrdesign/reference/rectangle_unbounded.md),
[`stratified_variance_objective()`](https://juancyamin.github.io/cmrdesign/reference/stratified_variance_objective.md),
[`variance_bounds_bernoulli_exact()`](https://juancyamin.github.io/cmrdesign/reference/variance_bounds_bernoulli_exact.md),
[`variance_bounds_maurer_pontil()`](https://juancyamin.github.io/cmrdesign/reference/variance_bounds_maurer_pontil.md),
[`variance_bounds_unbounded_mom()`](https://juancyamin.github.io/cmrdesign/reference/variance_bounds_unbounded_mom.md)

## Examples

``` r
set.seed(8)
strata <- rep(c("A", "B"), each = 24)
d <- rep(rep(c(1, 0), each = 12), 2)
y <- c(rbeta(12, 2, 6), rbeta(12, 4, 4),
       rbeta(12, 5, 3), rbeta(12, 3, 5))
rectangle_stratified(y, d, strata, strata_share = c(A = 0.45, B = 0.55))
#> $rectangle
#> $rectangle$lower
#>   A B
#> 1 0 0
#> 0 0 0
#> 
#> $rectangle$upper
#>      A    B
#> 1 0.25 0.25
#> 0 0.25 0.25
#> 
#> 
#> $checked_rectangle
#> $checked_rectangle$lower
#> 1:A 0:A 1:B 0:B 
#>   0   0   0   0 
#> 
#> $checked_rectangle$upper
#>  1:A  0:A  1:B  0:B 
#> 0.25 0.25 0.25 0.25 
#> 
#> $checked_rectangle$lower_matrix
#>   A B
#> 1 0 0
#> 0 0 0
#> 
#> $checked_rectangle$upper_matrix
#>      A    B
#> 1 0.25 0.25
#> 0 0.25 0.25
#> 
#> $checked_rectangle$strata_share
#>    A    B 
#> 0.45 0.55 
#> 
#> $checked_rectangle$cell_names
#> [1] "1:A" "0:A" "1:B" "0:B"
#> 
#> $checked_rectangle$weights
#>      A      A      B      B 
#> 0.2025 0.2025 0.3025 0.3025 
#> 
#> 
#> $strata_share
#>    A    B 
#> 0.45 0.55 
#> 
#> $cell_results
#> $cell_results$`1:A`
#> $cell_results$`1:A`$L
#> [1] 0
#> 
#> $cell_results$`1:A`$U
#> [1] 0.25
#> 
#> $cell_results$`1:A`$vhat
#> [1] 0.01535518
#> 
#> $cell_results$`1:A`$method
#> [1] "bounded"
#> 
#> $cell_results$`1:A`$n
#> [1] 12
#> 
#> $cell_results$`1:A`$statistic
#> $cell_results$`1:A`$statistic$vhat
#> [1] 0.01535518
#> 
#> $cell_results$`1:A`$statistic$sdhat
#> [1] 0.123916
#> 
#> $cell_results$`1:A`$statistic$beta_l
#> [1] 0.00625
#> 
#> $cell_results$`1:A`$statistic$beta_u
#> [1] 0.00625
#> 
#> 
#> 
#> $cell_results$`0:A`
#> $cell_results$`0:A`$L
#> [1] 0
#> 
#> $cell_results$`0:A`$U
#> [1] 0.25
#> 
#> $cell_results$`0:A`$vhat
#> [1] 0.03202178
#> 
#> $cell_results$`0:A`$method
#> [1] "bounded"
#> 
#> $cell_results$`0:A`$n
#> [1] 12
#> 
#> $cell_results$`0:A`$statistic
#> $cell_results$`0:A`$statistic$vhat
#> [1] 0.03202178
#> 
#> $cell_results$`0:A`$statistic$sdhat
#> [1] 0.1789463
#> 
#> $cell_results$`0:A`$statistic$beta_l
#> [1] 0.00625
#> 
#> $cell_results$`0:A`$statistic$beta_u
#> [1] 0.00625
#> 
#> 
#> 
#> $cell_results$`1:B`
#> $cell_results$`1:B`$L
#> [1] 0
#> 
#> $cell_results$`1:B`$U
#> [1] 0.25
#> 
#> $cell_results$`1:B`$vhat
#> [1] 0.0462582
#> 
#> $cell_results$`1:B`$method
#> [1] "bounded"
#> 
#> $cell_results$`1:B`$n
#> [1] 12
#> 
#> $cell_results$`1:B`$statistic
#> $cell_results$`1:B`$statistic$vhat
#> [1] 0.0462582
#> 
#> $cell_results$`1:B`$statistic$sdhat
#> [1] 0.2150772
#> 
#> $cell_results$`1:B`$statistic$beta_l
#> [1] 0.00625
#> 
#> $cell_results$`1:B`$statistic$beta_u
#> [1] 0.00625
#> 
#> 
#> 
#> $cell_results$`0:B`
#> $cell_results$`0:B`$L
#> [1] 0
#> 
#> $cell_results$`0:B`$U
#> [1] 0.25
#> 
#> $cell_results$`0:B`$vhat
#> [1] 0.02022631
#> 
#> $cell_results$`0:B`$method
#> [1] "bounded"
#> 
#> $cell_results$`0:B`$n
#> [1] 12
#> 
#> $cell_results$`0:B`$statistic
#> $cell_results$`0:B`$statistic$vhat
#> [1] 0.02022631
#> 
#> $cell_results$`0:B`$statistic$sdhat
#> [1] 0.1422192
#> 
#> $cell_results$`0:B`$statistic$beta_l
#> [1] 0.00625
#> 
#> $cell_results$`0:B`$statistic$beta_u
#> [1] 0.00625
#> 
#> 
#> 
#> 
#> $alpha
#> [1] 0.05
#> 
#> $beta
#> $beta$lower
#>         A       B
#> 1 0.00625 0.00625
#> 0 0.00625 0.00625
#> 
#> $beta$upper
#>         A       B
#> 1 0.00625 0.00625
#> 0 0.00625 0.00625
#> 
#> 
#> $joint_error_bound
#> [1] 0.05
#> 
#> $method
#> [1] "bounded"
#> 
#> $n
#>    A  B
#> 1 12 12
#> 0 12 12
#> 
#> $vhat
#>            A          B
#> 1 0.01535518 0.04625820
#> 0 0.03202178 0.02022631
#> 
#> $normalization
#> NULL
#> 
#> attr(,"class")
#> [1] "cmr_stratified_rectangle" "list"                    
```
