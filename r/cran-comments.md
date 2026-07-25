# cmrdesign 0.1.0

## Submission

This is a new submission.

## Test Environments

- Local: R 4.5.0 on macOS Sequoia 15.7.4, aarch64-apple-darwin20.
- GitHub Actions: Ubuntu, macOS, and Windows with R release.
- R-universe: version 0.1.0 fresh-install smoke check on macOS.
- win-builder R-release: R 4.6.1 (2026-06-24 ucrt), Windows Server 2022 x64,
  Status: 1 NOTE.
- win-builder R-devel: R Under development (unstable) (2026-07-24 r90297
  ucrt), Windows Server 2022 x64, Status: 1 NOTE.

## R CMD Check Results

Local `R CMD check --as-cran` was run on `cmrdesign_0.1.0.tar.gz` after
building vignettes with Pandoc available on `PATH`.

Result: 0 ERRORs, 0 WARNINGs, 3 NOTEs in the local restricted-network
environment.

Final win-builder R-release and R-devel checks both returned 0 ERRORs,
0 WARNINGs, and 1 NOTE.

## Notes

- `checking CRAN incoming feasibility ... NOTE`

  ```text
  Maintainer: ‘Juan C. Yamin <juan_yamin_silva@brown.edu>’

  NB: need Internet access to use CRAN incoming checks
  ```

  The local sandbox could not resolve CRAN, Bioconductor, arXiv, GitHub, or
  GitHub Pages hosts. The same package metadata URLs resolve outside the
  sandbox. On win-builder with Internet access, the corresponding incoming
  feasibility note was only:

  ```text
  New submission

  Possibly misspelled words in DESCRIPTION:
    Maurer
    Pontil
    Yamin
  ```

  These are expected for an initial CRAN submission; the listed words are
  author surnames.

- `checking for future file timestamps ... NOTE`

  ```text
  unable to verify current time
  ```

  This is a local environment limitation.

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
- Shared fixture parity tests, including allocation fixtures: OK.
- Shared fixture drift check: OK.
- Fresh R-universe install smoke check for version `0.1.0`: OK.
- Package name availability checked against current CRAN, the CRAN archive, and
  the Bioconductor package index: no existing `cmrdesign` package found.
