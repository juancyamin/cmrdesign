# Multi-arm variance objectives and Neyman allocation

Helper functions for shared-control multi-arm variance objectives,
oracle values, Neyman allocations, regret, and rectangle vertices.

## Usage

``` r
multiarm_variance_objective(pi, variances)

multiarm_oracle_variance(variances)

assign_multiarm_neyman(variances)

multiarm_regret(pi, variances)

multiarm_rectangle_vertices(rectangle, max_vertices = 65536L)
```

## Arguments

- pi:

  Named assignment-share vector over all arms, including control arm
  `"0"`.

- variances:

  Named variance vector over all arms, including control arm `"0"`.

- rectangle:

  Multi-arm variance rectangle, either a matrix/data frame with `lower`
  and `upper` columns or a named vector with entries like `v_l0`,
  `v_u0`, `v_l1`, `v_u1`.

- max_vertices:

  Maximum number of hyperrectangle vertices to enumerate.

## Value

Numeric objective/regret values, named assignment vectors, or a vertex
matrix. `assign_multiarm_neyman()` returns total assignment shares over
control and all treatment arms. `multiarm_rectangle_vertices()` returns
one row per variance-rectangle vertex.

## See also

Other assignment helpers:
[`assign_balance()`](https://juancyamin.github.io/cmrdesign/reference/assign_balance.md),
[`stratified_variance_objective()`](https://juancyamin.github.io/cmrdesign/reference/stratified_variance_objective.md),
[`variance_objective()`](https://juancyamin.github.io/cmrdesign/reference/variance_objective.md)

Other rectangle helpers:
[`binary_rectangle_corners()`](https://juancyamin.github.io/cmrdesign/reference/binary_rectangle_corners.md),
[`cmr_multiarm_from_rectangle()`](https://juancyamin.github.io/cmrdesign/reference/cmr_multiarm_from_rectangle.md),
[`cmr_stratified_from_rectangle()`](https://juancyamin.github.io/cmrdesign/reference/cmr_stratified_from_rectangle.md),
[`cmr_unbounded_from_rectangle()`](https://juancyamin.github.io/cmrdesign/reference/cmr_unbounded_from_rectangle.md),
[`folded_binomial_pmf()`](https://juancyamin.github.io/cmrdesign/reference/folded_binomial_pmf.md),
[`rectangle_bernoulli_binary()`](https://juancyamin.github.io/cmrdesign/reference/rectangle_bernoulli_binary.md),
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
variances <- c("0" = 0.05, "1" = 0.10, "2" = 0.04)
pi <- assign_multiarm_neyman(variances)
multiarm_variance_objective(pi, variances)
#> [1] 0.6929822
multiarm_regret(pi, variances)
#> [1] -1.110223e-16
```
