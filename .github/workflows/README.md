# Workflows

GitHub Actions workflows for the public repository:

- `python.yml`: installs the Python package and runs the `unittest` suite.
- `r.yml`: installs R test dependencies and runs `R CMD check`.
- `fixtures.yml`: regenerates shared JSON fixtures, checks for fixture drift,
  and runs cross-language fixture tests in both R and Python.

Documentation build checks can be added once the public documentation site is
chosen.
