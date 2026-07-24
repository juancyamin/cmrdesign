# Folded-binomial distribution for Bernoulli sample variances

Probability mass and tail probabilities for the folded count that
determines the exact Bernoulli sample variance.

## Usage

``` r
folded_binomial_pmf(v, m)

folded_binomial_tails(v, m)
```

## Arguments

- v:

  Bernoulli variance in `[0, 1/4]`.

- m:

  Arm sample size, at least 2.

## Value

`folded_binomial_pmf()` returns a named probability vector over folded
counts `0, ..., floor(m / 2)`. `folded_binomial_tails()` returns a list
with lower and upper cumulative tail probabilities.

## See also

Other rectangle helpers:
[`binary_rectangle_corners()`](https://juancyamin.github.io/cmrdesign/reference/binary_rectangle_corners.md),
[`cmr_multiarm_from_rectangle()`](https://juancyamin.github.io/cmrdesign/reference/cmr_multiarm_from_rectangle.md),
[`cmr_stratified_from_rectangle()`](https://juancyamin.github.io/cmrdesign/reference/cmr_stratified_from_rectangle.md),
[`cmr_unbounded_from_rectangle()`](https://juancyamin.github.io/cmrdesign/reference/cmr_unbounded_from_rectangle.md),
[`multiarm_variance_objective()`](https://juancyamin.github.io/cmrdesign/reference/multiarm_variance_objective.md),
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
folded_binomial_pmf(v = 0.20, m = 8)
#>      0      1      2      3      4 
#> 0.0752 0.2304 0.3136 0.2688 0.1120 
folded_binomial_tails(v = 0.20, m = 8)
#> $lower
#>      0      1      2      3      4 
#> 0.0752 0.3056 0.6192 0.8880 1.0000 
#> 
#> $upper
#>      0      1      2      3      4 
#> 1.0000 0.9248 0.6944 0.3808 0.1120 
#> 
```
