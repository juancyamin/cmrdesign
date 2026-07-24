# Binary Outcomes

This vignette shows how to use CMR when the pilot outcome is binary.
Binary outcomes support the exact folded-binomial variance bounds in
addition to the general bounded-outcome bounds. The outcome should be
coded as `0` and `1` for the exact Bernoulli method.

``` r

knitr::opts_chunk$set(collapse = TRUE, comment = "#>")
library(cmrdesign)
```

## Simulate a binary pilot

``` r

set.seed(202)

n_pilot <- 220
d <- rbinom(n_pilot, size = 1, prob = 0.5)
response_prob <- ifelse(d == 1, 0.38, 0.55)
y <- rbinom(n_pilot, size = 1, prob = response_prob)

table(treatment = d, outcome = y)
#>          outcome
#> treatment  0  1
#>         0 50 55
#>         1 65 50
```

## Exact Bernoulli CMR

For 0/1 outcomes, `method = "auto"` resolves to the exact Bernoulli
variance confidence set.

``` r

fit_auto <- cmr_binary(y, d, method = "auto", alpha = 0.05)

fit_auto$method
#> [1] "bernoulli"
fit_auto$pi
#> [1] 0.497153
round(fit_auto$rectangle, 4)
#>   v_l1   v_u1   v_l0   v_u0 
#> 0.2213 0.2500 0.2318 0.2500
fit_auto$pilot$n
#>  n1  n0 
#> 115 105
```

The exact Bernoulli rectangle is also available explicitly with
`method = "bernoulli"` or `method = "bernoulli_exact"`.

``` r

methods <- c("auto", "bernoulli", "bernoulli_exact", "bounded", "mtr")

comparison <- do.call(rbind, lapply(methods, function(method) {
  fit <- cmr_binary(y, d, method = method, alpha = 0.05)
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
#>                     pi  U_CMR   v_l1 v_u1   v_l0 v_u0
#> auto            0.4972 0.0006 0.2213 0.25 0.2318 0.25
#> bernoulli       0.4972 0.0006 0.2213 0.25 0.2318 0.25
#> bernoulli_exact 0.4972 0.0006 0.2213 0.25 0.2318 0.25
#> bounded         0.5038 0.0812 0.0487 0.25 0.0440 0.25
#> mtr             0.5026 0.0413 0.0905 0.25 0.0856 0.25
```

Use the exact Bernoulli option when the observed outcome is genuinely
binary. Use the bounded-outcome options when the outcome is continuous
or an index already scaled to `[0, 1]`.

As in the other workflows, `$pi` is the main-wave assignment share and
`$U_CMR` is a regret certificate, not a treatment-effect confidence
interval.

## Inspect the folded-binomial sufficient statistic

The exact Bernoulli bounds are functions of the folded count in each
arm.

``` r

fit_auto$confidence_set$treatment$statistic
#> $j
#> [1] 50
#> 
#> $x
#> [1] 50
#> 
#> $m
#> [1] 115
#> 
#> $raw_sample_variance
#> [1] 0.2479024
#> 
#> $beta_l
#> [1] 0.0125
#> 
#> $beta_u
#> [1] 0.0125
fit_auto$confidence_set$control$statistic
#> $j
#> [1] 50
#> 
#> $x
#> [1] 55
#> 
#> $m
#> [1] 105
#> 
#> $raw_sample_variance
#> [1] 0.2518315
#> 
#> $beta_l
#> [1] 0.0125
#> 
#> $beta_u
#> [1] 0.0125
```
