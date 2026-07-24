# Multiple Outcomes

This vignette shows the CMR extensions for multiple bounded outcomes.
Outcomes can be combined into a weighted index or protected as coprimary
outcomes. The outcome object `y` is a matrix with one row per pilot unit
and one column per outcome.

``` r

knitr::opts_chunk$set(collapse = TRUE, comment = "#>")
library(cmrdesign)
```

## Simulate a pilot with two outcomes

The simulated pilot has a test-score outcome and an attendance outcome,
both scaled to `[0, 1]`.

``` r

set.seed(303)

n_pilot <- 180
d <- rbinom(n_pilot, size = 1, prob = 0.5)

test_score <- numeric(n_pilot)
attendance <- numeric(n_pilot)

test_score[d == 1] <- rbeta(sum(d == 1), shape1 = 5.5, shape2 = 3.5)
test_score[d == 0] <- rbeta(sum(d == 0), shape1 = 4, shape2 = 4)

attendance[d == 1] <- rbeta(sum(d == 1), shape1 = 7, shape2 = 2.5)
attendance[d == 0] <- rbeta(sum(d == 0), shape1 = 5, shape2 = 3.5)

y <- cbind(test_score = test_score, attendance = attendance)
weights <- c(test_score = 0.7, attendance = 0.3)

by_arm_mean <- rbind(
  treatment = colMeans(y[d == 1, , drop = FALSE]),
  control = colMeans(y[d == 0, , drop = FALSE])
)
round(by_arm_mean, 3)
#>           test_score attendance
#> treatment      0.627      0.728
#> control        0.492      0.568
```

## Weighted-index CMR

With `estimand = "index"`, the package forms the weighted index first
and then constructs the two-arm confidence rectangle for that index.

``` r

fit_index <- cmr_multiple_outcomes(
  y = y,
  d = d,
  weights = weights,
  estimand = "index",
  method = "bounded"
)

fit_index$pi
#> [1] 0.4693132
round(fit_index$rectangle, 4)
#>   v_l1   v_u1   v_l0   v_u0 
#> 0.0000 0.1725 0.0000 0.2206
fit_index$estimand
#> [1] "index"
fit_index$weights
#> test_score attendance 
#>        0.7        0.3
```

This is the natural option when the main estimand is a prespecified
index.

## Coprimary-outcome CMR

With `estimand = "coprimary"`, the package builds outcome-by-arm
confidence bounds and combines them into an effective two-arm variance
rectangle using the prespecified weights.

``` r

fit_coprimary <- cmr_multiple_outcomes(
  y = y,
  d = d,
  weights = weights,
  estimand = "coprimary",
  method = "bounded"
)

fit_coprimary$pi
#> [1] 0.484048
round(fit_coprimary$rectangle, 4)
#> v_l1 v_u1 v_l0 v_u0 
#> 0.00 0.22 0.00 0.25
fit_coprimary$joint_error_bound
#> [1] 0.05
```

The outcome-specific pieces remain available for audit.

``` r

names(fit_coprimary$confidence_set$outcome_bounds)
#> [1] "test_score" "attendance"
round(fit_coprimary$confidence_set$outcome_vhat$treatment, 4)
#> [1] 0.0231 0.0184
round(fit_coprimary$confidence_set$outcome_vhat$control, 4)
#> [1] 0.0308 0.0216
```

## Compare index and coprimary designs

``` r

comparison <- rbind(
  index = c(pi = fit_index$pi, U_CMR = fit_index$U_CMR),
  coprimary = c(pi = fit_coprimary$pi, U_CMR = fit_coprimary$U_CMR)
)

round(comparison, 4)
#>               pi  U_CMR
#> index     0.4693 0.1951
#> coprimary 0.4840 0.2345
```

The two designs need not agree because they place different requirements
on the pilot confidence set.
