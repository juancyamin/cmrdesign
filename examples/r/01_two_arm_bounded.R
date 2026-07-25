# Simulated two-arm bounded-outcome CMR example.

library(cmrdesign)

set.seed(101)
n_pilot <- 800L
d <- c(rep(1, n_pilot / 2), rep(0, n_pilot / 2))
y <- c(rbeta(n_pilot / 2, 2, 5), rbeta(n_pilot / 2, 4, 4))

fit <- cmr_two_arm(y, d, alpha = 0.05, method = "bounded")
allocation <- realize_allocation(fit, n_main = 1000)

print(list(pi_treatment = fit$pi, certificate = fit$U_CMR))
print(list(counts = allocation$counts,
           realized_certificate = allocation$realized_U_CMR))
