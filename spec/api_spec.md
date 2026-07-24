# API Specification

This file is the package contract for the R and Python implementations. It is
written for the initial public release series. Changes to applied function
names, required inputs, return-field names, or default methods should be treated
as breaking unless this file is updated at the same time.

## Design Principles

- Applied users should pass pilot data, not precomputed summary statistics, to
  the main functions.
- Direct rectangle inputs are supported as expert workflows for auditing,
  replication, and teaching.
- R and Python should expose the same conceptual API. Language idioms may differ:
  R uses `na.rm`; Python uses `na_rm`.
- Bounded-outcome variance routines use outcomes on the bounded scale `[0, 1]`.
  For non-unit bounded outcomes, users should set `normalize = TRUE` in R or
  `normalize=True` in Python. When `method = "auto"` and normalization is
  requested, dispatch is based on the raw outcome values before normalization.
- The unbounded-outcome routine uses raw finite numeric outcomes and requires a
  user-supplied kurtosis bound `psi`; it does not use bounded-scale
  normalization.
- Confidence-set construction and CMR assignment are separable: every applied
  `cmr_*()` function should be reproducible from its corresponding
  `rectangle_*()` result.
- Public export and main-signature drift is checked in
  `r/tests/testthat/test-public-api.R` and `python/tests/test_public_api.py`.
  Any export addition, removal, rename, applied argument change, or default
  change should update this specification and those tests together.

## Main Applied Functions

These functions are the recommended entry points.

### `cmr_two_arm(y, d, ...)`

Purpose: pilot-informed treatment share for a two-arm experiment.

Required inputs:

- `y`: pilot outcome vector.
- `d`: pilot assignment indicator, with treatment `1` and control `0`.

Core options:

- `alpha = 0.05`.
- `method = "auto"`.
- `beta = NULL`/`None` for equal endpoint error allocation.
- `correction = "bonferroni"` or `"sidak_arms"`.
- `normalize = FALSE`/`False`, with optional `lower` and `upper`.
- `psi` is required only when `method = "unbounded"`.

Return: treatment share `pi`, CMR certificate `U_CMR`/`u_cmr`, rectangle,
confidence-set details, pilot sample sizes, pilot variances, method, alpha,
beta, and diagnostics.

### `cmr_unbounded(y, d, psi, ...)`

Purpose: two-arm CMR for raw finite outcomes that are not assumed bounded but
have known arm-specific kurtosis bounds.

Required inputs:

- `y`: pilot outcome vector.
- `d`: pilot assignment indicator, with treatment `1` and control `0`.
- `psi`: scalar or treatment/control pair with values at least `1`.

Core options:

- `alpha = 0.05`.
- Missing-data option: `na.rm` in R, `na_rm` in Python.

Return: the same two-arm fields as `cmr_two_arm()`, plus MoM block diagnostics
`rho`, `k`, `b`, and active/fallback status. If the pilot is too small, the
relative radius is at least one, or the MoM variance estimate is zero, the
function returns `pi = 1/2`, `U_CMR = Inf`, `rectangle = NULL`/`None`, and
`no_finite_certificate = TRUE` in diagnostics.

### `cmr_multiarm(y, arm, ...)`

Purpose: pilot-informed allocation across one control arm and two or more
treatment arms with a shared control.

Required inputs:

- `y`: pilot outcome vector.
- `arm`: pilot arm labels.

Core options:

- `control_arm = 0`.
- `alpha`, `method`, `beta`, `normalize`, and missing-data options as above.
- `solver_control` and `max_vertices` for expert numerical control.

Arm convention: the standardized control arm is named `"0"`. If the user passes
a different `control_arm`, it is internally mapped to `"0"`.

Variance objective weights: the control arm has weight equal to the number of
treatment arms; each treatment arm has weight one.

Endpoint error allocation is Bonferroni for multi-arm, stratified, and
co-primary multiple-outcome workflows. The `"sidak_arms"` correction is exposed
only for two-arm and proxy/delayed-outcome workflows.

### `cmr_stratified(y, d, strata, strata_share, ...)`

Purpose: pilot-informed allocation across treatment/control cells within
strata.

Required inputs:

- `y`: pilot outcome vector.
- `d`: treatment indicator.
- `strata`: pilot stratum labels.
- `strata_share`: target-population stratum shares, named whenever possible.

Return: cell allocations named `1:<stratum>` and `0:<stratum>`, plus sampling
margins and treatment margins by stratum.

### `cmr_multiple_outcomes(y, d, weights, estimand, ...)`

Purpose: two-arm CMR when the planning estimand is based on multiple bounded
outcomes.

Required inputs:

- `y`: outcome matrix/data frame with one row per pilot unit and one column per
  outcome.
- `d`: treatment indicator.

Options:

- `weights`: nonnegative outcome weights, normalized internally to sum to one.
- `estimand = "coprimary"` or `"index"`.

`estimand = "index"` first forms the weighted index outcome and then calls the
two-arm rule. `estimand = "coprimary"` constructs a weighted effective
two-arm variance rectangle from outcome-specific endpoint bounds.

### `cmr_proxy(proxy_y, d, zeta, ...)`

Purpose: two-arm CMR when pilot data observe a proxy or delayed-primary outcome
and the target main-wave outcome is linked by an arm-specific standard-deviation
bridge.

Required inputs:

