# Release Checklist

This checklist is for releases after the initial public package release. The R
package version `0.1.0` was published on CRAN on 2026-08-05. It assumes the API
contract in `spec/api_spec.md` has been reviewed and that package examples
remain simulated-data examples only.

## Release Gate

- Confirm the package version in `python/pyproject.toml`, `r/DESCRIPTION`,
  `CITATION.cff`, `CHANGELOG.md`, and `r/NEWS.md`.
- Confirm the paper link is present in the root README, package metadata, and
  citation file: <https://arxiv.org/abs/2607.16982>.
- Confirm the R package documentation site is configured for
  <https://juancyamin.github.io/cmrdesign/>.
- Confirm the public API review is current:
  `spec/api_review.md`.
- Confirm examples do not depend on paper replication data or simulations.
- For the R CRAN path, confirm the latest audit note:
  `docs/dev/cran_readiness.md`.
- For a future CRAN update, confirm `r/cran-comments.md` reflects the exact
  source tarball and check results being submitted.
- Confirm the four quick starts (root README, `docs/quickstart.md`,
  `r/README.md`, and `python/README.md`) show the same simulated two-arm
  example and the same default method.
- Confirm examples and vignettes show how to turn CMR shares into integer
  counts with `realize_allocation()` without generating randomized assignment
  lists automatically.

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

The shared fixture set should include `allocation.json` so deterministic
integer rounding and realized-certificate recomputation are checked in both R
and Python.

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

Build the R documentation site locally when `pkgdown` is available:

```bash
Rscript -e 'pkgdown::build_site("r", new_process = FALSE, install = FALSE)'
```

## Python Distribution Dry Run

See [Python Release](python_release.md) for the full TestPyPI/PyPI playbook.

Build Python source and wheel distributions from a clean checkout:

```bash
cd python
python -m pip install -e ".[release]"
python -m build --no-isolation
python -m twine check dist/*
```

Inspect the generated artifacts:

```bash
python -m tarfile -l dist/cmrdesign-*.tar.gz
python -m zipfile -l dist/cmrdesign-*.whl
```

Install the built wheel in a clean environment and run at least the package
import, the test suite, and the simulated examples:

```bash
python - <<'PY'
import cmrdesign as cmr
print(cmr.__version__)
PY
python -m unittest discover -s python/tests -v
```

Before uploading, run the simulated examples from the installed wheel with
warnings promoted to errors:

```bash
PYTHONWARNINGS=error python ../examples/python/01_two_arm_bounded.py
PYTHONWARNINGS=error python ../examples/python/04_multiarm.py
PYTHONWARNINGS=error python ../examples/python/05_stratified.py
```

Use TestPyPI before PyPI for each new public release. Uploads are irreversible
for a given version number, so the version should be changed intentionally
before any upload.

## R Release and CRAN Updates

R-universe registry:

- Registry repository:
  <https://github.com/r-universe/juancyamin>.
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

Before a future CRAN submission, run:

```bash
R CMD build r
R CMD check --as-cran cmrdesign_*.tar.gz
```

Use R-universe for development builds between CRAN releases.

## Final Checks

- GitHub Actions should be green for Python, R, Fixtures, and Validation.
- The pkgdown workflow should be green, and GitHub Pages should serve the R
  documentation site from the `gh-pages` branch.
- `git status --short` should be clean after generated artifacts are removed or
  ignored.
- The changelog should describe all user-visible changes since the previous
  release.
- The release tag should point to the exact commit that passed CI.
