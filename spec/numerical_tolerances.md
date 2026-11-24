# Numerical Tolerances

Default tolerances:

- Probability/simplex sum tolerance: `1e-10`.
- Variance endpoint tolerance: `1e-12`.
- Bernoulli endpoint bisection tolerance: `1e-11`.
- CMR binary regret equality tolerance: `1e-10`.
- Multi-arm/stratified optimality gap: `1e-9` times the problem scale, where
  the scale is the larger of one, the largest oracle value, and the largest
  objective at the uniform allocation.
- Multi-arm/stratified directional-violation tolerance: `1e-6`. It is used
  only when the fallback search runs without a dual bound.
- Cross-language closed-form fixture comparison tolerance: `1e-10` to `1e-12`.
- Cross-language variance-bound fixture comparison tolerance: `1e-10` unless
  bisection granularity requires `1e-8`.
- General multi-arm/stratified numerical-solver fixture comparison tolerance:
  case-specific, currently `1e-6` for the asymmetric solver fixtures.

General multi-arm and stratified rectangles are solved by the same barrier
Newton method in R and Python. The method reports a certified optimality gap:
`U_CMR` minus a dual lower bound on the minimax value. Both languages reach
the gap tolerance on the shared fixtures and on randomized checks against an
independent convex solver, and they agree with each other to about `1e-9` in
`U_CMR`. `U_CMR` remains the most stable comparison target. On nearly flat
regret surfaces more than one allocation can be effectively tied, so
element-wise `pi` comparisons keep a looser case-level tolerance.

Fixture tolerances are absolute differences.

All fixture files should include a top-level `tolerance`; individual cases may
override it with their own `tolerance` field.
