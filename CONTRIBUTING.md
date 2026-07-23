# Contributing

This project is in pre-release implementation mode. Contributions should keep
the R and Python packages aligned and should update the shared specification
whenever behavior changes.

Implementation contributions should include:

- Focused tests in the affected language.
- Cross-language fixture updates when behavior is part of the public API.
- Documentation or spec updates for changed user-facing behavior.
- A short note on numerical tolerances when a solver path is involved.

Useful local checks:

```bash
PYTHONPATH=src python -m unittest discover -s tests -v
```

from `python/`, and

```bash
R CMD build --no-build-vignettes r
R CMD check --no-manual --ignore-vignettes cmrdesign_*.tar.gz
```

from the repository root. Full vignette checks should be run in an environment
with Pandoc installed.

Generated fixture files in `spec/test_fixtures/` should be deterministic and
easy to inspect. They check R/Python parity; they do not replace independent
statistical validation.
