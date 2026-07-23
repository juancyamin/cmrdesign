"""Simulated shared-control multi-arm CMR example."""

import numpy as np

import cmrdesign as cmr

rng = np.random.default_rng(104)
n_per_arm = 300
arm = np.repeat([0, 1, 2], n_per_arm)
y = np.r_[
    rng.beta(4, 4, n_per_arm),
    rng.beta(2, 6, n_per_arm),
    rng.beta(5, 3, n_per_arm),
]

fit = cmr.cmr_multiarm(y, arm, alpha=0.05, method="bounded")

print(fit.pi)
print({"certificate": fit.U_CMR})
