# Contributing

This project is in pre-release implementation mode. Contributions should keep
the R and Python packages aligned and should update the shared specification
whenever behavior changes.

Implementation contributions should include:

- Focused tests in the affected language.
- Cross-language fixture updates when behavior is part of the public API.
- Documentation or spec updates for changed user-facing behavior.
- A short note on numerical tolerances when a solver path is involved.

For applied-user feedback, please use the GitHub issue forms:

- Bug reports: <https://github.com/juancyamin/cmrdesign/issues/new?template=bug_report.yml>
- Usage questions: <https://github.com/juancyamin/cmrdesign/issues/new?template=usage_question.yml>
- Alpha feedback: <https://github.com/juancyamin/cmrdesign/issues/new?template=alpha_feedback.yml>

Please use simulated, public, or redacted data in issues.

Useful local checks:

```bash
python -m pip install -e python
python -m unittest discover -s python/tests -v
```

from the repository root, and

```bash
Rscript -e 'roxygen2::roxygenise("r")'
git status --short r/NAMESPACE r/man
```

to regenerate R documentation with the `RoxygenNote` version in
`r/DESCRIPTION` and confirm it is committed, then

```bash
R CMD build --no-build-vignettes r
R CMD check --no-manual --ignore-vignettes cmrdesign_*.tar.gz
```

from the repository root. Full vignette checks should be run in an environment
with Pandoc installed.

Generated fixture files in `spec/test_fixtures/` should be deterministic and
easy to inspect. They check R/Python parity; they do not replace independent
statistical validation.

For release preparation, use `docs/dev/release_checklist.md` as the more
complete gate covering metadata, distribution builds, validation checks, and CI
status.
