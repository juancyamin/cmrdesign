# Shared Specification

The `spec/` directory is the contract between the R and Python packages.

It should be updated before or alongside any implementation change that affects:

- Mathematical formulas.
- Supported confidence-rectangle methods.
- Function inputs.
- Return object fields.
- Edge-case conventions.
- Numerical tolerances.
- Cross-language fixture expectations.
- Public exports in R or Python.

The reviewed public API surface is guarded by:

- `r/tests/testthat/test-public-api.R`
- `python/tests/test_public_api.py`
