# Core variance, oracle, Neyman, and regret functions.

variance_objective <- function(pi, v1, v0) {
  pi <- .cmr_check_probability(pi, "pi", allow_boundary = TRUE)
  v1 <- .cmr_check_variance(v1, "v1")
  v0 <- .cmr_check_variance(v0, "v0")
  args <- .cmr_recycle_common(pi, v1, v0, arg_names = c("pi", "v1", "v0"))
  pi <- args$pi
  v1 <- args$v1
  v0 <- args$v0

  out <- rep(NA_real_, length(pi))

  interior <- pi > 0 & pi < 1
  out[interior] <- v1[interior] / pi[interior] +
    v0[interior] / (1 - pi[interior])

  left <- pi == 0
  out[left] <- ifelse(v1[left] > 0, Inf, v0[left])

  right <- pi == 1
  out[right] <- ifelse(v0[right] > 0, Inf, v1[right])

  out
}

oracle_variance <- function(v1, v0) {
  v1 <- .cmr_check_variance(v1, "v1")
  v0 <- .cmr_check_variance(v0, "v0")
  args <- .cmr_recycle_common(v1, v0, arg_names = c("v1", "v0"))
  (sqrt(args$v1) + sqrt(args$v0))^2
}

assign_neyman <- function(v1, v0) {
  v1 <- .cmr_check_variance(v1, "v1")
  v0 <- .cmr_check_variance(v0, "v0")
  args <- .cmr_recycle_common(v1, v0, arg_names = c("v1", "v0"))
  s1 <- sqrt(args$v1)
  s0 <- sqrt(args$v0)
  denom <- s1 + s0
  ifelse(denom > 0, s1 / denom, 0.5)
}

regret <- function(pi, v1, v0) {
  pi <- .cmr_check_probability(pi, "pi", allow_boundary = TRUE)
  v1 <- .cmr_check_variance(v1, "v1")
  v0 <- .cmr_check_variance(v0, "v0")
  args <- .cmr_recycle_common(pi, v1, v0, arg_names = c("pi", "v1", "v0"))
  pi <- args$pi
  v1 <- args$v1
  v0 <- args$v0

  out <- rep(NA_real_, length(pi))

  interior <- pi > 0 & pi < 1
  if (any(interior)) {
    s1 <- sqrt(v1[interior])
    s0 <- sqrt(v0[interior])
    imbalance <- (1 - pi[interior]) * s1 - pi[interior] * s0
    out[interior] <- (imbalance^2) / (pi[interior] * (1 - pi[interior]))
  }

  left <- pi == 0
  out[left] <- ifelse(v1[left] > 0, Inf, 0)

  right <- pi == 1
  out[right] <- ifelse(v0[right] > 0, Inf, 0)

  out
}
