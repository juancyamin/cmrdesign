# cmrdesign

[![Python](https://github.com/juancyamin/cmrdesign/actions/workflows/python.yml/badge.svg)](https://github.com/juancyamin/cmrdesign/actions/workflows/python.yml)
[![R](https://github.com/juancyamin/cmrdesign/actions/workflows/r.yml/badge.svg)](https://github.com/juancyamin/cmrdesign/actions/workflows/r.yml)
[![Fixtures](https://github.com/juancyamin/cmrdesign/actions/workflows/fixtures.yml/badge.svg)](https://github.com/juancyamin/cmrdesign/actions/workflows/fixtures.yml)
[![Validation](https://github.com/juancyamin/cmrdesign/actions/workflows/validation.yml/badge.svg)](https://github.com/juancyamin/cmrdesign/actions/workflows/validation.yml)

`cmrdesign` provides R and Python implementations of Conditional Minimax
Regret (CMR) design rules for applied researchers.

The repository is intentionally scoped to software implementation only. It will
not contain paper replication scripts, empirical calibration workflows, raw
research data, simulation tables, or paper-specific figures.

The methods are developed in
[When and How to Pilot: Design Rules for Two-Wave Experiments](https://arxiv.org/abs/2607.16982)
by Juan C. Yamin.

## Goals

- Provide applied functions that take pilot data and return CMR allocations.
- Support two-arm, shared-control multi-arm, stratified, multiple-outcome, and
  proxy/delayed-outcome designs.
- Include bounded-outcome Maurer-Pontil, Martinez-Taboada-Ramdas (MTR), exact
  Bernoulli folded-binomial, and two-arm unbounded-outcome confidence
  rectangles.
- Include Appendix E-style pilot planning tools for activation thresholds,
  break-even screens, and pilot/main-wave sizing diagnostics.
- Keep R and Python implementations aligned through a shared mathematical and
  API specification plus cross-language fixtures.

## Installation

The package is currently distributed from GitHub while the API is still in the
pre-release `0.0.0.9000` series.

R via R-universe, after the first R-universe build completes:

```r
install.packages(
  "cmrdesign",
  repos = c("https://juancyamin.r-universe.dev", "https://cloud.r-project.org")
)
```

R development version from GitHub:

```r
install.packages("remotes")
remotes::install_github("juancyamin/cmrdesign", subdir = "r")
```

Python:

```bash
python -m pip install "cmrdesign @ git+https://github.com/juancyamin/cmrdesign.git#subdirectory=python"
```

## Current User API

R:

```r
cmr_two_arm(y, d, alpha = 0.05, method = "auto")
cmr_unbounded(y, d, psi, alpha = 0.05)
cmr_multiarm(y, arm, control_arm = 0, alpha = 0.05, method = "auto")
cmr_stratified(y, d, strata, strata_share, alpha = 0.05, method = "auto")
cmr_multiple_outcomes(y, d, weights, estimand = "coprimary", alpha = 0.05)
cmr_proxy(proxy_y, d, zeta, alpha = 0.05, method = "auto")
cmr_plan(n, sigma1, sigma0, alpha = 0.05, method = "bounded")
```

Python:

```python
cmr_two_arm(y, d, alpha=0.05, method="auto")
cmr_unbounded(y, d, psi, alpha=0.05)
cmr_multiarm(y, arm, control_arm=0, alpha=0.05, method="auto")
cmr_stratified(y, d, strata, strata_share, alpha=0.05, method="auto")
cmr_multiple_outcomes(y, d, weights, estimand="coprimary", alpha=0.05)
cmr_proxy(proxy_y, d, zeta, alpha=0.05, method="auto")
cmr_plan(n, sigma1, sigma0, alpha=0.05, method="bounded")
```

## Status

The package currently includes:

- R reference implementation with deterministic `testthat` coverage.
- Python implementation with standard-library `unittest` coverage.
- Simulated examples for the main two-arm rule, MTR, Bernoulli outcomes,
  unbounded outcomes, multi-arm designs, stratified designs, multiple outcomes,
  proxy outcomes, and pilot planning.
- Shared specs and numeric JSON fixtures used by both R and Python to check
  cross-language parity.
- Separate validation/provenance checks for formula-based cases, extension
  identities, Appendix E planning, and archived MTR reference values.
- Closed-form shortcuts for two-arm, collapsed multi-arm/stratified rectangles,
  and full no-information rectangles, plus numerical solvers for general
  multi-arm and stratified rectangles.

## Roadmap

1. Keep GitHub Actions green for R, Python, cross-language fixtures, and
   validation/provenance checks.
2. Expand user-facing docs and vignettes around input conventions and inference
   caveats.
3. Keep expanding independent validation against any newly archived paper-code
   release, especially for MTR.
4. Monitor the first R-universe build, then prepare TestPyPI/PyPI and
   eventually CRAN releases.

## Repository Layout

```text
spec/      Shared math/API specs and cross-language fixtures.
validation/ Reference/provenance checks separate from parity fixtures.
r/         R package.
python/    Python package.
examples/  Simulated examples in R and Python.
docs/      User-facing documentation.
```
