# Numerical Tolerances

Default tolerances:

- Probability/simplex sum tolerance: `1e-10`.
- Variance endpoint tolerance: `1e-12`.
- Bernoulli endpoint bisection tolerance: `1e-11`.
- CMR binary regret equality tolerance: `1e-10`.
- Multi-arm/stratified directional-violation tolerance: `1e-6`.
- Cross-language closed-form fixture comparison tolerance: `1e-10` to `1e-12`.
- Cross-language variance-bound fixture comparison tolerance: `1e-10` unless
  bisection granularity requires `1e-8`.
- General multi-arm/stratified numerical-solver fixture comparison tolerance:
  case-specific, currently `1e-6` for the asymmetric solver fixtures.

All fixture files should include a top-level `tolerance`; individual cases may
override it with their own `tolerance` field.
