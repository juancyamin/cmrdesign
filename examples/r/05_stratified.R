# Simulated stratified-design CMR example.

library(cmrdesign)

set.seed(105)
n_per_cell <- 150L
strata <- rep(c("urban", "rural"), each = 2 * n_per_cell)
d <- rep(c(rep(1, n_per_cell), rep(0, n_per_cell)), times = 2)
y <- c(
  rbeta(n_per_cell, 2, 5),
  rbeta(n_per_cell, 4, 4),
  rbeta(n_per_cell, 3, 6),
  rbeta(n_per_cell, 5, 4)
)
strata_share <- c(urban = 0.55, rural = 0.45)

fit <- cmr_stratified(y, d, strata, strata_share, alpha = 0.05, method = "bounded")

print(fit$pi)
print(fit$sampling_margin)
