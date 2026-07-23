"""Simulated proxy/delayed-primary-outcome CMR example."""

import numpy as np

import cmrdesign as cmr

rng = np.random.default_rng(107)
n_pilot = 100
d = np.r_[np.ones(n_pilot // 2), np.zeros(n_pilot // 2)]
proxy_y = np.r_[
    rng.binomial(1, 0.35, n_pilot // 2),
    rng.binomial(1, 0.25, n_pilot // 2),
]

fit = cmr.cmr_proxy(proxy_y, d, zeta={"treatment": 0.04, "control": 0.06}, method="bernoulli")

print({"pi_treatment": fit.pi, "certificate": fit.U_CMR})
print(fit.confidence_set.extra["bridge"])
