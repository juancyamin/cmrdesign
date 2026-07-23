# Test Fixtures

Fixtures in this folder are language-neutral JSON files used by both R and
Python. The R implementation is the current reference writer; both languages
read the resulting files. These fixtures are parity/regression tests, not an
independent proof of the underlying statistical formulas.

Each fixture should define:

- `schema_version`.
- `source`: currently `R reference implementation`.
- `purpose`.
- `tolerance`: default fixture-level absolute tolerance.
- `cases`: named test cases with inputs and expected outputs.

Case inputs should be small, deterministic, and easy to inspect. Case expected
outputs should avoid solver-specific internals unless the tolerance is explicit.

Closed-form two-arm, full-rectangle, collapsed-rectangle, and planning cases
should use tight tolerances. General multi-arm or stratified numerical solver
cases should use explicit case-level tolerances. Current asymmetric solver
fixtures use `1e-6`.
