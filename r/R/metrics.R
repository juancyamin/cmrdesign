# Simulation and validation metrics.

#' Diagnostic metrics for CMR simulations
#'
#' Small helpers for checking rectangle coverage, certificate validity, boundary
#' assignment, and realized variance gains in simulation or validation code.
#'
#' @param rectangle Two-arm variance rectangle, either a numeric vector with
#'   names `v_l1`, `v_u1`, `v_l0`, `v_u0` or a rectangle object returned by a
#'   two-arm rectangle constructor.
#' @param truth Named true variances, with entries `v1` and `v0`.
#' @param pi Treatment assignment share.
#' @param U CMR certificate to check against realized regret.
#' @param tol Nonnegative numerical tolerance.
#' @param v1 Treatment-arm variance.
#' @param v0 Control-arm variance.
#'
#' @return
#' `coverage_indicator()`, `certificate_valid()`, and `boundary_indicator()`
#' return logical values. `boundary_rate()`, `saving_vs_balance()`, and
#' `share_of_oracle_gain()` return numeric values.
#'
#' @examples
#' rect <- c(v_l1 = 0.02, v_u1 = 0.12, v_l0 = 0.01, v_u0 = 0.08)
#' truth <- c(v1 = 0.09, v0 = 0.04)
#' fit <- cmr_two_arm_from_rectangle(rect)
#' coverage_indicator(rect, truth)
#' certificate_valid(fit$pi, fit$U_CMR, truth)
#' saving_vs_balance(fit$pi, truth["v1"], truth["v0"])
#'
#' @family diagnostic helpers
#' @export
coverage_indicator <- function(rectangle, truth) {
  rectangle <- .cmr_check_binary_rectangle(rectangle)
  truth <- .cmr_check_truth_binary(truth)

  rectangle[["v_l1"]] <= truth[["v1"]] &&
    truth[["v1"]] <= rectangle[["v_u1"]] &&
    rectangle[["v_l0"]] <= truth[["v0"]] &&
    truth[["v0"]] <= rectangle[["v_u0"]]
}

#' @rdname coverage_indicator
#' @export
certificate_valid <- function(pi, U, truth, tol = 1e-10) {
  pi <- .cmr_check_probability(pi, "pi", allow_boundary = TRUE)
  U <- .cmr_check_nonnegative(U, "U", allow_infinite = TRUE)
  truth <- .cmr_check_truth_binary(truth)
  tol <- .cmr_check_numeric(tol, "tol")
  if (length(tol) != 1L || tol < 0) {
    .cmr_stop("`tol` must be a nonnegative scalar.")
  }

  args <- .cmr_recycle_common(pi, U, arg_names = c("pi", "U"))
  regret(args$pi, truth[["v1"]], truth[["v0"]]) <= args$U + tol
}

#' @rdname coverage_indicator
#' @export
boundary_indicator <- function(pi, tol = 0) {
  pi <- .cmr_check_probability(pi, "pi", allow_boundary = TRUE)
  tol <- .cmr_check_numeric(tol, "tol")
  if (length(tol) != 1L || tol < 0 || tol >= 0.5) {
    .cmr_stop("`tol` must be a scalar in [0, 0.5).")
  }
  pi <= tol | pi >= 1 - tol
}

#' @rdname coverage_indicator
#' @export
boundary_rate <- function(pi, tol = 0) {
  mean(boundary_indicator(pi, tol = tol))
}

#' @rdname coverage_indicator
#' @export
saving_vs_balance <- function(pi, v1, v0) {
  pi <- .cmr_check_probability(pi, "pi", allow_boundary = TRUE)
  v1 <- .cmr_check_variance(v1, "v1")
  v0 <- .cmr_check_variance(v0, "v0")
  args <- .cmr_recycle_common(pi, v1, v0, arg_names = c("pi", "v1", "v0"))

  v_balance <- variance_objective(0.5, args$v1, args$v0)
  v_rule <- variance_objective(args$pi, args$v1, args$v0)
  ifelse(v_balance > 0, 1 - v_rule / v_balance, 0)
}

#' @rdname coverage_indicator
#' @export
share_of_oracle_gain <- function(pi, v1, v0, tol = 1e-12) {
  pi <- .cmr_check_probability(pi, "pi", allow_boundary = TRUE)
  v1 <- .cmr_check_variance(v1, "v1")
  v0 <- .cmr_check_variance(v0, "v0")
  tol <- .cmr_check_numeric(tol, "tol")
  if (length(tol) != 1L || tol < 0) {
    .cmr_stop("`tol` must be a nonnegative scalar.")
  }
  args <- .cmr_recycle_common(pi, v1, v0, arg_names = c("pi", "v1", "v0"))

  v_balance <- variance_objective(0.5, args$v1, args$v0)
  v_oracle <- oracle_variance(args$v1, args$v0)
  oracle_gain <- ifelse(v_balance > 0, 1 - v_oracle / v_balance, 0)
  saving <- saving_vs_balance(args$pi, args$v1, args$v0)
  ifelse(abs(oracle_gain) > tol, saving / oracle_gain, NA_real_)
}
