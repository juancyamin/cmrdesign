# Validation And Provenance Checks

This directory is separate from `spec/test_fixtures/` on purpose.

`spec/test_fixtures/` checks R/Python parity. Those fixtures are generated from
the R implementation and then consumed by both languages. They are excellent
regression tests, but they do not independently validate the statistical
formulas.

The scripts here check selected package outputs against reference calculations
that are not regenerated from the package implementation:

- closed-form two-arm CMR from the mathematical formula;
- MTR variance-bound values copied from the archived old implementation
  regression test in the parent replication package;
- exact Bernoulli folded-binomial formulas;
- collapsed shared-control multi-arm and stratified reductions to known
  Neyman allocations;
- multiple-outcome co-primary rectangle construction from independent
  Maurer-Pontil endpoint calculations;
- proxy bridge widening from the standard-deviation bridge formula;
- Appendix E pilot-planning formulas and threshold values.

These checks are deliberately small and deterministic. They are not paper
simulations, Monte Carlo evidence, or a replacement for the proofs in the paper.
Their job is to protect implementation provenance before a public release.

## How To Run

From the repository root:

```sh
R CMD INSTALL r
Rscript validation/check_reference_values.R
PYTHONPATH=python/src python3 validation/check_reference_values.py
```

GitHub Actions runs the same checks in the `Validation` workflow.

## MTR Provenance

The frozen MTR reference values come from the earlier package/regression code in
the parent replication workspace, specifically the old test named:

```text
Martinez-Taboada-Ramdas bounds match old implementation regression
```

The reference case uses:

```text
y = rep(seq(0.05, 0.95, by = 0.10), 50)
beta_l = beta_u = 0.0125
```

and the archived expected endpoints:

```text
L = 0.04690604657062841
U = 0.10320241415971833
upper_center = 0.08352562992913529
alpha_lower_variance = 0.00625
alpha_lower_mean = 0.00625
```

This is a provenance/regression check against the archived implementation used
during package extraction. It should be kept in addition to, not instead of,
future checks against any newly archived paper-code release.
