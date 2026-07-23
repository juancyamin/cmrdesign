# Simulated binary-outcome example using exact Bernoulli rectangles.

library(cmrdesign)

set.seed(102)
n_pilot <- 100L
d <- c(rep(1, n_pilot / 2), rep(0, n_pilot / 2))
y <- c(rbinom(n_pilot / 2, 1, 0.35), rbinom(n_pilot / 2, 1, 0.20))

fit <- cmr_two_arm(y, d, alpha = 0.05, method = "auto")

print(list(method = fit$method, pi_treatment = fit$pi, certificate = fit$U_CMR))
