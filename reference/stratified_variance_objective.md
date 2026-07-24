# Stratified variance objectives and Neyman allocation

Helper functions for stratified two-arm variance objectives, oracle
values, Neyman allocations, regret, and rectangle vertices.

## Usage

``` r
stratified_variance_objective(pi, variances, strata_share)

stratified_oracle_variance(variances, strata_share)

assign_stratified_neyman(variances, strata_share)

stratified_regret(pi, variances, strata_share)

stratified_rectangle_vertices(rectangle, strata_share, max_vertices = 65536L)
```

## Arguments

- pi:

  Assignment shares for each treatment/control by stratum cell. A vector
  should be named like `"1:A"` and `"0:A"`, or a `2 x S` matrix with
  treatment and control rows.

- variances:

  Cell variances as a `2 x S` matrix or data frame with treatment and
  control rows.

- strata_share:

  Named stratum population shares that sum to one.

- rectangle:

  Stratified variance rectangle, a list with `lower` and `upper` `2 x S`
  matrices.

- max_vertices:

  Maximum number of hyperrectangle vertices to enumerate.

## Value

Numeric objective/regret values, named assignment vectors, or a vertex
matrix. `assign_stratified_neyman()` returns total assignment shares
over treatment/control by stratum cells.

## See also

Other assignment helpers:
[`assign_balance()`](https://juancyamin.github.io/cmrdesign/reference/assign_balance.md),
[`multiarm_variance_objective()`](https://juancyamin.github.io/cmrdesign/reference/multiarm_variance_objective.md),
[`variance_objective()`](https://juancyamin.github.io/cmrdesign/reference/variance_objective.md)

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
[`rectangle_unbounded()`](https://juancyamin.github.io/cmrdesign/reference/rectangle_unbounded.md),
[`variance_bounds_bernoulli_exact()`](https://juancyamin.github.io/cmrdesign/reference/variance_bounds_bernoulli_exact.md),
[`variance_bounds_maurer_pontil()`](https://juancyamin.github.io/cmrdesign/reference/variance_bounds_maurer_pontil.md),
[`variance_bounds_unbounded_mom()`](https://juancyamin.github.io/cmrdesign/reference/variance_bounds_unbounded_mom.md)

## Examples

``` r
strata_share <- c(A = 0.4, B = 0.6)
variances <- rbind(
  treatment = c(A = 0.10, B = 0.04),
  control = c(A = 0.05, B = 0.08)
)
pi <- assign_stratified_neyman(variances, strata_share)
stratified_variance_objective(pi, variances, strata_share)
#> [1] 0.2556713
```
