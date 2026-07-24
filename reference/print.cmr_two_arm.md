# Print and summarize CMR results

Compact display methods for CMR result objects. These methods show the
allocation, CMR certificate, method, sample size, and status without
dumping nested confidence-set internals.

## Usage

``` r
# S3 method for class 'cmr_two_arm'
print(x, ...)

# S3 method for class 'cmr_unbounded'
print(x, ...)

# S3 method for class 'cmr_proxy'
print(x, ...)

# S3 method for class 'cmr_multiple_outcomes'
print(x, ...)

# S3 method for class 'cmr_multiarm'
print(x, ...)

# S3 method for class 'cmr_stratified'
print(x, ...)

# S3 method for class 'cmr_two_arm'
summary(object, ...)

# S3 method for class 'cmr_unbounded'
summary(object, ...)

# S3 method for class 'cmr_proxy'
summary(object, ...)

# S3 method for class 'cmr_multiple_outcomes'
summary(object, ...)

# S3 method for class 'cmr_multiarm'
summary(object, ...)

# S3 method for class 'cmr_stratified'
summary(object, ...)

# S3 method for class 'summary.cmr_result'
print(x, ...)
```

## Arguments

- x, object:

  A CMR result object or summary object.

- ...:

  Reserved for future extensions.

## Value

[`print()`](https://rdrr.io/r/base/print.html) methods return the
original object invisibly.
[`summary()`](https://rdrr.io/r/base/summary.html) methods return a
compact list of class `summary.cmr_result`.

## See also

Other CMR rules:
[`binary_rectangle_corners()`](https://juancyamin.github.io/cmrdesign/reference/binary_rectangle_corners.md),
[`cmr_multiarm()`](https://juancyamin.github.io/cmrdesign/reference/cmr_multiarm.md),
[`cmr_multiarm_from_rectangle()`](https://juancyamin.github.io/cmrdesign/reference/cmr_multiarm_from_rectangle.md),
[`cmr_multiple_outcomes()`](https://juancyamin.github.io/cmrdesign/reference/cmr_multiple_outcomes.md),
[`cmr_proxy()`](https://juancyamin.github.io/cmrdesign/reference/cmr_proxy.md),
[`cmr_stratified()`](https://juancyamin.github.io/cmrdesign/reference/cmr_stratified.md),
[`cmr_stratified_from_rectangle()`](https://juancyamin.github.io/cmrdesign/reference/cmr_stratified_from_rectangle.md),
[`cmr_two_arm()`](https://juancyamin.github.io/cmrdesign/reference/cmr_two_arm.md),
[`cmr_unbounded()`](https://juancyamin.github.io/cmrdesign/reference/cmr_unbounded.md),
[`cmr_unbounded_from_rectangle()`](https://juancyamin.github.io/cmrdesign/reference/cmr_unbounded_from_rectangle.md)

## Examples

``` r
set.seed(13)
d <- rep(c(1, 0), each = 20)
y <- c(rbeta(20, 2, 6), rbeta(20, 4, 4))
fit <- cmr_two_arm(y, d)
print(fit)
#> <cmr_two_arm>
#>   pi: 0.5
#>   U_CMR: 0.25
#>   method: bounded
#>   n: 40
summary(fit)
#> <summary.cmr_two_arm>
#>   pi: 0.5
#>   U_CMR: 0.25
#>   method: bounded
#>   n: 40
```