- `proxy_y`: observed proxy outcome.
- `d`: treatment indicator.
- `zeta`: scalar or treatment/control pair satisfying the user-supplied bridge
  assumption `abs(primary_sd - proxy_sd) <= zeta` by arm.

The proxy confidence interval for each arm standard deviation is widened by
`zeta`, clipped to `[0, 0.5]`, and squared back into a variance interval.

Alias: `cmr_delayed_outcome()`.

### `cmr_plan(n, sigma1, sigma0, ...)`

Purpose: Appendix E-style pilot/main-wave planning screen.

Required inputs:

- `n`: total experiment size.
- `sigma1`, `sigma0`: planning standard deviations by treatment and control, or
  variances when `input = "variance"`.

Core options:

- `method = "bounded"` or `"bernoulli"`.
- `accounting = "design_only"` or `"pooled"`.
- `desired_pilot` for status diagnostics.

Return: activation threshold, break-even share, feasible even pilot sizes,
suggested pilot size, two-thirds-power default, desired-pilot status, and a
necessary-not-sufficient caveat.

## Expert Functions

Expert functions are public but should not be presented as the primary applied
workflow.

Python also exposes `CMRResult` and `RectangleResult` as public result
containers. R exposes S3 list classes through returned objects and methods
rather than standalone constructor classes.

### Rectangle Constructors

- `rectangle_two_arm()` / `rectangle_binary()`.
- `rectangle_bounded_binary()` / `rectangle_bounded_two_arm()`.
- `rectangle_bernoulli_binary()` / `rectangle_bernoulli_two_arm()`.
- `rectangle_unbounded()`.
- `rectangle_multiarm()`.
- `rectangle_stratified()`.
- `rectangle_multiple_outcomes()`.
- `rectangle_proxy()` / `rectangle_delayed_outcome()`.

### CMR From Rectangle

- `cmr_two_arm_from_rectangle()` / `cmr_binary_from_rectangle()`.
- `cmr_unbounded_from_rectangle()`.
- `cmr_multiarm_from_rectangle()`.
- `cmr_stratified_from_rectangle()`.

### Variance Bounds

- `variance_bounds_maurer_pontil()`.
- `variance_bounds_martinez_taboada_ramdas()`.
- `variance_bounds_bernoulli_exact()`.
- `variance_bounds_unbounded_mom()`.
- `folded_binomial_pmf()`.
- `folded_binomial_tails()`.

The bounded, MTR, and Bernoulli one-arm variance-bound helpers accept
language-idiomatic missing-data controls (`na.rm` in R and `na_rm` in Python).
They drop missing observations by default and error when that option is false.

### Core Objectives

- Two-arm: `variance_objective()`, `oracle_variance()`, `assign_neyman()`,
  `regret()`.
- Multi-arm: `assign_multiarm_neyman()`, `multiarm_variance_objective()`,
  `multiarm_oracle_variance()`, `multiarm_regret()`,
  `multiarm_rectangle_vertices()`.
- Stratified: `assign_stratified_neyman()`,
  `stratified_variance_objective()`, `stratified_oracle_variance()`,
  `stratified_regret()`, `stratified_rectangle_vertices()`.

## Method Names

Accepted method aliases:

- `"auto"`: exact Bernoulli when raw outcomes are exactly 0/1,
  Maurer-Pontil otherwise. Binary outcomes coded with other labels should be
  recoded to 0/1 or passed with `method = "bernoulli"`.
- `"bounded"`, `"maurer_pontil"`, `"mp"`: Maurer-Pontil bounded-outcome bounds.
- `"bernoulli"`, `"bernoulli_exact"`: exact folded-binomial Bernoulli bounds.
- `"martinez_taboada_ramdas"`, `"mtr"`: MTR bounded-outcome bounds. MTR treats
  pilot observations as an ordered sequence; users should pass the natural
  pilot order, randomization order, or collection order, and should not sort
  observations by outcome.
- `"unbounded"`, `"unbounded_mom"`, `"median_of_means"`, `"mom"`: two-arm
  unbounded-outcome median-of-means bounds. Users must provide `psi`. Pilot
  order matters because consecutive observations within each arm are paired.

Stored canonical method names:

- `"bounded"`.
- `"bernoulli"`.
- `"martinez_taboada_ramdas"`.
- `"unbounded_mom"`.

## Secondary Helper Surface

The initial public release treats the CMR functions, rectangle constructors,
from-rectangle solvers, variance-bound helpers, planning functions, and core
objective functions above as the cross-language contract.

The R package also exports documented secondary helpers for design diagnostics
and baseline comparisons. These remain public in R for the initial release, but
they are not part of the cross-language CMR contract and Python parity is not
required yet.

R-only secondary baseline helpers:

- `assign_balance()`.
- `assign_multiarm_balance()`.
- `assign_stratified_balance()`.
- `assign_feasible_neyman()`.
- `assign_trimmed_neyman()`.
- `assign_additive_regularized_neyman()`.
- `assign_exponential_regularized_neyman()`.

R-only secondary diagnostic helpers:

- `coverage_indicator()`.
- `certificate_valid()`.
- `boundary_indicator()`.
- `boundary_rate()`.
- `saving_vs_balance()`.
- `share_of_oracle_gain()`.

If a secondary helper becomes part of the cross-language contract, it should be
promoted into the expert-function sections above, added to both
implementations, and added to the Python public API test.
