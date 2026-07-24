# Pilot/main-wave planning summary

Summarize the pilot-size viability band and a default pilot-size
suggestion.

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
  strict_upper = TRUE
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
  strict_upper = TRUE
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

  If `TRUE`, feasible pilot sizes must be strictly below the design-only
  break-even cap.

## Value

A list of class `cmr_pilot_plan` with `band`, `suggested_pilot`,
`default_two_thirds_power`, `desired_pilot`, `desired_status`, a text
recommendation, and a caveat that the screen is necessary rather than
sufficient.

## See also

Other pilot planning:
[`activation_threshold_bounded()`](https://juancyamin.github.io/cmrdesign/reference/activation_threshold_bounded.md),
[`break_even_pilot_share()`](https://juancyamin.github.io/cmrdesign/reference/break_even_pilot_share.md),
[`pilot_viability_band()`](https://juancyamin.github.io/cmrdesign/reference/pilot_viability_band.md)

## Examples

``` r
cmr_plan(
  n = 3000,
  sigma1 = 0.18,
  sigma0 = 0.28,
  desired_pilot = 120
)
#> $band
#> $n
#> [1] 3000
#> 
#> $sigma
#> $sigma$sigma1
#> [1] 0.18
#> 
#> $sigma$sigma0
#> [1] 0.28
#> 
#> 
#> $alpha
#> [1] 0.05
#> 
#> $method
#> [1] "bounded"
#> 
#> $accounting
#> [1] "design_only"
#> 
#> $break_even_share
#> [1] 0.04512635
#> 
#> $break_even_total
#> [1] 135.3791
#> 
#> $activation_threshold
#> [1] 72
#> 
#> $strict_upper
#> [1] TRUE
#> 
#> $feasible_pilot_sizes
#>  [1]  72  74  76  78  80  82  84  86  88  90  92  94  96  98 100 102 104 106 108
#> [20] 110 112 114 116 118 120 122 124 126 128 130 132 134
#> 
#> $min_feasible
#> [1] 72
#> 
#> $max_feasible
#> [1] 134
#> 
#> $nonempty
#> [1] TRUE
#> 
#> attr(,"class")
#> [1] "cmr_pilot_viability_band" "list"                    
#> 
#> $suggested_pilot
#> [1] 72
#> 
#> $default_two_thirds_power
#> [1] 210
#> 
#> $desired_pilot
#> [1] 120
#> 
#> $desired_status
#> [1] "inside_viability_band"
#> 
#> $recommendation
#> [1] "Candidate pilot sizes lie between 72 and 134 observations, inclusive, on the admissible even grid."
#> 
#> $caveat
#> [1] "The viability band is necessary, not sufficient: a feasible pilot must still move the CMR assignment often enough to repay its sampling cost."
#> 
#> attr(,"class")
#> [1] "cmr_pilot_plan" "list"          
```
