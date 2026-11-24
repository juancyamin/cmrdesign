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

  Named stratum population shares that sum to one. Names must match the
  labels in `strata`. An unnamed vector is matched to strata in their
  order of first appearance in the pilot, so naming the shares is safer.

- alpha:

  Target joint error level.

- method:

  Confidence-set method. `"auto"` chooses exact Bernoulli bounds for 0/1
  outcomes and bounded Maurer–Pontil bounds otherwise.

- beta:

  Optional endpoint error allocation. If `NULL`, Bonferroni error is
  split across all lower and upper treatment/control by stratum
  endpoints.

- normalize:

  If `TRUE`, normalize bounded outcomes to `[0, 1]` before computing
  variances. For guarantee-bearing bounded CMR on a non-unit scale,
  provide known `lower` and `upper` bounds. With `method = "auto"` and
  raw 0/1 outcomes, exact Bernoulli bounds are used on the raw scale and
  normalization is skipped.

- lower, upper:

  Optional lower and upper outcome bounds used when `normalize = TRUE`.
  If either is omitted, the pilot minimum and/or maximum is used with a
  warning; that data-dependent normalization is exploratory and does not
  carry the finite-sample bounded-outcome CMR guarantee.

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
[`binary_rectangle_corners()`](https://juancyamin.github.io/cmrdesign/dev/reference/binary_rectangle_corners.md),
[`cmr_multiarm_from_rectangle()`](https://juancyamin.github.io/cmrdesign/dev/reference/cmr_multiarm_from_rectangle.md),
[`cmr_stratified_from_rectangle()`](https://juancyamin.github.io/cmrdesign/dev/reference/cmr_stratified_from_rectangle.md),
[`cmr_unbounded_from_rectangle()`](https://juancyamin.github.io/cmrdesign/dev/reference/cmr_unbounded_from_rectangle.md),
[`folded_binomial_pmf()`](https://juancyamin.github.io/cmrdesign/dev/reference/folded_binomial_pmf.md),
[`multiarm_variance_objective()`](https://juancyamin.github.io/cmrdesign/dev/reference/multiarm_variance_objective.md),
[`print.cmr_pilot_plan()`](https://juancyamin.github.io/cmrdesign/dev/reference/print.cmr_pilot_plan.md),
[`rectangle_bernoulli_binary()`](https://juancyamin.github.io/cmrdesign/dev/reference/rectangle_bernoulli_binary.md),
[`rectangle_bounded_two_arm()`](https://juancyamin.github.io/cmrdesign/dev/reference/rectangle_bounded_binary.md),
[`rectangle_multiarm()`](https://juancyamin.github.io/cmrdesign/dev/reference/rectangle_multiarm.md),
[`rectangle_multiple_outcomes()`](https://juancyamin.github.io/cmrdesign/dev/reference/rectangle_multiple_outcomes.md),
[`rectangle_proxy()`](https://juancyamin.github.io/cmrdesign/dev/reference/rectangle_proxy.md),
[`rectangle_unbounded()`](https://juancyamin.github.io/cmrdesign/dev/reference/rectangle_unbounded.md),
[`stratified_variance_objective()`](https://juancyamin.github.io/cmrdesign/dev/reference/stratified_variance_objective.md),
[`variance_bounds_bernoulli_exact()`](https://juancyamin.github.io/cmrdesign/dev/reference/variance_bounds_bernoulli_exact.md),
[`variance_bounds_maurer_pontil()`](https://juancyamin.github.io/cmrdesign/dev/reference/variance_bounds_maurer_pontil.md),
[`variance_bounds_unbounded_mom()`](https://juancyamin.github.io/cmrdesign/dev/reference/variance_bounds_unbounded_mom.md)

## Examples

``` r
set.seed(8)
strata <- rep(c("A", "B"), each = 24)
d <- rep(rep(c(1, 0), each = 12), 2)
y <- c(rbeta(12, 2, 6), rbeta(12, 4, 4),
       rbeta(12, 5, 3), rbeta(12, 3, 5))
rectangle_stratified(y, d, strata, strata_share = c(A = 0.45, B = 0.55))
#> <cmr_stratified_rectangle>
#>   lower: 1:A=0, 0:A=0, 1:B=0, 0:B=0
#>   upper: 1:A=0.25, 0:A=0.25, 1:B=0.25, 0:B=0.25
#>   method: bounded
#>   n: 48
#>   joint_error_bound: 0.05
```
