# Methods

CMR chooses the main-wave allocation that minimizes the largest regret over a
confidence set for the unknown outcome variances. The package separates that
workflow into two steps:

1. Build a variance confidence rectangle from pilot data.
2. Solve the CMR assignment rule for that rectangle.

The applied `cmr_*()` functions perform both steps. The `rectangle_*()` and
`cmr_*_from_rectangle()` functions expose the two steps separately for auditing
and replication.

## Two-Arm CMR

`cmr_two_arm(y, d, ...)` returns a treatment share `pi`, a CMR certificate
`U_CMR`, the variance rectangle, and diagnostics. For two arms, the assignment
has a closed form using the lower and upper variance endpoints for treatment
and control.

Aliases `cmr_binary()` and `rectangle_binary()` are provided for binary-outcome
workflows.

## Shared-Control Multi-Arm CMR

`cmr_multiarm(y, arm, control_arm = 0, ...)` allocates across one control arm
and multiple treatment arms. The control arm is weighted by the number of
treatment arms in the objective. Collapsed and full rectangles use closed-form
shortcuts; general rectangles are solved over rectangle vertices with numerical
optimization and a certificate check.

## Stratified CMR

`cmr_stratified(y, d, strata, strata_share, ...)` allocates across
treatment/control cells inside target-population strata. The returned object
includes total sampling shares by stratum and treatment shares within stratum.
Collapsed and full rectangles use closed-form shortcuts; general rectangles are
solved over cell-variance vertices.

## Multiple Outcomes

`cmr_multiple_outcomes(y, d, weights, estimand, ...)` supports two applied
workflows:

- `estimand = "index"` forms a weighted index outcome and then applies the
  ordinary two-arm CMR rule.
- `estimand = "coprimary"` builds a weighted effective two-arm variance
  rectangle from outcome-specific confidence endpoints.

Weights are normalized internally to sum to one.

## Proxy Or Delayed Outcomes

`cmr_proxy(proxy_y, d, zeta, ...)` and `cmr_delayed_outcome()` handle pilot data
that observe a proxy or delayed-primary outcome. The proxy standard-deviation
interval in each arm is widened by the user-supplied bridge constant `zeta`,
clipped to the feasible `[0, 0.5]` standard-deviation range, and squared back
into a variance interval before applying two-arm CMR.

## Confidence Rectangles

Implemented variance rectangles are:

- Maurer-Pontil bounded-outcome bounds: `method = "bounded"` or `"mp"`.
- Exact folded-binomial Bernoulli bounds: `method = "bernoulli"`.
- Martinez-Taboada-Ramdas sequential bounded-outcome bounds:
  `method = "mtr"`.

See `spec/math_spec.md` for formulas and `spec/api_spec.md` for the
cross-language contract.
