# Diagnostic metrics for CMR simulations

Small helpers for checking rectangle coverage, certificate validity,
boundary assignment, and realized variance gains in simulation or
validation code.

## Usage

``` r
coverage_indicator(rectangle, truth)

certificate_valid(pi, U, truth, tol = 1e-10)

boundary_indicator(pi, tol = 0)

boundary_rate(pi, tol = 0)

saving_vs_balance(pi, v1, v0)

share_of_oracle_gain(pi, v1, v0, tol = 1e-12)
```

## Arguments

- rectangle:

  Two-arm variance rectangle, either a numeric vector with names `v_l1`,
  `v_u1`, `v_l0`, `v_u0` or a rectangle object returned by a two-arm
  rectangle constructor.

- truth:

  Named true variances, with entries `v1` and `v0`.

- pi:

  Treatment assignment share.

- U:

  CMR certificate to check against realized regret.

- tol:

  Nonnegative numerical tolerance.

- v1:

  Treatment-arm variance.

- v0:

  Control-arm variance.

## Value

`coverage_indicator()`, `certificate_valid()`, and
`boundary_indicator()` return logical values. `boundary_rate()`,
`saving_vs_balance()`, and `share_of_oracle_gain()` return numeric
values.

## Examples

``` r
rect <- c(v_l1 = 0.02, v_u1 = 0.12, v_l0 = 0.01, v_u0 = 0.08)
truth <- c(v1 = 0.09, v0 = 0.04)
fit <- cmr_two_arm_from_rectangle(rect)
coverage_indicator(rect, truth)
#> [1] TRUE
certificate_valid(fit$pi, fit$U_CMR, truth)
#> [1] TRUE
saving_vs_balance(fit$pi, truth["v1"], truth["v0"])
#> [1] 0.03230763
```
