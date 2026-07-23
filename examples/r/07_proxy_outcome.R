# Simulated proxy/delayed-primary-outcome CMR example.

library(cmrdesign)

set.seed(107)
n_pilot <- 100L
d <- c(rep(1, n_pilot / 2), rep(0, n_pilot / 2))
proxy_y <- c(rbinom(n_pilot / 2, 1, 0.35), rbinom(n_pilot / 2, 1, 0.25))

fit <- cmr_proxy(
  proxy_y,
  d,
  zeta = c(treatment = 0.04, control = 0.06),
  method = "bernoulli"
)

print(list(pi_treatment = fit$pi, certificate = fit$U_CMR))
print(fit$confidence_set$bridge)
