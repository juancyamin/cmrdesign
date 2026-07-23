# Return Objects

Every CMR result should expose enough information for applied auditability while
keeping the first-level object easy to inspect.

## CMR Results

Required conceptual fields:

- `pi`: assignment share or allocation vector.
- `U_CMR` in R and `u_cmr`/`U_CMR` in Python: certified worst-case regret over
  the estimated confidence set.
- `rectangle`: the variance rectangle or hyperrectangle used by the rule.
- `confidence_set`: the rectangle-constructor return object when the result is
  created from pilot data.
- `pilot`: compact pilot summary with sample sizes, pilot variances, method, and
  any normalization metadata.
- `alpha`: family/joint error target.
- `beta`: endpoint error allocation.
- `method`: canonical confidence method.
- `joint_error_bound`: reported bound on joint confidence-set failure.
- `diagnostics`: solver and construction diagnostics.

Python implementation: `CMRResult` is a dataclass with `extra` for
extension-specific audit fields. R implementation: CMR results are S3 lists
with extension-specific entries at top level.

## Rectangle Results

Required conceptual fields:

- `rectangle`: variance endpoints.
- `alpha`.
- `beta`.
- `method`.
- `n`: pilot sample sizes by arm/cell.
- `vhat`: pilot sample variances by arm/cell.
- `joint_error_bound`.
- `diagnostics`.

Two-arm rectangle endpoint names are fixed:

- `v_l1`, `v_u1`: treatment lower/upper variance endpoints.
- `v_l0`, `v_u0`: control lower/upper variance endpoints.

Multi-arm rectangle endpoints are keyed by standardized arm labels. The control
arm is `"0"`.

Stratified rectangles are represented as lower and upper `2 x S` objects with
treatment row `1` and control row `0`, or equivalent named mappings in Python.

## Extension Fields

Multi-arm:

- arm labels.
- vertices and binding vertices for expert audit.
- solver diagnostics.

Stratified:

- cell allocations named `1:<stratum>` and `0:<stratum>`.
- sampling margins by stratum.
- treatment margins by stratum.
- vertices and binding vertices for expert audit.

Multiple outcomes:

- `estimand`: `"index"` or `"coprimary"`.
- normalized outcome `weights`.
- effective two-arm rectangle.
- per-outcome variance bounds for co-primary workflows.

Proxy/delayed outcomes:

- `zeta` bridge constants.
- proxy rectangle.
- widened primary-outcome rectangle.
- bridge assumption text.

Planning:

- activation threshold.
- break-even pilot share and total.
- feasible even pilot sizes.
- minimum and maximum feasible pilot sizes.
- two-thirds-power default.
- desired-pilot status when requested.
- caveat that the screen is necessary, not sufficient.

## Non-Goals For Return Objects

- The main applied functions should not require users to pass summary variances
  or arm counts.
- Solver internals should be visible in diagnostics but should not be part of
  the applied interpretation unless a user opts into expert review.
- Printed output can be improved later without changing the data fields
  specified here.
