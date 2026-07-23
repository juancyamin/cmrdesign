# cmrdesign Documentation

`cmrdesign` implements Conditional Minimax Regret (CMR) design rules for
pilot-informed experiments in R and Python. The package is focused on applied
implementation: pass pilot data, get a main-wave allocation and a regret
certificate.

Start with:

- [Quickstart](quickstart.md) for the shortest two-arm example.
- [Choosing A Method](choosing_methods.md) for `auto`, bounded, Bernoulli, and
  MTR confidence rectangles.
- [Methods](methods.md) for the implemented CMR rules and extensions.
- [Pilot Planning](pilot_planning.md) for Appendix E-style pilot/main-wave
  sizing screens.
- [FAQ](faq.md) for input conventions and common edge cases.

Implementation contracts live in `spec/`. Those files are the source of truth
for cross-language API names, return fields, formulas, and numerical tolerances.
