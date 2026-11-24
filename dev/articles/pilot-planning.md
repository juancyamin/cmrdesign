# Pilot Planning

This vignette shows the pilot-planning helpers from Appendix E of the
accompanying paper. These functions are screening tools. They identify
pilot sizes that pass necessary conditions for assignment adaptation to
be worthwhile, before any pilot data are observed. They do not guarantee
that pilot-based CMR will improve every realized experiment.

``` r

knitr::opts_chunk$set(collapse = TRUE, comment = "#>")
library(cmrdesign)
```

## Planning inputs

Suppose the total experimental budget is 3,000 observations. Historical
data or a closely related study suggest that the treatment-arm standard
deviation is about 0.18 and the control-arm standard deviation is about
0.28 on the `[0, 1]` outcome scale.

``` r

n_total <- 3000
sigma1 <- 0.18
sigma0 <- 0.28
alpha <- 0.05
```

## Break-even pilot share

The break-even share is based on the amount of variance imbalance
available for CMR to exploit.

``` r

break_even_pilot_share(sigma1, sigma0)
#> [1] 0.04512635
n_total * break_even_pilot_share(sigma1, sigma0)
#> [1] 135.3791
```

If the two standard deviations are nearly identical, the break-even
share is near zero and a positive pilot is hard to justify on
assignment-design grounds.

## Activation thresholds

For bounded outcomes, very small pilots may not move the confidence
rectangle away from the full `[0, 0.25]` variance range. The activation
threshold is the smallest even total pilot size that clears this screen.

``` r

activation_threshold_bounded(alpha = alpha, max_total_pilot = n_total - 2)
#> [1] 72
activation_threshold_bernoulli(alpha = alpha)
#> [1] 4
```

Binary outcomes have a separate exact-Bernoulli activation screen.

## Viability band

The viability band combines the activation screen with the break-even
cap.

``` r

band <- pilot_viability_band(
  n = n_total,
  sigma1 = sigma1,
  sigma0 = sigma0,
  alpha = alpha,
  method = "bounded"
)

band$nonempty
#> [1] TRUE
band$min_feasible
#> [1] 72
band$max_feasible
#> [1] 134
length(band$feasible_pilot_sizes)
#> [1] 32
```

The returned object keeps the full admissible even grid for audit.

``` r

head(band$feasible_pilot_sizes)
#> [1] 72 74 76 78 80 82
tail(band$feasible_pilot_sizes)
#> [1] 124 126 128 130 132 134
```

## Check a desired pilot size

[`cmr_plan()`](https://juancyamin.github.io/cmrdesign/dev/reference/pilot_plan.md)
reports whether a proposed pilot size lies inside the necessary
viability band. It also returns the smallest size in the band and the
size given by the two-thirds-power rule of the paper.

``` r

plan <- cmr_plan(
  n = n_total,
  sigma1 = sigma1,
  sigma0 = sigma0,
  alpha = alpha,
  method = "bounded",
  desired_pilot = 120
)

plan
#> <cmr_pilot_plan>
#>   n: 3000
#>   method: bounded, accounting: design_only
#>   viability band: 72 to 134 (even sizes)
#>   suggested_pilot: 72
#>   default_two_thirds_power: 210 (above_break_even_cap)
#>   desired_pilot: 120 (inside_viability_band)
plan$recommendation
#> [1] "Candidate pilot sizes lie between 72 and 134 observations, inclusive, on the admissible even grid."
plan$caveat
#> [1] "The viability band is necessary, not sufficient: a feasible pilot must still move the CMR assignment often enough to repay its sampling cost."
```

`suggested_pilot` is the smallest viable pilot. It is a floor, not an
optimal size. The two-thirds-power size is the worst-case-optimal scale
of the pilot, and `two_thirds_status` says where it falls relative to
the band. Here it is above the design-only break-even cap, which means a
pilot of that size cannot repay its cost at these planning values unless
its observations also enter the final estimate.

``` r

plan$default_two_thirds_power
#> [1] 210
plan$two_thirds_status
#> [1] "above_break_even_cap"
```

The same calculation can be run with variance inputs instead of standard
deviation inputs.

``` r

plan_from_variances <- cmr_plan(
  n = n_total,
  sigma1 = sigma1^2,
  sigma0 = sigma0^2,
  input = "variance",
  alpha = alpha,
  method = "bounded",
  desired_pilot = 120
)

plan_from_variances$desired_status
#> [1] "inside_viability_band"
plan_from_variances$suggested_pilot
#> [1] 72
```

For applications where all observations are eventually pooled into the
final analysis, use `accounting = "pooled"` to omit the design-only
break-even cap.

``` r

pooled_plan <- cmr_plan(
  n = n_total,
  sigma1 = sigma1,
  sigma0 = sigma0,
  alpha = alpha,
  method = "bounded",
  accounting = "pooled",
  desired_pilot = 400
)

pooled_plan$desired_status
#> [1] "inside_viability_band"
pooled_plan$two_thirds_status
#> [1] "inside_viability_band"
pooled_plan$band$min_feasible
#> [1] 72
pooled_plan$band$max_feasible
#> [1] 2998
```
