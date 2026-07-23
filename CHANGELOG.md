# Changelog

## 0.1.0a1 (Python pre-release candidate)

- Initial R and Python implementations of applied CMR design rules.
- Added two-arm, shared-control multi-arm, stratified, multiple-outcome,
  proxy/delayed-outcome, and Appendix E pilot-planning workflows.
- Added Maurer-Pontil bounded-outcome, exact folded-binomial Bernoulli, and
  Martinez-Taboada-Ramdas confidence rectangles.
- Added two-arm unbounded-outcome median-of-means confidence rectangles with
  bounded-kurtosis input `psi`.
- Added numeric cross-language JSON fixtures generated from the R reference
  implementation and read by both R and Python tests.
- Added closed-form shortcuts for collapsed and full multi-arm/stratified
  rectangles.
- Improved Python general multi-arm/stratified optimization parity using
  smooth-max and direct-search refinement, with asymmetric solver fixtures.
- Documented raw-scale `method = "auto"` dispatch before normalization and MTR
  row-order sensitivity.
- Added roxygen-generated R help pages with runnable examples and a CI drift
  check for generated R documentation.
- Fixed R proxy and two-arm rectangle wrappers so default `method` choices are
  resolved before forwarding.
- Added Python two-arm rectangle aliases and missing-data controls for expert
  one-arm variance-bound helpers.
- Added API-freeze notes, release-readiness metadata, and a release checklist.
- Added a Python package license file so wheels include license metadata.
- Suppressed expected internal NumPy floating-point warnings from multi-arm and
  stratified solver trial evaluations.
- Added the R-universe registry and install instructions for the R package.
- Added a Python TestPyPI/PyPI release playbook and release optional
  dependencies.
