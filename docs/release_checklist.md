# Release Checklist

This checklist is for preparing the implementation repository for an initial
public package release. It assumes the API contract in `spec/api_spec.md` has
been reviewed and that package examples remain simulated-data examples only.

## Pre-Release Gate

- Confirm the package version in `python/pyproject.toml`, `r/DESCRIPTION`,
  `CITATION.cff`, and `CHANGELOG.md`.
- Confirm the paper link is present in the root README, package metadata, and
  citation file: <https://arxiv.org/abs/2607.16982>.
- Confirm the API freeze review is current:
  `spec/api_freeze_review.md`.
- Confirm examples do not depend on paper replication data or simulations.

## Local Checks

Run Python tests from the repository root:

```bash
PYTHONPATH=python/src python3 -m unittest discover -s python/tests -v
```

Run fixture and validation checks:

```bash
PYTHONPATH=python/src python3 spec/scripts/check_fixture_drift.py
PYTHONPATH=python/src python3 validation/check_reference_values.py
R CMD INSTALL r
Rscript -e 'pkgload::load_all("r"); testthat::test_dir("r/tests/testthat")'
Rscript validation/check_reference_values.R
```

Regenerate and check R documentation with the roxygen version recorded in
`r/DESCRIPTION`:

```bash
Rscript -e 'roxygen2::roxygenise("r")'
git status --short r/NAMESPACE r/man
```

Run R package checks:

```bash
R CMD build --no-build-vignettes r
R CMD check --no-manual --ignore-vignettes cmrdesign_*.tar.gz
```

Full release checks should also run vignette chunks in an environment with
Pandoc installed.

## Python Distribution Dry Run

Build Python source and wheel distributions:

```bash
cd python
python -m pip install build twine
python -m build
python -m twine check dist/*
```

Install the built wheel in a clean environment and run at least:

```bash
python -m unittest discover -s python/tests -v
python - <<'PY'
import cmrdesign as cmr
print(cmr.__version__)
PY
```

Before uploading, run the simulated examples from the installed wheel with
warnings promoted to errors:

```bash
PYTHONWARNINGS=error python ../examples/python/01_two_arm_bounded.py
PYTHONWARNINGS=error python ../examples/python/04_multiarm.py
PYTHONWARNINGS=error python ../examples/python/05_stratified.py
```

Use TestPyPI before PyPI for the first public upload.

## R Release Dry Run

R-universe registry:

- Registry repository:
  <https://github.com/juancyamin/juancyamin.r-universe.dev>.
- Manifest entry:
  `{"package":"cmrdesign","url":"https://github.com/juancyamin/cmrdesign","subdir":"r"}`.
- Confirm the R-universe GitHub App is installed for `juancyamin`. R-universe
  recommends installing it on all repositories; selected repositories should at
  least include `cmrdesign` and `juancyamin.r-universe.dev`.
- Wait for the package to appear at <https://juancyamin.r-universe.dev>, then
  test installation from a clean R session:

```r
install.packages(
  "cmrdesign",
  repos = c("https://juancyamin.r-universe.dev", "https://cloud.r-project.org")
)
```

Before CRAN submission, run:

```bash
R CMD build r
R CMD check --as-cran cmrdesign_*.tar.gz
```

Also consider an R-universe release before CRAN so applied users can install
binary builds while the API is still in pre-release.

## Final Checks

- GitHub Actions should be green for Python, R, Fixtures, and Validation.
- `git status --short` should be clean after generated artifacts are removed or
  ignored.
- The changelog should describe all user-visible changes since the previous
  release.
- The release tag should point to the exact commit that passed CI.
