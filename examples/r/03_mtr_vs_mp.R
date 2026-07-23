# Compare Maurer-Pontil and MTR rectangles on simulated bounded outcomes.

library(cmrdesign)

set.seed(103)
n_pilot <- 240L
d <- c(rep(1, n_pilot / 2), rep(0, n_pilot / 2))
y <- c(rbeta(n_pilot / 2, 2, 6), rbeta(n_pilot / 2, 3, 5))

mp <- cmr_two_arm(y, d, alpha = 0.05, method = "bounded")
mtr <- cmr_two_arm(y, d, alpha = 0.05, method = "mtr")

print(list(mp_pi = mp$pi, mp_U = mp$U_CMR))
print(list(mtr_pi = mtr$pi, mtr_U = mtr$U_CMR))
