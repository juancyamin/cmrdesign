# cmrdesign 0.1.0

## Submission

This is a new submission.

## Test Environments

- Local: R 4.5.0 on macOS Sequoia 15.7.4, aarch64-apple-darwin20.
- GitHub Actions: macOS, Windows, and Ubuntu runners for package tests.
- R-universe: version 0.1.0 fresh-install smoke check on macOS.

## R CMD Check Results

Local `R CMD check --as-cran` was run on `cmrdesign_0.1.0.tar.gz` after
building vignettes with Pandoc 3.2 from the local RStudio bundle.

Result: 0 ERRORs, 0 WARNINGs, 2 NOTEs.

## Notes

- `New submission`: expected for the initial CRAN submission.
- Local HTML validation was skipped because the installed `tidy` was not recent
  enough. Rd checks, examples, tests, vignettes, and PDF manual checks all
  completed successfully.

## Additional Checks

- Package examples: OK.
- Package vignettes and vignette rebuilds: OK.
- `testthat`: 688 passing tests.
- Fresh local source install from `cmrdesign_0.1.0.tar.gz`: OK.
- Fresh local source-install smoke example with simulated two-arm data: OK.
- Reference/provenance validation: OK.
- Shared fixture drift check: OK.
- Fresh R-universe install smoke check for version `0.1.0`: OK.
- Package name availability checked against current CRAN, the CRAN archive, and
  the Bioconductor package index: no existing `cmrdesign` package found.
