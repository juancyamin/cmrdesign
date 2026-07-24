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

- solver_control:

  Optional list of solver controls for the general vertex epigraph
  solver.

- max_vertices:

  Maximum number of hyperrectangle vertices to enumerate.

## Value

A list of class `cmr_stratified` with total cell assignment shares `pi`,
matrix form `pi_matrix`, sampling and treatment margins, CMR certificate
`U_CMR`, confidence set, pilot summaries, endpoint error allocation, and
diagnostics.

## See also

Other CMR rules:
[`binary_rectangle_corners()`](https://juancyamin.github.io/cmrdesign/reference/binary_rectangle_corners.md),
[`cmr_multiarm()`](https://juancyamin.github.io/cmrdesign/reference/cmr_multiarm.md),
[`cmr_multiarm_from_rectangle()`](https://juancyamin.github.io/cmrdesign/reference/cmr_multiarm_from_rectangle.md),
[`cmr_multiple_outcomes()`](https://juancyamin.github.io/cmrdesign/reference/cmr_multiple_outcomes.md),
[`cmr_proxy()`](https://juancyamin.github.io/cmrdesign/reference/cmr_proxy.md),
[`cmr_stratified_from_rectangle()`](https://juancyamin.github.io/cmrdesign/reference/cmr_stratified_from_rectangle.md),
[`cmr_two_arm()`](https://juancyamin.github.io/cmrdesign/reference/cmr_two_arm.md),
[`cmr_unbounded()`](https://juancyamin.github.io/cmrdesign/reference/cmr_unbounded.md),
[`cmr_unbounded_from_rectangle()`](https://juancyamin.github.io/cmrdesign/reference/cmr_unbounded_from_rectangle.md),
[`print.cmr_two_arm()`](https://juancyamin.github.io/cmrdesign/reference/print.cmr_two_arm.md)

## Examples

``` r
set.seed(7)
strata <- rep(c("A", "B"), each = 40)
d <- rep(rep(c(1, 0), each = 20), 2)
y <- c(rbeta(20, 2, 6), rbeta(20, 4, 4),
       rbeta(20, 5, 3), rbeta(20, 3, 5))
cmr_stratified(y, d, strata, strata_share = c(A = 0.45, B = 0.55))
#> <cmr_stratified>
#>   pi: 1:A=0.225, 0:A=0.225, 1:B=0.275, 0:B=0.275
#>   U_CMR: 0.25
#>   method: bounded
#>   n: 80
```
