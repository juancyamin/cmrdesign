# Quickstart

This page shows the shortest path from simulated pilot data to a CMR assignment
and certificate. The same workflow applies to real pilot data: replace the
simulated vectors with columns from your pilot data set.

## Install

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

Python from GitHub:

```bash
python -m pip install "cmrdesign @ git+https://github.com/juancyamin/cmrdesign.git#subdirectory=python"
```

Python alpha from TestPyPI, for release testing:

```bash
python -m pip install \
  --index-url https://test.pypi.org/simple/ \
  --extra-index-url https://pypi.org/simple \
  cmrdesign==0.1.0a1
```

## Inputs

For a two-arm design you pass:

- `y`: one vector of pilot outcomes, one entry per pilot unit.
- `d`: one vector of treatment labels, with `1` for treatment and `0` for
  control.
- `alpha`: the joint error level for the variance confidence rectangle.
- `method`: the way the arm variance confidence intervals are computed.

The simulated examples below build `y` by concatenating treatment outcomes and
control outcomes only to make the data-generating process visible. The result is
still just one outcome vector, and `d` tells the function which entries came
from which arm. With a data frame you would usually call
`cmr_two_arm(data$outcome, data$treatment, ...)`.

## R

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

## Python

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

## Read The Result

- `pi` is the recommended main-wave treatment share. For two arms, `pi = 0.6`
  means assign 60 percent of the main wave to treatment and 40 percent to
  control.
- `U_CMR` is the worst-case regret certificate over the variance confidence
  rectangle. It is not a treatment-effect estimate and it is not a
  treatment-effect confidence interval.
- `rectangle` or `confidence_set` records the variance uncertainty set that
  generated the allocation.
- `method` records the confidence-interval method after `auto` dispatch.
- `diagnostics` records solver status and edge cases.

## Common Next Steps

| If your design changes to... | Use... |
| --- | --- |
| Binary outcome coded 0/1 | `method = "auto"` or `method = "bernoulli"` |
| Bounded non-binary outcome on `[0, 1]` | `method = "bounded"` or `"mtr"` |
| Bounded outcome on another known scale | `normalize = TRUE` in R or `normalize=True` in Python |
| Raw finite outcome without a known bound | `cmr_unbounded(y, d, psi = ...)` |
| Multiple treatment arms | `cmr_multiarm(y, arm, control_arm = ...)` |
| Known strata | `cmr_stratified(y, d, strata, strata_share)` |
| Multiple outcomes per unit | `cmr_multiple_outcomes(y_matrix, d, weights, estimand)` |
| Proxy or delayed primary outcome | `cmr_proxy(proxy_y, d, zeta)` |

See [Choosing A Method](choosing_methods.md) for the variance confidence
interval options and [Methods](methods.md) for the supported CMR extensions.
