library(cmrdesign)

set.seed(109)
n_per_arm <- 1500L
d <- c(rep(1, n_per_arm), rep(0, n_per_arm))

y <- c(
  0.20 + 1.10 * stats::rt(n_per_arm, df = 8),
  0.00 + 0.70 * stats::rt(n_per_arm, df = 8)
)

fit <- cmr_two_arm(
  y,
  d,
  alpha = 0.10,
  method = "unbounded",
  psi = c(treatment = 6, control = 6)
)

print(fit$pi)
print(fit$U_CMR)
print(fit$pilot[c("rho", "b", "active", "status")])
