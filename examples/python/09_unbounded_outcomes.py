import numpy as np

import cmrdesign as cmr

rng = np.random.default_rng(109)
n_per_arm = 1500
d = np.r_[np.ones(n_per_arm), np.zeros(n_per_arm)]

y = np.r_[
    0.20 + 1.10 * rng.standard_t(df=8, size=n_per_arm),
    0.00 + 0.70 * rng.standard_t(df=8, size=n_per_arm),
]

fit = cmr.cmr_two_arm(
    y,
    d,
    alpha=0.10,
    method="unbounded",
    psi={"treatment": 6, "control": 6},
)

print(fit.pi)
print(fit.U_CMR)
print({key: fit.pilot[key] for key in ("rho", "b", "active", "status")})
