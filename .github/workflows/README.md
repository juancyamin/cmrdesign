# Workflows

GitHub Actions workflows for the public repository:

- `python.yml`: installs the Python package and runs the `unittest` suite.
- `r.yml`: installs R test dependencies, checks generated roxygen
  documentation, executes vignette chunks, and runs `R CMD check`.
- `fixtures.yml`: regenerates shared JSON fixtures, checks for fixture drift,
  allowing declared numerical tolerances, and runs cross-language fixture tests
  in both R and Python.
- `validation.yml`: runs reference/provenance checks that are separate from
  generated parity fixtures, including archived MTR values and formula-based
  extension checks.

Full documentation-site build checks can be added once the public documentation
site is chosen.
