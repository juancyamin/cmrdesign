# Print pilot plans and confidence rectangles

Compact display methods for pilot-planning objects and for the
confidence rectangles returned by the `rectangle_*()` constructors. They
show the headline entries. The full object remains an ordinary list.

## Usage

``` r
# S3 method for class 'cmr_pilot_plan'
print(x, ...)

# S3 method for class 'cmr_pilot_viability_band'
print(x, ...)

# S3 method for class 'cmr_binary_rectangle'
print(x, ...)

# S3 method for class 'cmr_unbounded_rectangle'
print(x, ...)

# S3 method for class 'cmr_multiarm_rectangle'
print(x, ...)

# S3 method for class 'cmr_stratified_rectangle'
print(x, ...)

# S3 method for class 'cmr_multiple_outcomes_rectangle'
print(x, ...)
```

## Arguments

- x:

  A `cmr_pilot_plan`, `cmr_pilot_viability_band`, or confidence
  rectangle object.

- ...:

  Reserved for future extensions.

## Value

The original object, invisibly.

## See also

Other pilot planning:
[`activation_threshold_bounded()`](https://juancyamin.github.io/cmrdesign/dev/reference/activation_threshold_bounded.md),
[`break_even_pilot_share()`](https://juancyamin.github.io/cmrdesign/dev/reference/break_even_pilot_share.md),
[`pilot_plan()`](https://juancyamin.github.io/cmrdesign/dev/reference/pilot_plan.md),
[`pilot_viability_band()`](https://juancyamin.github.io/cmrdesign/dev/reference/pilot_viability_band.md)

Other rectangle helpers:
[`binary_rectangle_corners()`](https://juancyamin.github.io/cmrdesign/dev/reference/binary_rectangle_corners.md),
[`cmr_multiarm_from_rectangle()`](https://juancyamin.github.io/cmrdesign/dev/reference/cmr_multiarm_from_rectangle.md),
[`cmr_stratified_from_rectangle()`](https://juancyamin.github.io/cmrdesign/dev/reference/cmr_stratified_from_rectangle.md),
[`cmr_unbounded_from_rectangle()`](https://juancyamin.github.io/cmrdesign/dev/reference/cmr_unbounded_from_rectangle.md),
[`folded_binomial_pmf()`](https://juancyamin.github.io/cmrdesign/dev/reference/folded_binomial_pmf.md),
[`multiarm_variance_objective()`](https://juancyamin.github.io/cmrdesign/dev/reference/multiarm_variance_objective.md),
[`rectangle_bernoulli_binary()`](https://juancyamin.github.io/cmrdesign/dev/reference/rectangle_bernoulli_binary.md),
[`rectangle_bounded_two_arm()`](https://juancyamin.github.io/cmrdesign/dev/reference/rectangle_bounded_binary.md),
[`rectangle_multiarm()`](https://juancyamin.github.io/cmrdesign/dev/reference/rectangle_multiarm.md),
[`rectangle_multiple_outcomes()`](https://juancyamin.github.io/cmrdesign/dev/reference/rectangle_multiple_outcomes.md),
[`rectangle_proxy()`](https://juancyamin.github.io/cmrdesign/dev/reference/rectangle_proxy.md),
[`rectangle_stratified()`](https://juancyamin.github.io/cmrdesign/dev/reference/rectangle_stratified.md),
[`rectangle_unbounded()`](https://juancyamin.github.io/cmrdesign/dev/reference/rectangle_unbounded.md),
[`stratified_variance_objective()`](https://juancyamin.github.io/cmrdesign/dev/reference/stratified_variance_objective.md),
[`variance_bounds_bernoulli_exact()`](https://juancyamin.github.io/cmrdesign/dev/reference/variance_bounds_bernoulli_exact.md),
[`variance_bounds_maurer_pontil()`](https://juancyamin.github.io/cmrdesign/dev/reference/variance_bounds_maurer_pontil.md),
[`variance_bounds_unbounded_mom()`](https://juancyamin.github.io/cmrdesign/dev/reference/variance_bounds_unbounded_mom.md)

## Examples

``` r
cmr_plan(n = 3000, sigma1 = 0.18, sigma0 = 0.28, desired_pilot = 120)
#> <cmr_pilot_plan>
#>   n: 3000
#>   method: bounded, accounting: design_only
#>   viability band: 72 to 134 (even sizes)
#>   suggested_pilot: 72
#>   default_two_thirds_power: 210 (above_break_even_cap)
#>   desired_pilot: 120 (inside_viability_band)

d <- rep(c(1, 0), each = 6)
y <- c(1, 0, 1, 1, 0, 1, 0, 0, 1, 0, 0, 1)
rectangle_two_arm(y, d)
#> <cmr_binary_rectangle>
#>   rectangle: v_l1=0.02915, v_u1=0.25, v_l0=0.02915, v_u0=0.25
#>   method: bernoulli
#>   n: 12
#>   joint_error_bound: 0.05
```
