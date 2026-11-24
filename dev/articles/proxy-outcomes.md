# Proxy Outcomes

This vignette shows the proxy-outcome extension. The pilot observes a
short-run proxy, and the researcher supplies a bridge constant `zeta`
that limits how far the primary-outcome standard deviation can be from
the proxy standard deviation within each arm. The bridge constant is
part of the design assumption, not a quantity estimated by `cmrdesign`.

``` r

knitr::opts_chunk$set(collapse = TRUE, comment = "#>")
library(cmrdesign)
```

## Simulate proxy and primary outcomes

In a real delayed-outcome design, the pilot may only observe the proxy
in time for the main-wave assignment decision. Here the primary outcome
is simulated only so that we can compare the proxy design to an oracle
calculation.

``` r

set.seed(404)

n_pilot <- 200
d <- rbinom(n_pilot, size = 1, prob = 0.5)

primary <- numeric(n_pilot)
primary[d == 1] <- rbeta(sum(d == 1), shape1 = 6, shape2 = 3)
primary[d == 0] <- rbeta(sum(d == 0), shape1 = 3.5, shape2 = 3.5)

proxy_noise <- ifelse(d == 1, 0.06, 0.08) * rnorm(n_pilot)
proxy_y <- pmin(1, pmax(0, primary + proxy_noise))

round(rbind(
  proxy_treatment = c(mean = mean(proxy_y[d == 1]), variance = var(proxy_y[d == 1])),
  proxy_control = c(mean = mean(proxy_y[d == 0]), variance = var(proxy_y[d == 0]))
), 4)
#>                   mean variance
#> proxy_treatment 0.6606   0.0240
#> proxy_control   0.4783   0.0272
```

## Choose a bridge constant

The bridge constant is an assumption, not something estimated by the
package. It can be scalar or arm-specific. Arm-specific values can be
named with `"treatment"` and `"control"`.

``` r

zeta <- c(treatment = 0.04, control = 0.06)
```

## Proxy CMR

``` r

fit_proxy <- cmr_proxy(
  proxy_y = proxy_y,
  d = d,
  zeta = zeta,
  method = "bounded",
  alpha = 0.05
)

fit_proxy$pi
#> [1] 0.4904309
round(fit_proxy$rectangle, 4)
#>   v_l1   v_u1   v_l0   v_u0 
#> 0.0000 0.2316 0.0000 0.2500
fit_proxy$zeta
#>    1    0 
#> 0.04 0.06
fit_proxy$diagnostics$bridge
#> [1] "abs(primary_sd - proxy_sd) <= zeta by arm"
```

The reported rectangle is the widened primary-outcome rectangle. The
proxy rectangle remains available separately.

``` r

round(fit_proxy$confidence_set$bridge$proxy_rectangle, 4)
#>   v_l1   v_u1   v_l0   v_u0 
#> 0.0000 0.1947 0.0000 0.2259
round(fit_proxy$confidence_set$bridge$primary_rectangle, 4)
#>   v_l1   v_u1   v_l0   v_u0 
#> 0.0000 0.2316 0.0000 0.2500
```

## Simulated oracle comparison

The following calculation uses the simulated primary outcome directly.
This is not available at the decision time in a delayed-outcome
application; it is only a diagnostic for this simulated example.

``` r

fit_oracle <- cmr_two_arm(primary, d, method = "bounded")

comparison <- rbind(
  proxy = c(pi = fit_proxy$pi, U_CMR = fit_proxy$U_CMR),
  oracle_primary = c(pi = fit_oracle$pi, U_CMR = fit_oracle$U_CMR)
)

round(comparison, 4)
#>                    pi  U_CMR
#> proxy          0.4904 0.2406
#> oracle_primary 0.4770 0.1982
```
