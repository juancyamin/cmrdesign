"""Simulated multiple-outcome CMR example."""

import numpy as np

import cmrdesign as cmr

rng = np.random.default_rng(106)
n_pilot = 800
d = np.r_[np.ones(n_pilot // 2), np.zeros(n_pilot // 2)]
y1 = np.r_[rng.beta(2, 5, n_pilot // 2), rng.beta(4, 4, n_pilot // 2)]
y2 = np.r_[rng.beta(3, 6, n_pilot // 2), rng.beta(5, 5, n_pilot // 2)]
y = np.c_[y1, y2]

fit = cmr.cmr_multiple_outcomes(
    y,
    d,
    weights=[0.4, 0.6],
    estimand="coprimary",
    alpha=0.05,
    method="bounded",
)

print({"pi_treatment": fit.pi, "certificate": fit.U_CMR})
