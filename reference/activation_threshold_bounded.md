# Pilot-size activation thresholds

Compute simple method-specific pilot-size activation thresholds for the
Appendix E-style pilot-planning screen.

## Usage

``` r
activation_threshold_bounded(
  alpha = 0.05,
  max_total_pilot = 10000L,
  min_arm_size = 2L
)

activation_threshold_bernoulli(alpha = 0.05)
```

## Arguments

- alpha:

  Target error level.

- max_total_pilot:

  Largest total pilot size to search.

- min_arm_size:

  Minimum pilot observations per arm.

## Value

Total pilot size threshold. `activation_threshold_bounded()` returns
`Inf` if no even pilot size up to `max_total_pilot` clears the
bounded-outcome activation condition. `activation_threshold_bernoulli()`
returns `4`.

## See also

Other pilot planning:
[`break_even_pilot_share()`](https://juancyamin.github.io/cmrdesign/reference/break_even_pilot_share.md),
[`pilot_plan()`](https://juancyamin.github.io/cmrdesign/reference/pilot_plan.md),
[`pilot_viability_band()`](https://juancyamin.github.io/cmrdesign/reference/pilot_viability_band.md)

## Examples

``` r
activation_threshold_bounded(alpha = 0.05, max_total_pilot = 200)
#> [1] 72
activation_threshold_bernoulli(alpha = 0.05)
#> [1] 4
```
