# Stratified CMR assignment

Estimate cell-specific variance confidence intervals from pilot data and
return the stratified CMR assignment across treatment/control by stratum
cells.

## Usage

``` r
cmr_stratified(
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
  tol = 1e-11,
  solver_control = list(),
  max_vertices = 65536L
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

- solver_control:

  Optional list of solver controls for general rectangles. `gap_tol` is
  the target optimality gap relative to the problem scale (default
  `1e-9`). `barrier = FALSE` skips the barrier Newton method and uses
  the multi-start search directly. `max_starts`, `smooth_taus`, `maxit`,
  and `mirror_iterations` tune that fallback search.

- max_vertices:

  Maximum number of hyperrectangle vertices to enumerate.

## Value

A list of class `cmr_stratified` with total cell assignment shares `pi`,
matrix form `pi_matrix`, sampling and treatment margins, CMR certificate
`U_CMR`, confidence set, pilot summaries, endpoint error allocation, and
diagnostics.

## See also

Other CMR rules:
[`binary_rectangle_corners()`](https://juancyamin.github.io/cmrdesign/dev/reference/binary_rectangle_corners.md),
[`cmr_multiarm()`](https://juancyamin.github.io/cmrdesign/dev/reference/cmr_multiarm.md),
[`cmr_multiarm_from_rectangle()`](https://juancyamin.github.io/cmrdesign/dev/reference/cmr_multiarm_from_rectangle.md),
[`cmr_multiple_outcomes()`](https://juancyamin.github.io/cmrdesign/dev/reference/cmr_multiple_outcomes.md),
[`cmr_proxy()`](https://juancyamin.github.io/cmrdesign/dev/reference/cmr_proxy.md),
[`cmr_stratified_from_rectangle()`](https://juancyamin.github.io/cmrdesign/dev/reference/cmr_stratified_from_rectangle.md),
[`cmr_two_arm()`](https://juancyamin.github.io/cmrdesign/dev/reference/cmr_two_arm.md),
[`cmr_unbounded()`](https://juancyamin.github.io/cmrdesign/dev/reference/cmr_unbounded.md),
[`cmr_unbounded_from_rectangle()`](https://juancyamin.github.io/cmrdesign/dev/reference/cmr_unbounded_from_rectangle.md),
[`print.cmr_two_arm()`](https://juancyamin.github.io/cmrdesign/dev/reference/print.cmr_two_arm.md)

## Examples

``` r
set.seed(7)
strata <- rep(c("A", "B"), each = 400)
d <- rep(rep(c(1, 0), each = 200), 2)
y <- c(rbeta(200, 0.5, 0.5), rbeta(200, 8, 8),
       rbeta(200, 5, 3), rbeta(200, 3, 5))
fit <- cmr_stratified(y, d, strata, strata_share = c(A = 0.45, B = 0.55))
fit
#> <cmr_stratified>
#>   pi: 1:A=0.3272, 0:A=0.179664, 1:B=0.248631, 0:B=0.244505
#>   U_CMR: 0.14409
#>   method: bounded
#>   n: 800
fit$pi_matrix
#>           A         B
#> 1 0.3271999 0.2486312
#> 0 0.1796643 0.2445046
```
