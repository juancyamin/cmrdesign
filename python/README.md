# cmrdesign Python Package

[![PyPI](https://img.shields.io/pypi/v/cmrdesign?label=PyPI)](https://pypi.org/project/cmrdesign/)
[![Python versions](https://img.shields.io/pypi/pyversions/cmrdesign)](https://pypi.org/project/cmrdesign/)
[![arXiv](https://img.shields.io/badge/arXiv-2607.16982-b31b1b.svg)](https://arxiv.org/abs/2607.16982)

Python implementation of `cmrdesign`, the applied Conditional Minimax Regret
design-rule package.

The methods accompany
[When and How to Pilot: Design Rules for Two-Wave Experiments](https://arxiv.org/abs/2607.16982)
by Juan C. Yamin. This package is implementation-focused and uses simulated
examples only; paper replications and empirical simulations are intentionally
kept out of the package repository.

## Installation

Install the current Python alpha from PyPI:

```bash
python -m pip install --pre cmrdesign
```

For exact reproducibility, pin the current alpha version:

```bash
python -m pip install cmrdesign==0.1.0a2
```

For the development version from GitHub:

```bash
python -m pip install "cmrdesign @ git+https://github.com/juancyamin/cmrdesign.git#subdirectory=python"
```

For local development from the repository root:

```bash
python -m pip install -e python
```

## Quick Start

```python
import numpy as np
import cmrdesign as cmr

rng = np.random.default_rng(123)
d = np.r_[np.ones(40), np.zeros(40)]
y = np.r_[rng.beta(2, 5, 40), rng.beta(4, 4, 40)]

fit = cmr.cmr_two_arm(y, d, alpha=0.05, method="auto")
print(fit.pi)
print(fit.U_CMR)
```

## Implemented Surface

- `cmr_two_arm()` and `cmr_binary()`.
- `method="auto"` for the applied bounded/binary default.
- Maurer–Pontil bounded-outcome variance rectangles.
- Exact Bernoulli folded-binomial variance rectangles.
- Martinez-Taboada–Ramdas (MTR) bounded-outcome rectangles.
- Two-arm unbounded-outcome median-of-means rectangles via `cmr_unbounded()`.
- Shared-control multi-arm CMR via `cmr_multiarm()`.
- Stratified CMR via `cmr_stratified()`.
- Multiple-outcome CMR for weighted-index and co-primary workflows via
  `cmr_multiple_outcomes()`.
- Proxy/delayed-outcome CMR bridge widening via `cmr_proxy()`.
- Pilot-planning helpers from Appendix E of the accompanying paper
  (Yamin 2026) via `cmr_plan()`.
- Expert rectangle helpers via `rectangle_*()` and `cmr_*_from_rectangle()`.

See the repository-level docs for applied guidance:

- [Quick Start](https://github.com/juancyamin/cmrdesign/blob/main/docs/quickstart.md)
- [Choosing a Method](https://github.com/juancyamin/cmrdesign/blob/main/docs/choosing_methods.md)
- [Methods](https://github.com/juancyamin/cmrdesign/blob/main/docs/methods.md)
- [Pilot Planning](https://github.com/juancyamin/cmrdesign/blob/main/docs/pilot_planning.md)

From the repository root, run local checks with:

```bash
python -m pip install -e python
python -m unittest discover -s python/tests -v
```
