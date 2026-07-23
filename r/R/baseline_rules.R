# Baseline and comparator assignment rules.
#
# Benchmarks are intentionally standalone functions, not outputs of CMR
# functions. Simulation scripts should call these functions explicitly.

#' Baseline and comparator assignment rules
#'
#' Standalone benchmark assignment rules for comparing CMR against balance,
#' feasible Neyman, and simple regularized Neyman variants.
#'
#' @param n Number of assignment shares to return for `assign_balance()`.
#' @param arms Either the number of treatment arms, excluding control, or a
#'   vector of arm labels that includes control arm `"0"`.
#' @param strata_share Named stratum population shares that sum to one.
#' @param vhat1 Estimated treatment-arm variance or vector of estimates.
#' @param vhat0 Estimated control-arm variance or vector of estimates.
#' @param trim Lower and upper trimming amount for `assign_trimmed_neyman()`.
#'   The returned share is clipped to `[trim, 1 - trim]`.
#' @param nu Nonnegative additive regularization strength.
#' @param tau Nonnegative exponent for exponential regularization.
#' @param zero_guard How zero variance estimates are guarded in
#'   `assign_exponential_regularized_neyman()`: `"any"` returns balance if
#'   either arm variance is zero, `"both"` only if both are zero, and `"none"`
#'   applies no extra guard.
#'
#' @return
#' Numeric assignment shares. Two-arm functions return treatment shares.
#' `assign_multiarm_balance()` returns a named vector over all arms, including
#' control `"0"`. `assign_stratified_balance()` returns total assignment shares
#' for treatment and control cells named like `"1:A"` and `"0:A"`.
#'
#' @examples
#' assign_balance(3)
#' assign_feasible_neyman(0.12, 0.04)
#' assign_trimmed_neyman(0.12, 0.04, trim = 0.10)
#' assign_multiarm_balance(2)
#' assign_stratified_balance(c(A = 0.4, B = 0.6))
#'
#' @family assignment helpers
#' @export
assign_balance <- function(n = 1L) {
  n <- .cmr_check_scalar_integer(n, "n", lower = 1L)
  rep(0.5, n)
}

#' @rdname assign_balance
#' @export
assign_multiarm_balance <- function(arms) {
  if (length(arms) == 1L && is.numeric(arms)) {
    k <- .cmr_check_scalar_integer(arms, "arms", lower = 1L)
    arms <- c("0", as.character(seq_len(k)))
  } else {
    arms <- as.character(arms)
    if (length(arms) < 2L) {
      .cmr_stop("`arms` must include control plus at least one treatment arm.")
    }
    if (anyNA(arms) || any(arms == "")) {
      .cmr_stop("`arms` cannot contain missing or empty labels.")
    }
    arms <- sub("^v", "", arms)
    if (!"0" %in% arms) {
      .cmr_stop("`arms` must include control arm `0`.")
    }
    if (anyDuplicated(arms)) {
      .cmr_stop("`arms` labels must be unique.")
    }
    arms <- arms[.cmr_arm_order(arms)]
    k <- length(arms) - 1L
    if (k < 1L) {
      .cmr_stop("`arms` must include at least one treatment arm.")
    }
  }

  out <- rep(1 / (sqrt(k) * (1 + sqrt(k))), length(arms))
  names(out) <- arms
  out[["0"]] <- 1 / (1 + sqrt(k))
  out
}

#' @rdname assign_balance
#' @export
assign_stratified_balance <- function(strata_share) {
  strata_share <- .cmr_check_strata_share(strata_share)
  out <- rep(strata_share / 2, each = 2L)
  names(out) <- as.vector(rbind(
    paste0("1:", names(strata_share)),
    paste0("0:", names(strata_share))
  ))
  out
}

#' @rdname assign_balance
#' @export
assign_feasible_neyman <- function(vhat1, vhat0) {
  assign_neyman(vhat1, vhat0)
}

assign_cairafi_feasible_neyman <- function(vhat1, vhat0) {
  vhat1 <- .cmr_check_variance(vhat1, "vhat1")
  vhat0 <- .cmr_check_variance(vhat0, "vhat0")
  args <- .cmr_recycle_common(vhat1, vhat0, arg_names = c("vhat1", "vhat0"))
  s1 <- sqrt(args$vhat1)
  s0 <- sqrt(args$vhat0)
  denom <- s1 + s0
  out <- ifelse(denom > 0, s1 / denom, 0.5)
  out[args$vhat1 == 0 | args$vhat0 == 0] <- 0.5
  out
}

#' @rdname assign_balance
#' @export
assign_trimmed_neyman <- function(vhat1, vhat0, trim = 0.10) {
  trim <- .cmr_check_trim(trim)
  pi <- assign_feasible_neyman(vhat1, vhat0)
  .cmr_clip(pi, trim, 1 - trim)
}

