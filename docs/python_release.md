# Python Release

This page records the Python packaging path for `cmrdesign`. It is for
maintainers preparing TestPyPI or PyPI releases, not for ordinary applied use.

The Python package is currently prepared for the alpha version `0.1.0a1`.
For future releases, make an explicit version decision:

- Keep `0.0.0.9000` only for local/GitHub development builds.
- Use `0.1.0a1` for a first public pre-release.
- Use `0.1.0` only when the API, docs, and validation story are ready for a
  stable initial release.

Uploads to TestPyPI and PyPI are external side effects. Do not upload without
an explicit maintainer decision and a clean CI run for the exact commit being
released.

## Pre-Upload Gate

From the repository root:

```bash
git status --short
git log --oneline -1
PYTHONPATH=python/src python -m unittest discover -s python/tests -v
PYTHONPATH=python/src python spec/scripts/check_fixture_drift.py
PYTHONPATH=python/src python validation/check_reference_values.py
```

Confirm:

- The release commit has green GitHub Actions for Python, R, Fixtures, and
  Validation.
- `python/pyproject.toml`, `r/DESCRIPTION`, `CITATION.cff`, and
  `CHANGELOG.md` agree on the intended release version where applicable.
- The root README and Python README describe installation accurately for the
  release state.
- All examples use simulated data.

## Build And Check

From a clean checkout:

```bash
cd python
python -m pip install -e ".[release]"
python -m build --no-isolation
python -m twine check dist/*
```

Inspect source and wheel contents:

```bash
python -m tarfile -l dist/cmrdesign-*.tar.gz
python -m zipfile -l dist/cmrdesign-*.whl
```

Expected high-level contents:

- `src/cmrdesign/`
- `pyproject.toml`
- `README.md`
- `LICENSE`
- package metadata under `dist-info/` in the wheel

## Clean Wheel Smoke Test

From the repository root, using a temporary virtual environment:

```bash
python -m venv /tmp/cmrdesign-wheel-smoke
/tmp/cmrdesign-wheel-smoke/bin/python -m pip install --upgrade pip
/tmp/cmrdesign-wheel-smoke/bin/python -m pip install python/dist/cmrdesign-*.whl
/tmp/cmrdesign-wheel-smoke/bin/python - <<'PY'
import cmrdesign as cmr

print(cmr.__version__)
fit = cmr.cmr_two_arm(
    [0, 1, 0, 1, 1, 1, 0, 0],
    [1, 1, 1, 1, 0, 0, 0, 0],
    method="bernoulli",
)
print(fit.pi)
print(fit.U_CMR)
PY
```

Also run selected installed-package examples:

```bash
cd python
PYTHONWARNINGS=error /tmp/cmrdesign-wheel-smoke/bin/python ../examples/python/01_two_arm_bounded.py
PYTHONWARNINGS=error /tmp/cmrdesign-wheel-smoke/bin/python ../examples/python/04_multiarm.py
PYTHONWARNINGS=error /tmp/cmrdesign-wheel-smoke/bin/python ../examples/python/05_stratified.py
PYTHONWARNINGS=error /tmp/cmrdesign-wheel-smoke/bin/python ../examples/python/09_unbounded_outcomes.py
```

## TestPyPI Upload

Use a TestPyPI API token. Do not commit tokens or paste them into logs.

```bash
cd python
python -m twine upload --repository testpypi dist/*
```

Verify installation from TestPyPI in a fresh environment. `numpy` is a PyPI
dependency, so include the PyPI extra index:

```bash
python -m venv /tmp/cmrdesign-testpypi-smoke
/tmp/cmrdesign-testpypi-smoke/bin/python -m pip install --upgrade pip
/tmp/cmrdesign-testpypi-smoke/bin/python -m pip install \
  --index-url https://test.pypi.org/simple/ \
  --extra-index-url https://pypi.org/simple \
  cmrdesign==VERSION
/tmp/cmrdesign-testpypi-smoke/bin/python - <<'PY'
import cmrdesign as cmr

print(cmr.__version__)
fit = cmr.cmr_two_arm(
    [0, 1, 0, 1, 1, 1, 0, 0],
    [1, 1, 1, 1, 0, 0, 0, 0],
    method="bernoulli",
)
print(fit)
PY
```

Replace `VERSION` with the exact version uploaded.

## PyPI Upload

Only upload to PyPI after the TestPyPI smoke test succeeds and the maintainer
decides the version is ready for the public index.

```bash
cd python
python -m twine upload dist/*
```

Then verify from a clean environment:

```bash
python -m venv /tmp/cmrdesign-pypi-smoke
/tmp/cmrdesign-pypi-smoke/bin/python -m pip install --upgrade pip
/tmp/cmrdesign-pypi-smoke/bin/python -m pip install cmrdesign==VERSION
/tmp/cmrdesign-pypi-smoke/bin/python - <<'PY'
import cmrdesign as cmr
print(cmr.__version__)
print(cmr.cmr_plan(n=1000, sigma1=0.5, sigma0=0.25)["suggested_pilot"])
PY
```

After PyPI is live, update README installation instructions to distinguish the
stable PyPI install from the GitHub development install.
