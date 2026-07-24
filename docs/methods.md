# Methods

CMR chooses the main-wave allocation that minimizes the largest regret over a
confidence set for the unknown outcome variances. The package separates that
workflow into two steps:

1. Build arm, cell, or outcome-specific variance confidence intervals from
   pilot data.
2. Solve the CMR assignment rule for the resulting variance rectangle.

The applied `cmr_*()` functions perform both steps. The `rectangle_*()` and
`cmr_*_from_rectangle()` functions expose the two steps separately for
auditing, teaching, and replication checks.

## Function Map

| Applied design | Function | Main result |
| --- | --- | --- |
| One treatment and one control | `cmr_two_arm(y, d, ...)` | Treatment share `pi` |
| Two-arm raw unbounded outcomes | `cmr_unbounded(y, d, psi, ...)` | Treatment share `pi` |
| Multiple treatments with one shared control | `cmr_multiarm(y, arm, ...)` | Named assignment shares over all arms |
| Known strata in the target population | `cmr_stratified(y, d, strata, strata_share, ...)` | Cell shares, stratum sampling margins, treatment shares within strata |
| Multiple outcomes per unit | `cmr_multiple_outcomes(y, d, weights, estimand, ...)` | Treatment share `pi` for an index or co-primary objective |
| Proxy or delayed primary outcome | `cmr_proxy(proxy_y, d, zeta, ...)` | Treatment share `pi` after bridge widening |
| Pilot/main-wave planning before data collection | `cmr_plan(n, sigma1, sigma0, ...)` | Feasible pilot-size screen and suggested pilot size |

Most result objects include `pi`, `U_CMR`, `rectangle` or `confidence_set`,
`pilot`, `method`, and `diagnostics`. `U_CMR` is a design certificate, not a
treatment-effect confidence interval.

## Two-Arm CMR

`cmr_two_arm(y, d, ...)` returns a treatment share `pi`, a CMR certificate
`U_CMR`, the variance rectangle, and diagnostics. For two arms, the assignment
has a closed form using the lower and upper variance endpoints for treatment
and control.

Aliases `cmr_binary()` and `rectangle_binary()` are provided for binary-outcome
workflows. For raw finite outcomes without a known bound, use
`cmr_unbounded()` or `cmr_two_arm(..., method = "unbounded", psi = ...)`.

## Shared-Control Multi-Arm CMR

`cmr_multiarm(y, arm, control_arm = 0, ...)` allocates across one control arm
and multiple treatment arms. The control arm is weighted by the number of
treatment arms in the objective. Collapsed and full rectangles use closed-form
shortcuts; general rectangles are solved over rectangle vertices with numerical
optimization and a certificate check.

The outcome vector `y` still has one entry per pilot unit. The companion `arm`
vector labels each row's arm. The returned `pi` is a named vector over the
standardized control arm `"0"` and all treatment arms.

## Stratified CMR

`cmr_stratified(y, d, strata, strata_share, ...)` allocates across
treatment/control cells inside target-population strata. The returned object
includes total sampling shares by stratum and treatment shares within stratum.
Collapsed and full rectangles use closed-form shortcuts; general rectangles are
solved over cell-variance vertices.

`strata_share` should describe the target population, not just the realized
pilot composition, unless those are intentionally the same. The returned
`pi_matrix` is often the clearest applied object: rows are treatment/control
and columns are strata.

For general multi-arm and stratified rectangles, the certificate `U_CMR` is the
authoritative cross-language quantity. When the regret surface is nearly flat,
multiple allocations can be essentially tied, so tiny solver differences may
move `pi` more than they move `U_CMR`.

The general vertex method enumerates variance-rectangle vertices, so it is
intended for a modest number of arms or stratified cells. Very large
hyperrectangles can hit the `max_vertices` cap by construction.

## Multiple Outcomes

`cmr_multiple_outcomes(y, d, weights, estimand, ...)` supports two applied
workflows:

- `estimand = "index"` forms a weighted index outcome and then applies the
  ordinary two-arm CMR rule.
- `estimand = "coprimary"` builds a weighted effective two-arm variance
  rectangle from outcome-specific confidence endpoints.

Weights are normalized internally to sum to one.

Here `y` is a matrix or data frame with one row per pilot unit and one column
per outcome. The treatment vector `d` has one entry per row. For co-primary
workflows, the result keeps outcome-specific confidence bounds in
`confidence_set$outcome_bounds` in R and
`confidence_set.extra["outcome_bounds"]` in Python.

## Proxy Or Delayed Outcomes

`cmr_proxy(proxy_y, d, zeta, ...)` and `cmr_delayed_outcome()` handle pilots in
which only a proxy or delayed primary outcome is observed. The proxy
standard-deviation
interval in each arm is widened by the user-supplied bridge constant `zeta`,
clipped to the feasible `[0, 0.5]` standard-deviation range, and squared back
into a variance interval before applying two-arm CMR.

`zeta` is an identifying/design assumption supplied by the researcher. It is
not estimated by the function. The reported rectangle is the widened
primary-outcome rectangle; the original proxy rectangle is kept for audit.

## Unbounded Outcomes

`cmr_unbounded(y, d, psi, ...)` and `cmr_two_arm(..., method = "unbounded",
psi = ...)` implement the two-arm unbounded-outcome extension. This path uses
raw finite numeric outcomes and a user-supplied kurtosis bound `psi >= 1`,
either common across arms or supplied separately for treatment and control.

Within each arm, the function preserves row order, forms consecutive pairs,
computes half squared pair differences, and builds a median-of-means variance
interval. If the pilot is too small for the requested confidence level, the
relative radius is at least one, or the MoM variance estimate is zero, the
function returns balance with no finite certificate.

The unbounded method is not currently implemented for multi-arm, stratified,
multiple-outcome, or proxy designs.

## Pilot Planning

`cmr_plan(n, sigma1, sigma0, ...)` is used before the pilot is collected. It
implements the pilot-size planning screen from Appendix E of the accompanying
paper (Yamin 2026) using planning standard deviations or variances. The output
reports the activation threshold, break-even cap, feasible even pilot sizes, a
default suggested pilot size, and diagnostics for an optional `desired_pilot`.

This is a planning screen, not a guarantee that adaptation will help in every
realized experiment.

## Confidence Rectangles

Implemented variance rectangles are:

- Maurer–Pontil bounded-outcome bounds: `method = "bounded"` or `"mp"`.
- Exact folded-binomial Bernoulli bounds: `method = "bernoulli"`.
- Martinez-Taboada–Ramdas sequential bounded-outcome bounds:
  `method = "mtr"`.
- Unbounded-outcome median-of-means bounds: `method = "unbounded"`, with
  required `psi`.

See [Choosing a Method](choosing_methods.md) for when each interval method is
appropriate.

See `spec/math_spec.md` for formulas and `spec/api_spec.md` for the
cross-language contract.