#' @rdname assign_balance
#' @export
assign_additive_regularized_neyman <- function(vhat1, vhat0, nu) {
  vhat1 <- .cmr_check_variance(vhat1, "vhat1")
  vhat0 <- .cmr_check_variance(vhat0, "vhat0")
  nu <- .cmr_check_numeric(nu, "nu")
  if (length(nu) != 1L || nu < 0) {
    .cmr_stop("`nu` must be a nonnegative scalar.")
  }
  args <- .cmr_recycle_common(vhat1, vhat0, arg_names = c("vhat1", "vhat0"))
  s1 <- sqrt(args$vhat1)
  s0 <- sqrt(args$vhat0)
  denom <- (s1 + s0) * (1 + nu)
  ifelse(denom > 0, (s1 + nu * s0) / denom, 0.5)
}

assign_cairafi_additive_neyman <- function(vhat1, vhat0, nu) {
  vhat1 <- .cmr_check_variance(vhat1, "vhat1")
  vhat0 <- .cmr_check_variance(vhat0, "vhat0")
  nu <- .cmr_check_numeric(nu, "nu")
  if (length(nu) != 1L || nu < 0) {
    .cmr_stop("`nu` must be a nonnegative scalar.")
  }
  out <- assign_additive_regularized_neyman(vhat1, vhat0, nu = nu)
  if (nu == 0) {
    args <- .cmr_recycle_common(vhat1, vhat0, arg_names = c("vhat1", "vhat0"))
    out[args$vhat1 == 0 | args$vhat0 == 0] <- 0.5
  }
  out
}

#' @rdname assign_balance
#' @export
assign_exponential_regularized_neyman <- function(vhat1,
                                                  vhat0,
                                                  tau,
                                                  zero_guard = c("any", "both", "none")) {
  zero_guard <- match.arg(zero_guard)
  vhat1 <- .cmr_check_variance(vhat1, "vhat1")
  vhat0 <- .cmr_check_variance(vhat0, "vhat0")
  tau <- .cmr_check_numeric(tau, "tau")
  if (length(tau) != 1L || tau < 0) {
    .cmr_stop("`tau` must be a nonnegative scalar.")
  }
  args <- .cmr_recycle_common(vhat1, vhat0, arg_names = c("vhat1", "vhat0"))

  if (tau == 0) {
    return(rep(0.5, length(args$vhat1)))
  }

  s1_tau <- sqrt(args$vhat1)^tau
  s0_tau <- sqrt(args$vhat0)^tau
  denom <- s1_tau + s0_tau
  out <- ifelse(denom > 0, s1_tau / denom, 0.5)

  if (zero_guard == "any") {
    out[args$vhat1 == 0 | args$vhat0 == 0] <- 0.5
  } else if (zero_guard == "both") {
    out[args$vhat1 == 0 & args$vhat0 == 0] <- 0.5
  }

  out
}

assign_cairafi_exponential_neyman <- function(vhat1, vhat0, tau) {
  assign_exponential_regularized_neyman(
    vhat1 = vhat1,
    vhat0 = vhat0,
    tau = tau,
    zero_guard = "any"
  )
}

.cairafi_variance_wald_component <- function(y) {
  if (length(y) < 2L) {
    .cmr_stop("Each pilot arm must contain at least two observations.")
  }
  mu <- mean(y)
  mu2 <- mean(y^2)
  centered_y <- y - mu
  centered_y2 <- y^2 - mu2
  cov_22 <- mean(centered_y2^2)
  cov_12 <- mean(centered_y * centered_y2)
  cov_11 <- mean(centered_y^2)
  c(1, -2 * mu) %*%
    matrix(c(cov_22, cov_12, cov_12, cov_11), nrow = 2L) %*%
    c(1, -2 * mu)
}

cairafi_homoskedasticity_wald <- function(y, d, na.rm = TRUE) {
  pilot <- .cmr_split_binary_pilot(y, d, na.rm = na.rm)
  if (length(pilot$y1) < 2L || length(pilot$y0) < 2L) {
    .cmr_stop("Each pilot arm must contain at least two observations.")
  }

  sigma2_1 <- mean(pilot$y1^2) - mean(pilot$y1)^2
  sigma2_0 <- mean(pilot$y0^2) - mean(pilot$y0)^2
  se2 <- as.numeric(.cairafi_variance_wald_component(pilot$y1)) / length(pilot$y1) +
    as.numeric(.cairafi_variance_wald_component(pilot$y0)) / length(pilot$y0)

  if (se2 <= 0) {
    diff <- sigma2_1 - sigma2_0
    return(ifelse(abs(diff) <= 1e-12, 0, sign(diff) * Inf))
  }

  (sigma2_1 - sigma2_0) / sqrt(se2)
}

assign_cairafi_test_neyman <- function(y, d, alpha = 0.05, na.rm = TRUE) {
  alpha <- .cmr_check_alpha(alpha)
  pilot <- .cmr_split_binary_pilot(y, d, na.rm = na.rm)
  if (length(pilot$y1) < 2L || length(pilot$y0) < 2L) {
    .cmr_stop("Each pilot arm must contain at least two observations.")
  }

  wald <- cairafi_homoskedasticity_wald(pilot$y, pilot$d, na.rm = FALSE)
  if (abs(wald) <= stats::qnorm(1 - alpha / 2)) {
    return(0.5)
  }

  assign_cairafi_feasible_neyman(
    .cmr_clip(stats::var(pilot$y1), 0, 0.25),
    .cmr_clip(stats::var(pilot$y0), 0, 0.25)
  )
}
