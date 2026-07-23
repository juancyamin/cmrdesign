"""Simulated binary-outcome example using exact Bernoulli rectangles."""

import numpy as np

import cmrdesign as cmr

rng = np.random.default_rng(102)
n_pilot = 100
d = np.r_[np.ones(n_pilot // 2), np.zeros(n_pilot // 2)]
y = np.r_[rng.binomial(1, 0.35, n_pilot // 2), rng.binomial(1, 0.20, n_pilot // 2)]

fit = cmr.cmr_two_arm(y, d, alpha=0.05, method="auto")

print({"method": fit.method, "pi_treatment": fit.pi, "certificate": fit.U_CMR})
