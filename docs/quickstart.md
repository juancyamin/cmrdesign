# Quickstart

This page shows the shortest path from simulated pilot data to a CMR assignment
and certificate.

## Install

R via R-universe, after the first R-universe build completes:

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

Python:

```bash
python -m pip install "cmrdesign @ git+https://github.com/juancyamin/cmrdesign.git#subdirectory=python"
```

## R

```r
library(cmrdesign)

set.seed(123)
d <- c(rep(1, 40), rep(0, 40))
y <- c(rbeta(40, 2, 5), rbeta(40, 4, 4))

fit <- cmr_two_arm(y, d, alpha = 0.05, method = "bounded")
fit$pi
fit$U_CMR
```

## Python

```python
import numpy as np
import cmrdesign as cmr

rng = np.random.default_rng(123)
d = np.r_[np.ones(40), np.zeros(40)]
y = np.r_[rng.beta(2, 5, 40), rng.beta(4, 4, 40)]

fit = cmr.cmr_two_arm(y, d, alpha=0.05, method="bounded")
fit.pi
fit.U_CMR
```

Use `method="auto"` for the applied default. It dispatches to exact Bernoulli
folded-binomial rectangles for raw 0/1 outcomes and Maurer-Pontil
bounded-outcome rectangles otherwise. If you normalize a non-unit-scale outcome,
`auto` still checks the raw values first. Use `method="mtr"` to request the
Martinez-Taboada-Ramdas bounded-outcome confidence sequence bounds; MTR uses
the supplied pilot row order. Use `method="unbounded"` with `psi` for the
two-arm unbounded-outcome extension when outcomes are raw finite values rather
than bounded-scale outcomes.
