# cmrdesign Documentation

`cmrdesign` implements Conditional Minimax Regret (CMR) design rules for
pilot-informed experiments in R and Python. The package is focused on applied
implementation: pass pilot data, get a main-wave allocation and a regret
certificate.

The methods accompany
[When and How to Pilot: Design Rules for Two-Wave Experiments](https://arxiv.org/abs/2607.16982)
by Juan C. Yamin. This repository is software only: examples use simulated
data, and paper replications or empirical calibration scripts are kept outside
the package.

## Where To Start

| If you want to... | Read... |
| --- | --- |
| Run the smallest two-arm example | [Quickstart](quickstart.md) |
| Decide between bounded, Bernoulli, MTR, and unbounded variance intervals | [Choosing A Method](choosing_methods.md) |
| Understand which CMR extension matches your design | [Methods](methods.md) |
| Plan pilot size before collecting pilot data | [Pilot Planning](pilot_planning.md) |
| Resolve input-format and interpretation questions | [FAQ](faq.md) |
| Prepare a release or audit the package | [Release Checklist](release_checklist.md) |
| Review R CRAN-readiness status | [R CRAN Readiness](cran_readiness.md) |
| Prepare a Python TestPyPI/PyPI upload | [Python Release](python_release.md) |

The R package also includes vignettes for two-arm bounded outcomes, binary
outcomes, multiple outcomes, proxy outcomes, CMR extensions, and pilot
planning.

## Main Applied Functions

| Design | R | Python |
| --- | --- | --- |
| Two arms, bounded or binary outcomes | `cmr_two_arm()` | `cmr_two_arm()` |
| Two arms, raw unbounded outcomes | `cmr_unbounded()` | `cmr_unbounded()` |
| Multiple treatments with one control | `cmr_multiarm()` | `cmr_multiarm()` |
| Known target-population strata | `cmr_stratified()` | `cmr_stratified()` |
| Multiple outcomes per pilot unit | `cmr_multiple_outcomes()` | `cmr_multiple_outcomes()` |
| Proxy or delayed primary outcome | `cmr_proxy()` | `cmr_proxy()` |
| Pilot/main-wave sample-size planning | `cmr_plan()` | `cmr_plan()` |

Implementation contracts live in `spec/`. Those files are the source of truth
for cross-language API names, return fields, formulas, and numerical
tolerances.
