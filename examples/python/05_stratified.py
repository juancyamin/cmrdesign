"""Simulated stratified-design CMR example."""

import numpy as np

import cmrdesign as cmr

rng = np.random.default_rng(105)
n_per_cell = 150
strata = np.repeat(["urban", "rural"], 2 * n_per_cell)
d = np.tile(np.r_[np.ones(n_per_cell), np.zeros(n_per_cell)], 2)
y = np.r_[
    rng.beta(2, 5, n_per_cell),
    rng.beta(4, 4, n_per_cell),
    rng.beta(3, 6, n_per_cell),
    rng.beta(5, 4, n_per_cell),
]
strata_share = {"urban": 0.55, "rural": 0.45}

fit = cmr.cmr_stratified(y, d, strata, strata_share, alpha=0.05, method="bounded")

print(fit.pi)
print(fit.extra["sampling_margin"])
