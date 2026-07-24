# cmrdesign

[![Python](https://github.com/juancyamin/cmrdesign/actions/workflows/python.yml/badge.svg)](https://github.com/juancyamin/cmrdesign/actions/workflows/python.yml)
[![R](https://github.com/juancyamin/cmrdesign/actions/workflows/r.yml/badge.svg)](https://github.com/juancyamin/cmrdesign/actions/workflows/r.yml)
[![pkgdown](https://github.com/juancyamin/cmrdesign/actions/workflows/pkgdown.yml/badge.svg)](https://github.com/juancyamin/cmrdesign/actions/workflows/pkgdown.yml)
[![Fixtures](https://github.com/juancyamin/cmrdesign/actions/workflows/fixtures.yml/badge.svg)](https://github.com/juancyamin/cmrdesign/actions/workflows/fixtures.yml)
[![Validation](https://github.com/juancyamin/cmrdesign/actions/workflows/validation.yml/badge.svg)](https://github.com/juancyamin/cmrdesign/actions/workflows/validation.yml)
[![PyPI](https://img.shields.io/pypi/v/cmrdesign?label=PyPI)](https://pypi.org/project/cmrdesign/)
[![Python versions](https://img.shields.io/pypi/pyversions/cmrdesign)](https://pypi.org/project/cmrdesign/)
[![GitHub release](https://img.shields.io/github/v/release/juancyamin/cmrdesign?include_prereleases&label=GitHub%20release)](https://github.com/juancyamin/cmrdesign/releases)
[![R-universe version](https://juancyamin.r-universe.dev/cmrdesign/badges/version)](https://juancyamin.r-universe.dev/cmrdesign)
[![R-universe checks](https://juancyamin.r-universe.dev/cmrdesign/badges/checks)](https://juancyamin.r-universe.dev/cmrdesign)
[![arXiv](https://img.shields.io/badge/arXiv-2607.16982-b31b1b.svg)](https://arxiv.org/abs/2607.16982)

`cmrdesign` implements Conditional Minimax Regret (CMR) design rules in R and
Python. The package is for applied researchers planning a main experimental
wave after observing pilot data: pass pilot outcomes and assignment labels, get
a recommended main-wave allocation and a worst-case regret certificate.

The methods accompany
[When and How to Pilot: Design Rules for Two-Wave Experiments](https://arxiv.org/abs/2607.16982)
by [Juan C. Yamin](https://juancyamin.github.io/).

Package links:
[documentation site](https://juancyamin.github.io/cmrdesign/),
[PyPI](https://pypi.org/project/cmrdesign/),
[R-universe](https://juancyamin.r-universe.dev/cmrdesign),
[GitHub releases](https://github.com/juancyamin/cmrdesign/releases), and
[paper](https://arxiv.org/abs/2607.16982).

This repository is software only. It does not contain paper replication code,
raw research data, empirical calibration workflows, or paper-specific
simulation output.

## Installation

The R package is available from R-universe. The Python package is available
from PyPI as alpha version `0.1.0a2`; pin the exact version while the API is
pre-release.

R via R-universe:

```r
install.packages(
  "cmrdesign",
  repos = c("https://juancyamin.r-universe.dev", "https://cloud.r-project.org")
)
```

R development version from GitHub:

```r
install.packages("remotes")
remotes::install_github("juancyamin/cmrdesign", subdir = "r")
```

Python alpha from PyPI:

```bash
python -m pip install cmrdesign==0.1.0a2
```

Python development version from GitHub:

```bash
python -m pip install "cmrdesign @ git+https://github.com/juancyamin/cmrdesign.git#subdirectory=python"
```

## Quick Start

In a two-arm design, `y` is one vector of pilot outcomes and `d` marks the arm
for each observation. Here the first 40 observations are treatment and the next
40 are control.

R:

```r
library(cmrdesign)

set.seed(123)
d <- c(rep(1, 40), rep(0, 40))
y <- c(rbeta(40, 2, 5), rbeta(40, 4, 4))

fit <- cmr_two_arm(y, d, alpha = 0.05, method = "auto")
fit$pi
fit$U_CMR
summary(fit)
```

Python:

```python
import numpy as np
import cmrdesign as cmr

rng = np.random.default_rng(123)
d = np.r_[np.ones(40), np.zeros(40)]
y = np.r_[rng.beta(2, 5, 40), rng.beta(4, 4, 40)]

fit = cmr.cmr_two_arm(y, d, alpha=0.05, method="auto")
fit.pi
fit.U_CMR
print(fit)
```

`pi` is the recommended treatment share for the main wave. `U_CMR` is the
certificate: the worst-case regret of that allocation over the estimated
confidence set for arm variances.

## Which Function Should I Use?

| If your design is... | Use... | Main inputs |
| --- | --- | --- |
| One treatment and one control | `cmr_two_arm()` | `y`, `d` |
| Two-arm with raw unbounded outcomes | `cmr_unbounded()` | `y`, `d`, `psi` |
| Several treatments sharing one control | `cmr_multiarm()` | `y`, `arm`, `control_arm` |
| Known strata with possibly different variances | `cmr_stratified()` | `y`, `d`, `strata`, `strata_share` |
| Multiple outcomes per unit | `cmr_multiple_outcomes()` | outcome matrix `y`, `d`, `weights` |
| Proxy or delayed primary outcome | `cmr_proxy()` | `proxy_y`, `d`, bridge constant `zeta` |
| Pilot versus main-wave sample-size planning | `cmr_plan()` | total `n`, pilot SD guesses |

The direct rectangle functions, such as `cmr_two_arm_from_rectangle()` and
`cmr_multiarm_from_rectangle()`, are useful for auditing or teaching. Applied
users will usually pass pilot data directly and let the package estimate the
confidence rectangle.

## Choosing A Confidence Method

| Method | Use when... | Notes |
| --- | --- | --- |
| `method = "auto"` | You want the default applied behavior | Uses exact Bernoulli bounds for raw 0/1 outcomes and bounded-outcome bounds otherwise. |
| `method = "bounded"` or `"mp"` | Outcomes are bounded, usually normalized to `[0, 1]` | Uses Maurer-Pontil variance bounds. |
| `method = "bernoulli"` | Outcomes are truly binary and coded 0/1 | Uses exact folded-binomial variance bounds. |
| `method = "mtr"` | You specifically want Martinez-Taboada-Ramdas bounds | Uses the pilot row order, so do not sort outcomes before calling it. |
| `method = "unbounded"` | Two-arm outcomes are raw finite values rather than bounded-scale values | Requires a kurtosis bound `psi`; use `cmr_unbounded()` for the clearest API. |

For non-unit bounded outcomes, use `normalize = TRUE` in R or `normalize=True`
in Python when the raw scale is known and meaningful. If a binary outcome is
coded as something other than 0/1, recode it to 0/1 or explicitly set
`method = "bernoulli"`.

## Interpreting Results

Most CMR result objects contain:

- `pi`: recommended main-wave allocation. In two-arm designs this is the
  treatment share; in multi-arm or stratified designs it can be a vector or
  matrix of shares.
- `U_CMR`: the worst-case regret certificate over the confidence set.
- `rectangle` or `confidence_set`: the variance uncertainty set used by the
  rule.
- `method`: the confidence-rectangle method actually used after `auto`
  dispatch.
- `diagnostics`: solver and edge-case information, such as whether the
  confidence set collapsed or became a full no-information rectangle.

CMR is a design rule for allocating the next experimental wave. It is not a
treatment-effect estimator, and `U_CMR` is not a treatment-effect confidence
interval.

## Examples And Docs

All examples use simulated data.

- [Quickstart](docs/quickstart.md): shortest two-arm example.
- [R package site](https://juancyamin.github.io/cmrdesign/): R reference pages
  and rendered vignettes.
- [Choosing a method](docs/choosing_methods.md): `auto`, bounded, Bernoulli,
  MTR, and unbounded rules.
- [Methods](docs/methods.md): implementation details and supported extensions.
- [Pilot planning](docs/pilot_planning.md): Appendix E-style pilot/main-wave
  sizing screens.
- [FAQ](docs/faq.md): input conventions and common edge cases.
- [R examples](examples/r) and [Python examples](examples/python): simulated
  examples for each supported design.
- R vignettes in [r/vignettes](r/vignettes): applied tutorials for the core
  two-arm rule, confidence-method variants, extensions, and pilot planning.

## Alpha Feedback

`cmrdesign` is in alpha release. Applied-user feedback is especially useful
before the beta/API freeze:

- [Bug reports](https://github.com/juancyamin/cmrdesign/issues/new?template=bug_report.yml):
  incorrect results, installation failures, solver errors, or R/Python
  inconsistencies.
- [Usage questions](https://github.com/juancyamin/cmrdesign/issues/new?template=usage_question.yml):
  help choosing between CMR functions, confidence methods, or input formats.
- [Alpha feedback](https://github.com/juancyamin/cmrdesign/issues/new?template=alpha_feedback.yml):
  comments on names, return objects, examples, documentation, or applied
  workflow.

Please use simulated, public, or redacted data in GitHub issues.

## For Contributors

`cmrdesign` is pre-release software. The R and Python APIs are intended to be
parallel, and cross-language JSON fixtures check that the two implementations
return the same numerical results on shared cases.

```text
spec/        Shared math/API specs and cross-language fixtures.
validation/  Independent reference and provenance checks.
r/           R package.
python/      Python package.
examples/    Simulated examples in R and Python.
docs/        User-facing documentation.
```
