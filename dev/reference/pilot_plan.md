# Pilot/main-wave planning summary

Summarize the pilot-size viability band, the smallest viable pilot, and
the pilot size given by the two-thirds-power rule of the accompanying
paper.

## Usage

``` r
pilot_plan(
  n,
  sigma1,
  sigma0,
  alpha = 0.05,
  method = c("bounded", "bernoulli"),
  input = c("sd", "variance"),
  accounting = c("design_only", "pooled"),
  desired_pilot = NULL,
  strict_upper = FALSE
)

cmr_plan(
  n,
  sigma1,
  sigma0,
  alpha = 0.05,
  method = c("bounded", "bernoulli"),
  input = c("sd", "variance"),
  accounting = c("design_only", "pooled"),
  desired_pilot = NULL,
  strict_upper = FALSE
)
```

## Arguments

- n:

  Total experimental sample size across pilot and main wave.

- sigma1:

  Treatment-arm standard deviation, or variance when
  `input = "variance"`.

- sigma0:

  Control-arm standard deviation, or variance when `input = "variance"`.

- alpha:

  Target error level.

- method:

  Planning method, either `"bounded"` or `"bernoulli"`.

- input:

  Whether `sigma1` and `sigma0` are standard deviations (`"sd"`) or
  variances (`"variance"`).

- accounting:

  `"design_only"` applies the break-even pilot-share cap; `"pooled"`
  ignores that cap.

- desired_pilot:

  Optional user-proposed pilot size to classify.

- strict_upper:

  If `FALSE`, the default, a pilot size equal to the design-only
  break-even cap is feasible, as in the viability band of the
  accompanying paper. If `TRUE`, feasible pilot sizes must be strictly
  below the cap.

## Value

A list of class `cmr_pilot_plan` with the following entries.

- `band`:

  The viability band from
  [`pilot_viability_band()`](https://juancyamin.github.io/cmrdesign/dev/reference/pilot_viability_band.md).

- `suggested_pilot`:

  The smallest pilot size in the band, or `0` when the band is empty.
  This is the least costly pilot at which CMR can leave balance. It is a
  floor, not an optimal size.

- `default_two_thirds_power`:

  The pilot size `2 * ceiling(n^(2/3) / 2)` from the two-thirds-power
  rule.

- `two_thirds_status`:

  Where `default_two_thirds_power` falls relative to the band, using the
  same labels as `desired_status`.

- `desired_pilot`, `desired_status`:

  The user-proposed pilot size and its classification:
  `"inside_viability_band"`, `"below_activation_threshold"`,
  `"above_break_even_cap"`, `"outside_budget"`, `"not_admissible_odd"`,
  or `"no_pilot"`.

- `recommendation`, `caveat`:

  Text summaries. The caveat records that the band is necessary rather
  than sufficient.

The object has a compact [`print()`](https://rdrr.io/r/base/print.html)
method.

## See also

Other pilot planning:
[`activation_threshold_bounded()`](https://juancyamin.github.io/cmrdesign/dev/reference/activation_threshold_bounded.md),
[`break_even_pilot_share()`](https://juancyamin.github.io/cmrdesign/dev/reference/break_even_pilot_share.md),
[`pilot_viability_band()`](https://juancyamin.github.io/cmrdesign/dev/reference/pilot_viability_band.md),
[`print.cmr_pilot_plan()`](https://juancyamin.github.io/cmrdesign/dev/reference/print.cmr_pilot_plan.md)

## Examples

``` r
cmr_plan(
  n = 3000,
  sigma1 = 0.18,
  sigma0 = 0.28,
  desired_pilot = 120
)
#> <cmr_pilot_plan>
#>   n: 3000
#>   method: bounded, accounting: design_only
#>   viability band: 72 to 134 (even sizes)
#>   suggested_pilot: 72
#>   default_two_thirds_power: 210 (above_break_even_cap)
#>   desired_pilot: 120 (inside_viability_band)
```
