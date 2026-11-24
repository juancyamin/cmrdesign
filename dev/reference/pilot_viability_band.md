# Pilot viability band

Compute a necessary viability screen for pilot sizes before choosing a
pilot/main-wave split.

## Usage

``` r
pilot_viability_band(
  n,
  sigma1,
  sigma0,
  alpha = 0.05,
  method = c("bounded", "bernoulli"),
  input = c("sd", "variance"),
  accounting = c("design_only", "pooled"),
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

- strict_upper:

  If `FALSE`, the default, a pilot size equal to the design-only
  break-even cap is feasible, as in the viability band of the
  accompanying paper. If `TRUE`, feasible pilot sizes must be strictly
  below the cap.

## Value

A list of class `cmr_pilot_viability_band` with total sample size,
standard deviations, method, break-even share and total, activation
threshold, feasible even pilot sizes, and min/max feasible pilot sizes.
The object has a compact [`print()`](https://rdrr.io/r/base/print.html)
method.

## See also

Other pilot planning:
[`activation_threshold_bounded()`](https://juancyamin.github.io/cmrdesign/dev/reference/activation_threshold_bounded.md),
[`break_even_pilot_share()`](https://juancyamin.github.io/cmrdesign/dev/reference/break_even_pilot_share.md),
[`pilot_plan()`](https://juancyamin.github.io/cmrdesign/dev/reference/pilot_plan.md),
[`print.cmr_pilot_plan()`](https://juancyamin.github.io/cmrdesign/dev/reference/print.cmr_pilot_plan.md)

## Examples

``` r
pilot_viability_band(n = 3000, sigma1 = 0.18, sigma0 = 0.28)
#> <cmr_pilot_viability_band>
#>   n: 3000
#>   method: bounded, accounting: design_only
#>   activation_threshold: 72
#>   break_even_total: 135.379 (share 0.0451264)
#>   feasible pilot sizes: 72 to 134 (32 even sizes)
```
