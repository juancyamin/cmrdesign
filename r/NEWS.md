# cmrdesign 0.1.0

First CRAN-oriented release of `cmrdesign`.

- Added applied Conditional Minimax Regret rules for two-arm, unbounded
  two-arm, shared-control multi-arm, stratified, multiple-outcome, and proxy
  outcome designs.
- Added pilot/main-wave sample-size planning tools from Appendix E of the
  accompanying paper.
- Added R/Python cross-language fixtures, reference validation, vignettes, and
  compact print/summary methods for core CMR results.
- Added `realize_allocation()` to turn CMR target shares into integer
  main-wave counts and recompute the rounded-design certificate when possible.
- Added allocation cross-language fixtures and vignette/examples coverage for
  integer count realization.
- Hardened `realize_allocation()` input validation for named length-one
  targets, fixed stratum counts, zero-count realized arms, and certificate
  recomputation diagnostics.
- Maurer–Pontil bounded-outcome fits now report the raw Bessel sample variance
  in `vhat` and keep projected unit-interval variances in the method-specific
  `statistic$projected_vhat` field.
- Added explicit warnings when `normalize = TRUE` uses pilot min/max support
  bounds, clarifying that this convenience path is exploratory rather than
  finite-sample guarantee-bearing.
