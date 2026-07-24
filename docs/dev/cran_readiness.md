# R CRAN Readiness

Date: 2026-07-24

This note records the CRAN-readiness pass for the R package in `r/`. It is
separate from the Python release path, which remains documented in
`docs/dev/python_release.md`.

## Version Decision

The R package version is now `0.1.0` in `r/DESCRIPTION`. The previous
`0.0.0.9000` version was useful for development and R-universe iteration, but
`R CMD check --as-cran` flags it as a large development-style version.

The Python package remains on its alpha release line, currently `0.1.0a2` on
PyPI. Future synchronized repository tags should make the intended R and Python
release states explicit.

## Local CRAN Check

Full vignette builds require Pandoc on the `PATH`, or discoverable through the
`RSTUDIO_PANDOC` environment variable. Commands run from the repository root:

```bash
Rscript -e 'roxygen2::roxygenise("r")'
R CMD build r
R CMD check --as-cran cmrdesign_0.1.0.tar.gz
```

Result:

- `R CMD build r`: OK, including vignette creation.
- `R CMD check --as-cran`: 0 ERRORs, 0 WARNINGs, 2 NOTEs.
- `testthat`: the full testthat suite passes.
- Examples: OK.
- Vignettes: OK, including rebuild checks.
- PDF manual: OK.

Remaining NOTES:

- `New submission`: expected for an initial CRAN submission.
- Local HTML validation skipped because the installed `tidy` is not recent
  enough. This is a local tooling limitation; it is not a package code, Rd, or
  vignette failure.

## Additional Local Checks

- Fresh local source install from `cmrdesign_0.1.0.tar.gz`: OK.
- Fresh local source-install smoke example with simulated two-arm data: OK.
- R reference/provenance validation: OK.
- Shared fixture drift check: OK.
- Python reference/provenance validation: OK with the bundled Python runtime.
- Package name availability checked against current CRAN, the CRAN archive, and
  the Bioconductor package index: no existing `cmrdesign` package found.
- `r/cran-comments.md` added for the eventual CRAN submission and excluded from
  the built source package via `r/.Rbuildignore`.
- GitHub Actions R matrix on Ubuntu, macOS, and Windows: OK.
- Fresh R-universe install smoke check for version `0.1.0`: OK.

## Package Contents

The R source package contains package code, Rd documentation, vignettes, tests,
and JSON test fixtures under `inst/extdata/test_fixtures`. It does not ship
paper replication data, empirical calibration workflows, or paper-specific
simulation output.

## Remaining Gates

The local and GitHub Actions CRAN-readiness gates are complete. Before an
actual CRAN upload, repeat the build, `R CMD check --as-cran`, and
fresh-install smoke checks if any R package code, documentation, examples,
vignettes, or metadata changes.

Also run the external Windows checks requested in `r/cran-comments.md`
(`devtools::check_win_devel()` and `devtools::check_win_release()`, or an
equivalent rhub check set) and update that file with the exact results.
