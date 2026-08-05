# Changelog

`cmrdesign` versions the R and Python packages separately; entries below are
labeled by package.

## Unreleased

- No unreleased user-visible changes.

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
