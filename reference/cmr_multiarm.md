# Shared-control multi-arm CMR assignment

Estimate arm-specific variance confidence intervals from pilot data and
return the shared-control multi-arm CMR assignment.

## Usage

``` r
cmr_multiarm(
  y,
  arm,
  alpha = 0.05,
  method = c("auto", "bounded", "bernoulli", "maurer_pontil", "mp", "bernoulli_exact",
    "martinez_taboada_ramdas", "mtr"),
  beta = NULL,
  control_arm = 0,
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

- arm:

  Pilot arm labels. The control arm is identified by `control_arm` and
  internally standardized to `"0"`.

- alpha:

  Target joint error level.

- method:

  Confidence-set method. `"auto"` chooses exact Bernoulli bounds for 0/1
  outcomes and bounded Maurer–Pontil bounds otherwise.

- beta:

  Optional endpoint error allocation. If `NULL`, Bonferroni error is
  split across all lower and upper arm endpoints.

- control_arm:

  Label identifying the control arm in `arm`.

- normalize:

  If `TRUE`, normalize bounded outcomes to `[0, 1]` before computing
  variances.

- lower, upper:

  Optional lower and upper outcome bounds used when `normalize = TRUE`.

- na.rm:

  If `TRUE`, drop rows with missing `y` or `arm`.

- tol:

  Numerical tolerance for exact Bernoulli bound inversion.

- solver_control:

  Optional list of solver controls for the general vertex epigraph
  solver.

- max_vertices:

  Maximum number of hyperrectangle vertices to enumerate.

## Value

A list of class `cmr_multiarm` with named assignment shares `pi` over
all arms, CMR certificate `U_CMR`, confidence set, pilot summaries,
endpoint error allocation, and diagnostics.

## See also

Other CMR rules:
[`binary_rectangle_corners()`](https://juancyamin.github.io/cmrdesign/reference/binary_rectangle_corners.md),
[`cmr_multiarm_from_rectangle()`](https://juancyamin.github.io/cmrdesign/reference/cmr_multiarm_from_rectangle.md),
[`cmr_multiple_outcomes()`](https://juancyamin.github.io/cmrdesign/reference/cmr_multiple_outcomes.md),
[`cmr_proxy()`](https://juancyamin.github.io/cmrdesign/reference/cmr_proxy.md),
[`cmr_stratified()`](https://juancyamin.github.io/cmrdesign/reference/cmr_stratified.md),
[`cmr_stratified_from_rectangle()`](https://juancyamin.github.io/cmrdesign/reference/cmr_stratified_from_rectangle.md),
[`cmr_two_arm()`](https://juancyamin.github.io/cmrdesign/reference/cmr_two_arm.md),
[`cmr_unbounded()`](https://juancyamin.github.io/cmrdesign/reference/cmr_unbounded.md),
[`cmr_unbounded_from_rectangle()`](https://juancyamin.github.io/cmrdesign/reference/cmr_unbounded_from_rectangle.md),
[`print.cmr_two_arm()`](https://juancyamin.github.io/cmrdesign/reference/print.cmr_two_arm.md)

## Examples

``` r
set.seed(5)
arm <- rep(c(0, 1, 2), each = 20)
y <- c(rbeta(20, 4, 4), rbeta(20, 2, 6), rbeta(20, 5, 3))
cmr_multiarm(y, arm, method = "bounded")
#> <cmr_multiarm>
#>   pi: 0=0.414214, 1=0.292893, 2=0.292893
#>   U_CMR: 0.707107
#>   method: bounded
#>   n: 60
```
