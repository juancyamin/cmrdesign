# R CRAN Release Record

Published: 2026-08-05

This note records the initial CRAN release of the R package in `r/`. It is
separate from the Python release path documented in `docs/dev/python_release.md`.

## Published Version

`cmrdesign` version `0.1.0` was submitted on 2026-07-25 and published on CRAN
on 2026-08-05. The previous `0.0.0.9000` version was useful for development and
R-universe iteration, but `R CMD check --as-cran` flags it as a large
development-style version.

The paired Python `0.1.0` release is documented separately in
`docs/dev/python_release.md`.

## Pre-Submission Checks

Full vignette builds require Pandoc on the `PATH`, or discoverable through the
`RSTUDIO_PANDOC` environment variable. Commands run from the repository root:

```bash
Rscript -e 'roxygen2::roxygenise("r")'
R CMD build r
PATH="/Applications/RStudio.app/Contents/Resources/app/quarto/bin/tools/aarch64:$PATH" \
  RSTUDIO_PANDOC=/Applications/RStudio.app/Contents/Resources/app/quarto/bin/tools/aarch64 \
  R CMD check --as-cran cmrdesign_0.1.0.tar.gz
```

Result:

- `R CMD build r`: OK, including vignette creation.
- `R CMD check --as-cran`: 0 ERRORs, 0 WARNINGs, 3 NOTEs in the local
  restricted-network environment.
- `testthat`: the full testthat suite passes.
- Examples: OK.
- Vignettes: OK, including rebuild checks.
- PDF manual: OK.

Remaining NOTES:

- CRAN incoming and URL checks need Internet access. In the local sandbox,
  CRAN, Bioconductor, arXiv, GitHub, and GitHub Pages hosts could not be
  resolved.
- Future file timestamp verification could not confirm the current time in the
  local environment.
- Local HTML validation skipped because the installed `tidy` is not recent
  enough. This is a local tooling limitation; it is not a package code, Rd, or
  vignette failure.

## Additional Local Checks

- Fresh local source install from `cmrdesign_0.1.0.tar.gz`: OK.
- Fresh local source-install smoke example with simulated two-arm data: OK.
- R reference/provenance validation: OK.
- Shared fixture parity tests, including allocation fixtures: OK.
- The fixture drift script compares generated fixture files to `HEAD`; rerun it
  after the Phase E fixture additions are committed.
- Python reference/provenance validation: OK with the bundled Python runtime.
- Package name availability checked against current CRAN, the CRAN archive, and
  the Bioconductor package index: no existing `cmrdesign` package found.
- `r/cran-comments.md` recorded the exact initial-submission check environment
  and is excluded from the built source package via `r/.Rbuildignore`.
- GitHub Actions R matrix on Ubuntu, macOS, and Windows: OK.
- Fresh R-universe install smoke check for version `0.1.0`: OK.

## Package Contents

The R source package contains package code, Rd documentation, vignettes, tests,
and JSON test fixtures under `inst/extdata/test_fixtures`. It does not ship
paper replication data, empirical calibration workflows, or paper-specific
simulation output.

## CRAN Publication Result

The CRAN source package is available at
<https://CRAN.R-project.org/package=cmrdesign>. CRAN's public check matrix is
currently clean for version `0.1.0`.

The final win-builder R-release and R-devel checks each returned 0 ERRORs,
0 WARNINGs, and 1 expected incoming-feasibility NOTE for a new submission and
the surnames Maurer, Pontil, and Yamin.

## Future R Releases

For any future CRAN update, repeat the build, `R CMD check --as-cran`, fresh
install, GitHub Actions, and external Windows checks if R package code,
documentation, examples, vignettes, or metadata changed. Update
`r/cran-comments.md` for the exact source tarball being submitted.
