"""Simulated two-arm bounded-outcome CMR example."""

import numpy as np

import cmrdesign as cmr

rng = np.random.default_rng(101)
n_pilot = 800
d = np.r_[np.ones(n_pilot // 2), np.zeros(n_pilot // 2)]
y = np.r_[rng.beta(2, 5, n_pilot // 2), rng.beta(4, 4, n_pilot // 2)]

fit = cmr.cmr_two_arm(y, d, alpha=0.05, method="bounded")

print({"pi_treatment": fit.pi, "certificate": fit.U_CMR})
