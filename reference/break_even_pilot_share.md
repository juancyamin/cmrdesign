# Break-even pilot share

Compute the design-only break-even pilot share implied by treatment and
control standard deviations.

## Usage

``` r
break_even_pilot_share(sigma1, sigma0, input = c("sd", "variance"))
```

## Arguments

- sigma1:

  Treatment-arm standard deviation, or variance when
  `input = "variance"`.

- sigma0:

  Control-arm standard deviation, or variance when `input = "variance"`.

- input:

  Whether `sigma1` and `sigma0` are standard deviations (`"sd"`) or
  variances (`"variance"`).

## Value

Numeric break-even share in `[0, 0.5]`.

## See also

Other pilot planning:
[`activation_threshold_bounded()`](https://juancyamin.github.io/cmrdesign/reference/activation_threshold_bounded.md),
[`pilot_plan()`](https://juancyamin.github.io/cmrdesign/reference/pilot_plan.md),
[`pilot_viability_band()`](https://juancyamin.github.io/cmrdesign/reference/pilot_viability_band.md)

## Examples

``` r
break_even_pilot_share(sigma1 = 0.35, sigma0 = 0.20)
#> [1] 0.06923077
break_even_pilot_share(sigma1 = 0.35^2, sigma0 = 0.20^2, input = "variance")
#> [1] 0.06923077
```
