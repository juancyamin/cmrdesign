# Mathematical Specification

This file states the implementation formulas used by both R and Python.

## Core Two-Arm Quantities

For treatment share `pi`, treatment variance `v1`, and control variance `v0`,
the main-wave variance objective is

```text
V(pi; v1, v0) = v1 / pi + v0 / (1 - pi).
```

The known-variance Neyman assignment is

```text
pi_N(v1, v0) = sqrt(v1) / (sqrt(v1) + sqrt(v0)),
```

with value `1/2` if both variances are zero.

The oracle value is

```text
V*(v1, v0) = (sqrt(v1) + sqrt(v0))^2.
```

Regret is

```text
R(pi; v1, v0) = V(pi; v1, v0) - V*(v1, v0).
```

Equivalently, for interior `pi`,

```text
R(pi; v1, v0)
  = ((1 - pi) sqrt(v1) - pi sqrt(v0))^2 / (pi (1 - pi)).
```

## Two-Arm CMR From A Rectangle

For a variance rectangle

```text
[v_l1, v_u1] x [v_l0, v_u0],
```

the worst regret is attained at the two off-diagonal corners:

```text
(v_u1, v_l0) and (v_l1, v_u0).
```

The closed-form CMR assignment is

```text
pi_CMR = (sqrt(v_u1) + sqrt(v_l1))
       / (sqrt(v_u1) + sqrt(v_l1) + sqrt(v_u0) + sqrt(v_l0)).
```

If all four endpoints are zero, `pi_CMR = 1/2`. The CMR certificate is the
larger of the two off-diagonal regrets at `pi_CMR`.

## Confidence Rectangles

All implemented confidence rectangles are variance rectangles on `[0, 1/4]`.

### Maurer-Pontil Bounded-Outcome Bounds

For bounded observations in `[0, 1]`, sample size `m`, and sample standard
deviation `s_hat`, the one-sided endpoint adjustment is

```text
eta(beta) = sqrt(2 log(1 / beta) / (m - 1)).
```

Endpoints are

```text
L = max(0, s_hat - eta(beta_l))^2,
U = min(1/4, (s_hat + eta(beta_u))^2).
```

If an endpoint error is zero, the corresponding endpoint is conservative:
`L = 0` for lower and `U = 1/4` for upper.

### Martinez-Taboada-Ramdas Bounds

The MTR implementation follows the sequential empirical-Bernstein-style
variance bounds used in the paper code. The public contract is the deterministic
mapping from ordered bounded pilot outcomes and endpoint errors to lower and
upper variance endpoints. Because the calculation is sequential, the order of
the pilot observations is part of the input: use the natural pilot,
randomization, or data-collection order, not an outcome-sorted order. The
constants exposed in the implementation are:

```text
lower_alpha_split = 0.5
c1 = 0.5
c2 = 0.25^2
c3 = 0.25
c4 = 0.5
c5 = 2
cs = FALSE
tilde_cs = TRUE
```

The fixture `bounded_mtr.json` is the regression test for the package's
canonical MTR calculation. It checks R/Python parity, but it is not independent
mathematical validation of the original MTR routine; before journal, CRAN, or
PyPI release, keep a separate provenance check against the paper code or an
archived independent implementation.

### Exact Bernoulli Folded-Binomial Bounds

For Bernoulli outcomes with sample size `m`, success count `x`, and folded count
`j = min(x, m - x)`, the folded sample variance is

```text
j (m - j) / (m (m - 1)).
```

For variance `v`, the smaller Bernoulli success probability with variance `v` is

```text
rho(v) = 2v / (1 + sqrt(1 - 4v)),
```

with `rho(1/4) = 1/2`.

The folded-binomial PMF sums the binomial probabilities of counts `j` and
`m - j`, avoiding double-counting at `j = m/2`. Lower and upper variance
endpoints are obtained by bisection against the folded lower and upper tails.

### Error Budgets

Two-arm equal Bonferroni allocation uses `alpha / 4` for each one-sided endpoint.
Two-arm equal Sidak-by-arm allocation uses

```text
(1 - sqrt(1 - alpha)) / 2
```

for each one-sided endpoint.

For multi-arm, the default endpoint error is `alpha / (2 * number_of_arms)`.
For stratified, it is `alpha / (4 * number_of_strata)`. For co-primary multiple
outcomes, it is `alpha / (4 * number_of_outcomes)`.

## Extensions

### Shared-Control Multi-Arm

For arms including standardized control `"0"` and treatment arms `1, ..., K`,
the weighted objective at allocation vector `pi` is

```text
K v0 / pi0 + sum_k vk / pik.
```

The oracle value at known variances is

```text
(sqrt(K v0) + sum_k sqrt(vk))^2.
```

CMR over a hyperrectangle is solved over the rectangle vertices.

### Stratified

For stratum shares `q_s`, treatment/control cell allocations `pi_{1s}` and
`pi_{0s}`, and variances `v_{1s}`, `v_{0s}`, the weighted objective is

```text
sum_s q_s^2 v_{1s} / pi_{1s}
  + sum_s q_s^2 v_{0s} / pi_{0s}.
```

CMR over a stratified hyperrectangle is solved over the cell-variance vertices.

### Multiple Outcomes

For `estimand = "index"`, the weighted index outcome is formed first and the
ordinary two-arm CMR rule is applied to that index.

For `estimand = "coprimary"`, the implementation constructs an effective
two-arm rectangle by taking the weighted sum of outcome-specific lower and upper
variance endpoints by arm.

### Proxy/Delayed Outcomes

For proxy standard-deviation interval `[s_l, s_u]` and bridge constant `zeta`,
the implied primary-outcome interval is

```text
[max(0, s_l - zeta), min(0.5, s_u + zeta)].
```

The endpoints are squared to form the primary variance interval.

## Appendix E Planning

Bounded-outcome activation threshold: smallest even pilot size with equal arm
sizes such that the Maurer-Pontil upper-radius adjustment is smaller than the
maximum possible sample standard deviation for that arm size.

Bernoulli activation threshold: `4`.

Break-even pilot share for planning standard deviations `sigma1`, `sigma0`:

```text
(sigma1 - sigma0)^2 / (2 (sigma1^2 + sigma0^2)).
```

The design-only viability band keeps even pilot sizes that clear activation and
lie below the break-even total. The pooled accounting option keeps activation
but drops the design-only break-even cap.

Default pilot size:

```text
2 * ceiling(n^(2/3) / 2).
```
