# Simulated shared-control multi-arm CMR example.

library(cmrdesign)

set.seed(104)
n_per_arm <- 300L
arm <- rep(c(0, 1, 2), each = n_per_arm)
y <- c(
  rbeta(n_per_arm, 4, 4),
  rbeta(n_per_arm, 2, 6),
  rbeta(n_per_arm, 5, 3)
)

fit <- cmr_multiarm(y, arm, alpha = 0.05, method = "bounded")

print(fit$pi)
print(list(certificate = fit$U_CMR))
