# Two-Arm Bounded Outcomes

This vignette shows the basic two-arm CMR workflow with a simulated
bounded pilot outcome. The pilot outcome is assumed to have already been
rescaled to the unit interval. The goal is to choose the main-wave
assignment share, not to estimate a treatment effect.

``` r

knitr::opts_chunk$set(collapse = TRUE, comment = "#>")
library(cmrdesign)
```

## Simulate a pilot

The treatment arm has a slightly higher mean and lower variance in this
simulation. CMR uses the pilot only to choose the main-wave treatment
assignment probability.

``` r

set.seed(101)

n_pilot <- 160
d <- rbinom(n_pilot, size = 1, prob = 0.5)
y <- numeric(n_pilot)
y[d == 1] <- rbeta(sum(d == 1), shape1 = 5, shape2 = 3)
y[d == 0] <- rbeta(sum(d == 0), shape1 = 2.2, shape2 = 2.2)

pilot_summary <- aggregate(y, by = list(treatment = d), FUN = function(x) {
  c(mean = mean(x), variance = var(x), n = length(x))
})
pilot_summary
#>   treatment     x.mean x.variance        x.n
#> 1         0  0.5338473  0.0336135 78.0000000
#> 2         1  0.6405866  0.0285648 82.0000000
```

## Compute the CMR assignment

The default bounded-outcome confidence rectangle uses the Maurer–Pontil
empirical variance bounds for outcomes in `[0, 1]`.

``` r

fit_bounded <- cmr_two_arm(y, d, method = "bounded", alpha = 0.05)

fit_bounded$pi
#> [1] 0.498971
round(fit_bounded$rectangle, 4)
#>  v_l1  v_u1  v_l0  v_u0 
#> 0.000 0.248 0.000 0.250
fit_bounded$U_CMR
#> [1] 0.2489731
fit_bounded$binding
#> [1] "both"
```

Here `$pi` is the main-wave probability assigned to treatment. The
rectangle contains lower and upper confidence bounds for the treatment
and control variances. The CMR certificate `$U_CMR` is the worst-case
regret over the two least favorable corners of that rectangle; it is not
a treatment-effect confidence interval.

``` r

fit_bounded$pilot$n
#> n1 n0 
#> 82 78
round(fit_bounded$pilot$vhat, 4)
#>  vhat1  vhat0 
#> 0.0286 0.0336
fit_bounded$joint_error_bound
#> [1] 0.05
```

## Convert the share to integer counts

After choosing a main-wave size, use
[`realize_allocation()`](https://juancyamin.github.io/cmrdesign/reference/realize_allocation.md)
to turn the continuous CMR target share into executable
treatment/control counts. The helper recomputes the certificate at the
rounded shares.

``` r

allocation <- realize_allocation(fit_bounded, n_main = 1000)

allocation$counts
#> treatment   control 
#>       499       501
allocation$shares
#> treatment   control 
#>     0.499     0.501
allocation$realized_U_CMR
#> [1] 0.249002
```

## Compare confidence-set methods

The package exposes the bounded/MP and MTR variance confidence sets
through the same interface. The MTR option implements the
Martinez-Taboada–Ramdas one-sided variance bounds.

``` r

methods <- c("bounded", "mp", "mtr")

comparison <- do.call(rbind, lapply(methods, function(method) {
  fit <- cmr_two_arm(y, d, method = method, alpha = 0.05)
  c(
    pi = fit$pi,
    U_CMR = fit$U_CMR,
    v_l1 = fit$rectangle[["v_l1"]],
    v_u1 = fit$rectangle[["v_u1"]],
    v_l0 = fit$rectangle[["v_l0"]],
    v_u0 = fit$rectangle[["v_u0"]]
  )
}))
rownames(comparison) <- methods

round(comparison, 4)
#>             pi  U_CMR v_l1  v_u1 v_l0   v_u0
#> bounded 0.4990 0.2490    0 0.248    0 0.2500
#> mp      0.4990 0.2490    0 0.248    0 0.2500
#> mtr     0.4909 0.1431    0 0.138    0 0.1484
```

`"bounded"` and `"mp"` are synonyms. In applications, use the method
that matches the confidence set you want to report, and record the
method in the analysis plan.

## Work from a precomputed rectangle

If the rectangle was computed elsewhere, the CMR rule can be applied
directly.

``` r

manual_fit <- cmr_two_arm_from_rectangle(fit_bounded$rectangle)

manual_fit$pi
#> [1] 0.498971
manual_fit$U_CMR
#> [1] 0.2489731
```
