# cmrdesign 0.1.0

## Submission

This is a new submission.

## Test Environments

- Local: R 4.5.0 on macOS Sequoia 15.7.4, aarch64-apple-darwin20.
- GitHub Actions: Ubuntu, macOS, and Windows with R release.
- R-universe: version 0.1.0 fresh-install smoke check on macOS.

Before CRAN submission, also run win-builder on R-devel and R-release and
replace this sentence with the actual win-builder results.

## R CMD Check Results

Local `R CMD check --as-cran` was run on `cmrdesign_0.1.0.tar.gz` after
building vignettes with Pandoc 3.2.

Result: 0 ERRORs, 0 WARNINGs, 2 NOTEs.

## Notes

- `checking CRAN incoming feasibility ... NOTE`

  ```text
  Maintainer: ‘Juan C. Yamin <juan_yamin_silva@brown.edu>’

  New submission
  ```

- `checking HTML version of manual ... NOTE`

  ```text
  Skipping checking HTML validation: 'tidy' doesn't look like recent enough HTML Tidy.
  Please obtain a recent version of HTML Tidy by downloading a binary
  release or compiling the source code from <https://www.html-tidy.org/>.
  ```

  Rd checks, examples, tests, vignettes, and PDF manual checks all completed
  successfully.

## Additional Checks

- Package examples: OK.
- Package vignettes and vignette rebuilds: OK.
- `testthat`: the full testthat suite passes.
- Fresh local source install from `cmrdesign_0.1.0.tar.gz`: OK.
- Fresh local source-install smoke example with simulated two-arm data: OK.
- Reference/provenance validation: OK.
- Shared fixture drift check: OK.
- Fresh R-universe install smoke check for version `0.1.0`: OK.
- Package name availability checked against current CRAN, the CRAN archive, and
  the Bioconductor package index: no existing `cmrdesign` package found.
