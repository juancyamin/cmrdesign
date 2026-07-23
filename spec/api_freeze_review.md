# Public API Review

Date: 2026-07-23

This note records the pre-release review of the CMR-focused public API for the
R and Python implementations. It is not an API freeze or a release
announcement; it is the decision trail for what should be treated as reviewed
before packaging polish, PyPI/CRAN preparation, or formal versioning.

## Scope Reviewed

The freeze review focused on applied, simulation-free implementation of CMR and
its extensions:

- Two-arm bounded outcomes with Maurer-Pontil bounds.
- Exact Bernoulli/binary outcomes.
- Martinez-Taboada-Ramdas bounded-outcome bounds.
- Unbounded finite outcomes with median-of-means variance intervals.
- Multi-arm designs with a shared control.
- Stratified designs.
- Multiple-outcome designs.
- Proxy/delayed-outcome designs.
- Appendix E-style pilot/main-wave planning screens.

## Current Review Status

The public API was rechecked after CI was green on the documentation pass. The
review compared:

- R exports in `r/NAMESPACE`.
- Python public symbols in `python/src/cmrdesign/__init__.py`.
- Applied function names, aliases, and defaults.
- Return-object fields in `spec/return_objects.md`.
- User-facing docs in `README.md` and `docs/`.

Public export drift is now guarded by:

- `r/tests/testthat/test-public-api.R`.
- `python/tests/test_public_api.py`.

## Reviewed Applied Surface

The recommended applied entry points are aligned conceptually across R and
Python:

- `cmr_two_arm()` and `cmr_binary()`.
- `cmr_unbounded()`.
- `cmr_multiarm()`.
- `cmr_stratified()`.
- `cmr_multiple_outcomes()`.
- `cmr_proxy()` and `cmr_delayed_outcome()`.
- `cmr_plan()` and `pilot_plan()`.

The expert rectangle workflow is also part of the stable surface:

- Users may build a confidence rectangle with `rectangle_*()`.
- Users may reproduce the assignment rule from a rectangle with
  `cmr_*_from_rectangle()`.
- This keeps confidence-set construction and minimax-regret optimization
  auditable and separable.

## Input Policy

The applied API should take pilot data vectors or matrices, not precomputed
variance estimates and arm sample sizes. This is the right default for applied
users because the package can own:

- missing-data handling;
- bounded-scale validation and normalization;
- binary-outcome dispatch;
- endpoint error allocation;
- pilot sample-size accounting;
- reproducible audit fields.

Summary-variance workflows are still supported indirectly through expert
rectangle inputs, so advanced users can construct or edit rectangles themselves
without bloating the main API.

## Cross-Language Decisions

R and Python should expose the same conceptual API, with language idioms where
appropriate:

- R uses `na.rm`; Python uses `na_rm`.
- R returns S3 lists with extension fields often at top level.
- Python returns dataclasses with extension fields in `diagnostics` or `extra`.
- R uses `U_CMR`; Python supports `u_cmr` and the compatibility alias `U_CMR`.

Exact byte-for-byte return-object parity is not required. The stable contract is
the conceptual field set described in `return_objects.md`.

## Parity Fixes Applied

The review identified two small Python-side parity gaps, both safe to fix before
freeze:

- Added Python aliases `rectangle_bounded_two_arm` and
  `rectangle_bernoulli_two_arm`, matching the R alias names.
- Added `na_rm` controls to the Python one-arm bounded, MTR, and Bernoulli
  variance-bound helpers. Missing observations are dropped by default and raise
  an error when `na_rm=False`, matching the applied functions and R behavior.

## Secondary Helper Surface

R exports additional documented helpers for baseline comparisons and design
diagnostics, such as balanced allocation, regularized Neyman rules,
boundary/coverage indicators, and oracle-gain summaries. These helpers are
useful, but they are not part of the cross-language CMR contract for the first
public release.

This is intentional. The Python package should stay focused on the CMR applied
workflow unless a secondary helper becomes important enough to promote into the
shared expert API.

## Remaining Pre-Release Checks

Before declaring the API frozen for an initial release branch or tag:

- Run the full R and Python test suites.
- Run fixture drift checks.
- Run the validation scripts.
- Run R vignette chunks and `R CMD check`.
- Re-read examples to confirm all examples use simulated data.
- Confirm README and quickstart examples link to the paper:
  <https://arxiv.org/abs/2607.16982>.
