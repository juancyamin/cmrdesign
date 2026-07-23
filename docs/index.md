# cmrdesign Documentation

`cmrdesign` implements Conditional Minimax Regret (CMR) design rules for
pilot-informed experiments in R and Python. The package is focused on applied
implementation: pass pilot data, get a main-wave allocation and a regret
certificate.

The package accompanies
[When and How to Pilot: Design Rules for Two-Wave Experiments](https://arxiv.org/abs/2607.16982)
by Juan C. Yamin.

Start with:

- [Quickstart](quickstart.md) for the shortest two-arm example.
- [Choosing A Method](choosing_methods.md) for `auto`, bounded, Bernoulli, MTR,
  and unbounded confidence rectangles.
- [Methods](methods.md) for the implemented CMR rules and extensions.
- [Pilot Planning](pilot_planning.md) for Appendix E-style pilot/main-wave
  sizing screens.
- [FAQ](faq.md) for input conventions and common edge cases.

Implementation contracts live in `spec/`. Those files are the source of truth
for cross-language API names, return fields, formulas, and numerical tolerances.
