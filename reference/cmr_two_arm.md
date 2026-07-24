# Two-arm Conditional Minimax Regret assignment

Estimate a finite-sample variance confidence rectangle from pilot data
and return the two-arm Conditional Minimax Regret (CMR) assignment.

## Usage

``` r
cmr_two_arm(
  y,
  d,
  alpha = 0.05,
  method = c("auto", "bounded", "bernoulli", "maurer_pontil", "mp", "bernoulli_exact",
    "martinez_taboada_ramdas", "mtr", "unbounded", "unbounded_mom", "median_of_means",
    "mom"),
  beta = NULL,
  correction = c("bonferroni", "sidak_arms"),
  normalize = FALSE,
  lower = NULL,
  upper = NULL,
  psi = NULL,
  na.rm = TRUE,
  tol = 1e-11
)

cmr_binary(
  y,
  d,
  alpha = 0.05,
  method = c("auto", "bounded", "bernoulli", "maurer_pontil", "mp", "bernoulli_exact",
    "martinez_taboada_ramdas", "mtr", "unbounded", "unbounded_mom", "median_of_means",
    "mom"),
  beta = NULL,
  correction = c("bonferroni", "sidak_arms"),
  normalize = FALSE,
  lower = NULL,
  upper = NULL,
  psi = NULL,
  na.rm = TRUE,
  tol = 1e-11
)
```

## Arguments

- y:

  Pilot outcomes. For bounded and Bernoulli methods, outcomes must be in
  `[0, 1]` unless `normalize = TRUE`. For unbounded methods, outcomes
  are raw numeric values and `psi` is required.

- d:

  Pilot treatment indicator; treatment is `1` and control is `0`.

- alpha:

  Target joint error level for the variance confidence set.

- method:

  Confidence-set method. `"auto"` uses exact Bernoulli bounds for 0/1
  outcomes and bounded Maurer–Pontil bounds otherwise. `"bounded"`,
  `"maurer_pontil"`, and `"mp"` are synonyms. `"bernoulli"` and
  `"bernoulli_exact"` use folded-binomial exact bounds. `"mtr"` and
  `"martinez_taboada_ramdas"` use the empirical-Bernstein MTR bounds.
  `"unbounded"`, `"unbounded_mom"`, `"median_of_means"`, and `"mom"`
  dispatch to the unbounded-outcome median-of-means extension.

- beta:

  Optional endpoint error allocation. If `NULL`, error is split across
  lower and upper endpoints using `correction`.

- correction:

  Endpoint error correction, either `"bonferroni"` or `"sidak_arms"` for
  two-arm bounded/Bernoulli/proxy workflows.

- normalize:

  If `TRUE`, normalize bounded outcomes to `[0, 1]` before computing the
  rectangle.

- lower, upper:

  Optional lower and upper outcome bounds used when `normalize = TRUE`.

- psi:

  Bounded-kurtosis parameter for unbounded-outcome methods. Provide a
  scalar or a treatment/control pair.

- na.rm:

  If `TRUE`, drop rows with missing `y` or `d`.

- tol:

  Numerical tolerance for exact Bernoulli bound inversion.

## Value

A list of class `cmr_two_arm` with treatment share `pi`, regret
certificate `U_CMR`, confidence rectangle, pilot summaries, endpoint
error allocation, and diagnostics. The object has compact
[`print()`](https://rdrr.io/r/base/print.html) and
[`summary()`](https://rdrr.io/r/base/summary.html) methods.

## See also

Other CMR rules:
[`binary_rectangle_corners()`](https://juancyamin.github.io/cmrdesign/reference/binary_rectangle_corners.md),
[`cmr_multiarm()`](https://juancyamin.github.io/cmrdesign/reference/cmr_multiarm.md),
[`cmr_multiarm_from_rectangle()`](https://juancyamin.github.io/cmrdesign/reference/cmr_multiarm_from_rectangle.md),
[`cmr_multiple_outcomes()`](https://juancyamin.github.io/cmrdesign/reference/cmr_multiple_outcomes.md),
[`cmr_proxy()`](https://juancyamin.github.io/cmrdesign/reference/cmr_proxy.md),
[`cmr_stratified()`](https://juancyamin.github.io/cmrdesign/reference/cmr_stratified.md),
[`cmr_stratified_from_rectangle()`](https://juancyamin.github.io/cmrdesign/reference/cmr_stratified_from_rectangle.md),
[`cmr_unbounded()`](https://juancyamin.github.io/cmrdesign/reference/cmr_unbounded.md),
[`cmr_unbounded_from_rectangle()`](https://juancyamin.github.io/cmrdesign/reference/cmr_unbounded_from_rectangle.md),
[`print.cmr_two_arm()`](https://juancyamin.github.io/cmrdesign/reference/print.cmr_two_arm.md)

## Examples

``` r
set.seed(1)
d <- rep(c(1, 0), each = 40)
y <- c(rbeta(40, 2, 6), rbeta(40, 4, 4))

fit <- cmr_two_arm(y, d, alpha = 0.05, method = "bounded")
fit
#> <cmr_two_arm>
#>   pi: 0.5
#>   U_CMR: 0.25
#>   method: bounded
#>   n: 80
summary(fit)
#> <summary.cmr_two_arm>
#>   pi: 0.5
#>   U_CMR: 0.25
#>   method: bounded
#>   n: 80
```
