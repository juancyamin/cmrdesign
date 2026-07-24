# CMR Extensions

This vignette shows three extension workflows that keep the same applied
pattern: pass simulated pilot outcomes and design labels, inspect the
main-wave allocation, and record the CMR certificate.

``` r

knitr::opts_chunk$set(collapse = TRUE, comment = "#>")
library(cmrdesign)
```

## Shared-control multi-arm designs

Use
[`cmr_multiarm()`](https://juancyamin.github.io/cmrdesign/reference/cmr_multiarm.md)
when the pilot has multiple treatment arms and one shared control group.
The outcome vector `y` has one entry per pilot unit, and `arm` labels
the corresponding arm. The control arm is standardized to `"0"` in the
result.

``` r

set.seed(505)

n_per_arm <- 180
arm <- rep(c(0, 1, 2), each = n_per_arm)
y <- c(
  rbeta(n_per_arm, shape1 = 4, shape2 = 4),
  rbeta(n_per_arm, shape1 = 2.5, shape2 = 6),
  rbeta(n_per_arm, shape1 = 5, shape2 = 3)
)

fit_multi <- cmr_multiarm(y, arm, alpha = 0.05, method = "bounded")

round(fit_multi$pi, 3)
#>     0     1     2 
#> 0.414 0.298 0.288
fit_multi$U_CMR
#> [1] 0.4317102
fit_multi$method
#> [1] "bounded"
fit_multi$pilot$n
#>   0   1   2 
#> 180 180 180
```

The returned `pi` is a named vector of total main-wave assignment shares
across control and all treatment arms.

## Stratified designs

Use
[`cmr_stratified()`](https://juancyamin.github.io/cmrdesign/reference/cmr_stratified.md)
when the main-wave allocation should adapt across known
target-population strata. The `strata_share` input should describe the
target population shares, not only the realized pilot composition.

``` r

set.seed(506)

n_per_cell <- 100
strata <- rep(c("urban", "rural"), each = 2 * n_per_cell)
d <- rep(c(rep(1, n_per_cell), rep(0, n_per_cell)), times = 2)
y <- c(
  rbeta(n_per_cell, shape1 = 2, shape2 = 5),
  rbeta(n_per_cell, shape1 = 4, shape2 = 4),
  rbeta(n_per_cell, shape1 = 3, shape2 = 6),
  rbeta(n_per_cell, shape1 = 5, shape2 = 4)
)
strata_share <- c(urban = 0.55, rural = 0.45)

fit_strata <- cmr_stratified(
  y = y,
  d = d,
  strata = strata,
  strata_share = strata_share,
  alpha = 0.05,
  method = "bounded"
)

round(fit_strata$pi_matrix, 3)
#>   urban rural
#> 1 0.275 0.220
#> 0 0.278 0.227
round(fit_strata$sampling_margin, 3)
#> urban rural 
#> 0.553 0.447
round(fit_strata$treatment_margin, 3)
#> urban rural 
#> 0.498 0.492
fit_strata$U_CMR
#> [1] 0.2281025
```

`pi_matrix` gives the total assignment share for each treatment/control
by stratum cell. `sampling_margin` gives the total sample share assigned
to each stratum, and `treatment_margin` gives the treatment share within
each stratum.

## Raw unbounded outcomes

Use
[`cmr_unbounded()`](https://juancyamin.github.io/cmrdesign/reference/cmr_unbounded.md)
when the two-arm outcome is raw and finite but not assumed to be bounded
on a known scale. This method requires a bounded-kurtosis input `psi`.
It is currently a two-arm extension only.

``` r

set.seed(507)

n_per_arm <- 1500
d <- c(rep(1, n_per_arm), rep(0, n_per_arm))
y <- c(
  0.20 + 1.10 * rt(n_per_arm, df = 8),
  0.00 + 0.70 * rt(n_per_arm, df = 8)
)

fit_unbounded <- cmr_unbounded(
  y = y,
  d = d,
  psi = c(treatment = 6, control = 6),
  alpha = 0.10
)

fit_unbounded$pi
#> [1] 0.6152421
fit_unbounded$U_CMR
#> [1] 0.9331825
fit_unbounded$pilot[c("rho", "b", "active", "status")]
#> $rho
#>      rho1      rho0 
#> 0.6720215 0.6720215 
#> 
#> $b
#> b1 b0 
#> 31 31 
#> 
#> $active
#> [1] TRUE
#> 
#> $status
#> [1] "active"
```

If the median-of-means variance interval is inactive because the pilot
is too small, the relative radius is too large, or the variance estimate
is zero, the function returns the balanced assignment with no finite
certificate. Check `fit_unbounded$pilot$status` before using the result.
