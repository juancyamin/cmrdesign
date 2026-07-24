# cmrdesign Python Package

Python implementation of `cmrdesign`, the applied Conditional Minimax Regret
design-rule package.

The methods accompany
[When and How to Pilot: Design Rules for Two-Wave Experiments](https://arxiv.org/abs/2607.16982)
by Juan C. Yamin. This package is implementation-focused and uses simulated
examples only; paper replications and empirical simulations are intentionally
kept out of the package repository.

## Installation

Until the first PyPI upload, install from GitHub for normal use:

```bash
python -m pip install "cmrdesign @ git+https://github.com/juancyamin/cmrdesign.git#subdirectory=python"
```

The first alpha candidate is also available on TestPyPI for release testing:

```bash
python -m pip install \
  --index-url https://test.pypi.org/simple/ \
  --extra-index-url https://pypi.org/simple \
  cmrdesign==0.1.0a1
```

For local development from the repository root:

```bash
python -m pip install -e python
```

## Quick Example

```python
import numpy as np
import cmrdesign as cmr

rng = np.random.default_rng(123)
d = np.r_[np.ones(40), np.zeros(40)]
y = np.r_[rng.beta(2, 5, 40), rng.beta(4, 4, 40)]

fit = cmr.cmr_two_arm(y, d, alpha=0.05, method="bounded")
print(fit.pi)
print(fit.U_CMR)
```

## Implemented Surface

- `cmr_two_arm()` and `cmr_binary()`.
- `method="auto"` for the applied bounded/binary default.
- Maurer-Pontil bounded-outcome variance rectangles.
- Exact Bernoulli folded-binomial variance rectangles.
- Martinez-Taboada-Ramdas (MTR) bounded-outcome rectangles.
- Two-arm unbounded-outcome median-of-means rectangles via `cmr_unbounded()`.
- Shared-control multi-arm CMR via `cmr_multiarm()`.
- Stratified CMR via `cmr_stratified()`.
- Multiple-outcome CMR for weighted-index and co-primary workflows via
  `cmr_multiple_outcomes()`.
- Proxy/delayed-outcome CMR bridge widening via `cmr_proxy()`.
- Appendix E pilot-planning helpers via `cmr_plan()`.
- Expert rectangle helpers via `rectangle_*()` and `cmr_*_from_rectangle()`.

See the repository-level docs for applied guidance:

- `docs/quickstart.md`
- `docs/choosing_methods.md`
- `docs/methods.md`
- `docs/pilot_planning.md`

From the repository root, run local checks with:

```bash
python -m pip install -e python
python -m unittest discover -s python/tests -v
```
