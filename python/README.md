# cmrdesign Python Package

Python implementation of `cmrdesign`, the applied Conditional Minimax Regret
design-rule package.

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

- `cmr_two_arm()` and expert rectangle helpers.
- Exact Bernoulli folded-binomial rectangles.
- Maurer-Pontil bounded-outcome rectangles.
- Martinez-Taboada-Ramdas (MTR) rectangles.
- Shared-control multi-arm CMR.
- Stratified CMR.
- Multiple-outcome CMR for weighted-index and co-primary workflows.
- Proxy/delayed-outcome CMR bridge widening.
- Appendix E pilot-planning helpers via `cmr_plan()`.

Run local checks with:

```bash
PYTHONPATH=src python -m unittest discover -s tests -v
```
