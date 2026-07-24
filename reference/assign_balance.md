# Baseline and comparator assignment rules

Standalone benchmark assignment rules for comparing CMR against balance,
feasible Neyman, and simple regularized Neyman variants.

## Usage

``` r
assign_balance(n = 1L)

assign_multiarm_balance(arms)

assign_stratified_balance(strata_share)

assign_feasible_neyman(vhat1, vhat0)

assign_trimmed_neyman(vhat1, vhat0, trim = 0.1)

assign_additive_regularized_neyman(vhat1, vhat0, nu)

assign_exponential_regularized_neyman(
  vhat1,
  vhat0,
  tau,
  zero_guard = c("any", "both", "none")
)
```

## Arguments

- n:

  Number of assignment shares to return for `assign_balance()`.

- arms:

  Either the number of treatment arms, excluding control, or a vector of
  arm labels that includes control arm `"0"`.

- strata_share:

  Named stratum population shares that sum to one.

- vhat1:

  Estimated treatment-arm variance or vector of estimates.

- vhat0:

  Estimated control-arm variance or vector of estimates.

- trim:

  Lower and upper trimming amount for `assign_trimmed_neyman()`. The
  returned share is clipped to `[trim, 1 - trim]`.

- nu:

  Nonnegative additive regularization strength.

- tau:

  Nonnegative exponent for exponential regularization.

- zero_guard:

  How zero variance estimates are guarded in
  `assign_exponential_regularized_neyman()`: `"any"` returns balance if
  either arm variance is zero, `"both"` only if both are zero, and
  `"none"` applies no extra guard.

## Value

Numeric assignment shares. Two-arm functions return treatment shares.
`assign_multiarm_balance()` returns a named vector over all arms,
including control `"0"`. `assign_stratified_balance()` returns total
assignment shares for treatment and control cells named like `"1:A"` and
`"0:A"`.

## See also

Other assignment helpers:
[`multiarm_variance_objective()`](https://juancyamin.github.io/cmrdesign/reference/multiarm_variance_objective.md),
[`stratified_variance_objective()`](https://juancyamin.github.io/cmrdesign/reference/stratified_variance_objective.md),
[`variance_objective()`](https://juancyamin.github.io/cmrdesign/reference/variance_objective.md)

## Examples

``` r
assign_balance(3)
#> [1] 0.5 0.5 0.5
assign_feasible_neyman(0.12, 0.04)
#> [1] 0.6339746
assign_trimmed_neyman(0.12, 0.04, trim = 0.10)
#> [1] 0.6339746
assign_multiarm_balance(2)
#>         0         1         2 
#> 0.4142136 0.2928932 0.2928932 
assign_stratified_balance(c(A = 0.4, B = 0.6))
#> 1:A 0:A 1:B 0:B 
#> 0.2 0.2 0.3 0.3 
```
