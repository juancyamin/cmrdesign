# Changelog

`cmrdesign` versions the R and Python packages separately; entries below are
labeled by package.

## Unreleased

- No unreleased user-visible changes.

## Python 0.1.1 (prepared, not yet on PyPI)

- Fixed `cmr_multiarm()` and `rectangle_multiarm()` for treatment arm labels
  that start with "v", such as `"variant_a"` or `"v1"`. They raised a
  `KeyError` in 0.1.0.
- `method="auto"` looks at the raw outcome values in multi-arm and stratified
  designs, as documented. An explicit method is applied to the normalized
  outcome, and a warning is raised when raw 0/1 outcomes make `auto` skip a
  requested normalization.
- `pilot_viability_band()` and `cmr_plan()` default to `strict_upper=False`,
  which reproduces the viability band of the accompanying paper. `cmr_plan()`
  returns `two_thirds_status` and never classifies a pilot as inside an empty
  band.
- General multi-arm and stratified rectangles are solved by a barrier Newton
  method with a certified optimality gap, reported as
  `diagnostics["optimality_gap"]`. `U_CMR` can be slightly smaller than in
  0.1.0, by up to about `3e-5` in relative terms in our checks.
- `regret()`, `variance_objective()`, `oracle_variance()`, and
  `assign_neyman()` gain `scale="nonnegative"`.
- Every public function has a NumPy-style docstring with parameters, returns,
  and, for the main entry points, a runnable example.
- `variance_bounds_martinez_taboada_ramdas()` validates its tuning constants
  and returns them in `statistic`.
- `CMRResult` has a `correction` field. Missing arm and stratum labels given
  as `pandas.NA` are dropped like `None` and NaN.
- Errors raised while processing one arm, cell, or outcome name it.
- The package passes `ruff` and `mypy`, and both run in CI. Python 3.13 is
  tested and declared.

## R 0.1.1 (prepared, not yet on CRAN)

- See `r/NEWS.md` for the full list. In short: fixed `cmr_multiarm()` for arm
  labels that start with "v" and `cmr_stratified()` for stratum labels that
  contain a colon, aligned the default viability band with the paper, added a
  certified solver for multi-arm and stratified rectangles, accepted a scalar
  `beta` in every two-arm workflow, added `scale = "nonnegative"` to the
  diagnostics helpers, and added print methods for plans and rectangles.
- Cross-language fixtures were regenerated and extended with a six-arm
  rectangle, a three-stratum rectangle, and planning cases for
  `strict_upper` and `two_thirds_status`.

## Python 0.1.0 - 2026-08-05

- Promoted the current checked implementation from the `0.1.0a2` alpha line to
  the first non-pre-release Python package version.
- Updated Python metadata, installation instructions, and PyPI project links
  to point users to the package documentation site.
- Kept the PyPI development-status classifier at Beta for the initial public
  Python release while the package continues to collect applied-user feedback.

## R 0.1.0 - 2026-08-05 (CRAN release)

- Published `cmrdesign` 0.1.0 on CRAN.
- Moved the R package version from development-only `0.0.0.9000` to
  CRAN-style `0.1.0`.
- Simplified R package author metadata so `Authors@R` is the single source of
  truth for the package author and maintainer.
- Added a CRAN-readiness audit note recording the local `R CMD check
  --as-cran` result, vignette build status, and remaining expected notes.
- Added R-package `cran-comments.md` to document the initial CRAN submission.
- Added CRAN-style paper references in R metadata, GitHub citation metadata,
  and the root README citation section.
- Added `r/inst/CITATION` and `r/NEWS.md` for R citation and changelog
  workflows.
- Maurer–Pontil bounded-outcome bounds now use the raw Bessel sample variance
  in the finite-sample statistic and project only the returned
  confidence-rectangle endpoints to `[0, 1/4]`.
- `normalize = TRUE` without known `lower` and `upper` now warns that pilot
  min/max normalization is exploratory and does not carry the finite-sample
  bounded-outcome CMR guarantee.
- Added `realize_allocation()` to convert continuous CMR shares into integer
  main-wave counts with deterministic largest-remainder rounding and, when
  possible, a recomputed certificate at the realized shares.
- Hardened `realize_allocation()` validation for named length-one targets,
  fixed stratum counts, zero-count realized arms, and certificate
  recomputation diagnostics.
- Added cross-language allocation fixtures and updated simulated
  examples/vignettes to show integer count realization after computing CMR
  shares.

## Python 0.1.0a2 - 2026-07-24 (pre-release)

- Updated the Python package README so the PyPI project page shows the real
  `pip install cmrdesign==0.1.0a2` command instead of the temporary TestPyPI
  release-testing instructions.

## Python 0.1.0a1 - 2026-07-24 (pre-release candidate)

- Initial R and Python implementations of applied CMR design rules.
- Added two-arm, shared-control multi-arm, stratified, multiple-outcome,
  proxy/delayed-outcome, and Appendix E pilot-planning workflows.
- Added Maurer–Pontil bounded-outcome, exact folded-binomial Bernoulli, and
  Martinez-Taboada–Ramdas confidence rectangles.
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
