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

- strict_upper:

  If `TRUE`, feasible pilot sizes must be strictly below the design-only
  break-even cap.

## Value

A list of class `cmr_pilot_viability_band` with total sample size,
standard deviations, method, break-even share and total, activation
threshold, feasible even pilot sizes, and min/max feasible pilot sizes.

## See also

Other pilot planning:
[`activation_threshold_bounded()`](https://juancyamin.github.io/cmrdesign/reference/activation_threshold_bounded.md),
[`break_even_pilot_share()`](https://juancyamin.github.io/cmrdesign/reference/break_even_pilot_share.md),
[`pilot_plan()`](https://juancyamin.github.io/cmrdesign/reference/pilot_plan.md)

## Examples

``` r
pilot_viability_band(n = 1000, sigma1 = 0.35, sigma0 = 0.20)
#> $n
#> [1] 1000
#> 
#> $sigma
#> $sigma$sigma1
#> [1] 0.35
#> 
#> $sigma$sigma0
#> [1] 0.2
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
#> [1] 0.06923077
#> 
#> $break_even_total
#> [1] 69.23077
#> 
#> $activation_threshold
#> [1] 72
#> 
#> $strict_upper
#> [1] TRUE
#> 
#> $feasible_pilot_sizes
#> integer(0)
#> 
#> $min_feasible
#> [1] NA
#> 
#> $max_feasible
#> [1] NA
#> 
#> $nonempty
#> [1] FALSE
#> 
#> attr(,"class")
#> [1] "cmr_pilot_viability_band" "list"                    
```
