"""Compare Maurer–Pontil and MTR rectangles on simulated bounded outcomes."""

import numpy as np

import cmrdesign as cmr

rng = np.random.default_rng(103)
n_pilot = 240
d = np.r_[np.ones(n_pilot // 2), np.zeros(n_pilot // 2)]
y = np.r_[rng.beta(2, 6, n_pilot // 2), rng.beta(3, 5, n_pilot // 2)]

mp = cmr.cmr_two_arm(y, d, alpha=0.05, method="bounded")
mtr = cmr.cmr_two_arm(y, d, alpha=0.05, method="mtr")

print({"mp_pi": mp.pi, "mp_U": mp.U_CMR})
print({"mtr_pi": mtr.pi, "mtr_U": mtr.U_CMR})
