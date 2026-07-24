# cmrdesign

`cmrdesign` implements Conditional Minimax Regret (CMR) design rules for
pilot-informed experiments in R. Pass pilot outcomes and assignment labels, get
a recommended main-wave allocation and a worst-case regret certificate.

The methods accompany
[When and How to Pilot: Design Rules for Two-Wave Experiments](https://arxiv.org/abs/2607.16982)
by [Juan C. Yamin](https://juancyamin.github.io/).

## Installation

Install the R package from R-universe:

```r
install.packages(
  "cmrdesign",
  repos = c("https://juancyamin.r-universe.dev", "https://cloud.r-project.org")
)
```

Or install the development version from GitHub:

```r
install.packages("remotes")
remotes::install_github("juancyamin/cmrdesign", subdir = "r")
```

## Quick Start

In a two-arm design, `y` is one vector of pilot outcomes and `d` marks the arm
for each observation. Here the first 40 observations are treatment and the next
40 are control.

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

`pi` is the recommended treatment share for the main wave. `U_CMR` is the
worst-case regret certificate over the confidence set for arm variances.

## Which Function Should I Use?

| If your design is... | Use... |
| --- | --- |
| One treatment and one control | `cmr_two_arm()` |
| Two arms with raw unbounded outcomes | `cmr_unbounded()` |
| Several treatments sharing one control | `cmr_multiarm()` |
| Known strata with possibly different variances | `cmr_stratified()` |
| Multiple outcomes per unit | `cmr_multiple_outcomes()` |
| Proxy or delayed primary outcome | `cmr_proxy()` |
| Pilot versus main-wave sample-size planning | `cmr_plan()` |

The direct rectangle functions, such as `cmr_two_arm_from_rectangle()` and
`cmr_multiarm_from_rectangle()`, are useful for auditing or teaching. Applied
users will usually pass pilot data directly and let the package estimate the
confidence rectangle.

## Choosing a Confidence Method

| Method | Use when... |
| --- | --- |
| `method = "auto"` | Use the default applied behavior. It chooses exact Bernoulli bounds for raw 0/1 outcomes and bounded-outcome bounds otherwise. |
| `method = "bounded"` or `"mp"` | Outcomes are bounded, usually normalized to `[0, 1]`. |
| `method = "bernoulli"` | Outcomes are truly binary and coded 0/1. |
| `method = "mtr"` | You specifically want Martinez-Taboada–Ramdas bounds. The rule uses pilot row order, so do not sort outcomes before calling it. |
| `method = "unbounded"` | Two-arm outcomes are raw finite values rather than bounded-scale values. Use `cmr_unbounded()` and supply a kurtosis bound `psi`. |

CMR is a design rule for allocating the next experimental wave. It is not a
treatment-effect estimator, and `U_CMR` is not a treatment-effect confidence
interval.

## Python Package

The companion Python package is available on
[PyPI](https://pypi.org/project/cmrdesign/).

## Feedback

`cmrdesign` is an early release. Please report issues with simulated, public,
or redacted data:

- [Bug reports](https://github.com/juancyamin/cmrdesign/issues/new?template=bug_report.yml)
- [Usage questions](https://github.com/juancyamin/cmrdesign/issues/new?template=usage_question.yml)
- [Alpha feedback](https://github.com/juancyamin/cmrdesign/issues/new?template=alpha_feedback.yml)
