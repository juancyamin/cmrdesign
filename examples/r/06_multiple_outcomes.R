# Simulated multiple-outcome CMR example.

library(cmrdesign)

set.seed(106)
n_pilot <- 800L
d <- c(rep(1, n_pilot / 2), rep(0, n_pilot / 2))
y1 <- c(rbeta(n_pilot / 2, 2, 5), rbeta(n_pilot / 2, 4, 4))
y2 <- c(rbeta(n_pilot / 2, 3, 6), rbeta(n_pilot / 2, 5, 5))
y <- cbind(primary = y1, secondary = y2)

fit <- cmr_multiple_outcomes(
  y,
  d,
  weights = c(primary = 0.4, secondary = 0.6),
  estimand = "coprimary",
  alpha = 0.05,
  method = "bounded"
)

print(list(pi_treatment = fit$pi, certificate = fit$U_CMR))
