# Two-arm variance objectives and Neyman allocation

Helper functions for the two-arm variance objective, oracle variance,
Neyman allocation, and regret. These are useful for checking CMR
certificates and comparing CMR against oracle or feasible-Neyman
benchmarks.

## Usage

``` r
variance_objective(pi, v1, v0)

oracle_variance(v1, v0)

assign_neyman(v1, v0)

regret(pi, v1, v0)
```

## Arguments

- pi:

  Treatment assignment share. Values must lie in `[0, 1]`.

- v1:

  Treatment-arm outcome variance. For bounded or Bernoulli outcomes,
  this must lie in `[0, 1/4]`.

- v0:

  Control-arm outcome variance. For bounded or Bernoulli outcomes, this
  must lie in `[0, 1/4]`.

## Value

Numeric vector after ordinary R recycling of `pi`, `v1`, and `v0`.
`variance_objective()` returns `v1 / pi + v0 / (1 - pi)`,
`oracle_variance()` returns the Neyman-oracle value
`(sqrt(v1) + sqrt(v0))^2`, `assign_neyman()` returns the treatment
share, and `regret()` returns excess variance relative to the oracle.

## See also

Other assignment helpers:
[`assign_balance()`](https://juancyamin.github.io/cmrdesign/reference/assign_balance.md),
[`multiarm_variance_objective()`](https://juancyamin.github.io/cmrdesign/reference/multiarm_variance_objective.md),
[`stratified_variance_objective()`](https://juancyamin.github.io/cmrdesign/reference/stratified_variance_objective.md)

## Examples

``` r
v1 <- 0.12
v0 <- 0.04
pi <- assign_neyman(v1, v0)
variance_objective(pi, v1, v0)
#> [1] 0.2985641
oracle_variance(v1, v0)
#> [1] 0.2985641
regret(0.5, v1, v0)
#> [1] 0.02143594
```
