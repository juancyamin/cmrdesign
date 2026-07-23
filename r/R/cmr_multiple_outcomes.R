# Multiple-outcome Conditional Minimax Regret rules.

#' Multiple-outcome CMR assignment
#'
#' Estimate an effective two-arm variance rectangle for multiple outcomes and
#' return the CMR treatment share.
#'
#' @inheritParams rectangle_multiple_outcomes
#'
#' @return
#' A list of class `cmr_multiple_outcomes` and `cmr_two_arm` with treatment
#' share `pi`, CMR certificate `U_CMR`, effective confidence rectangle, pilot
#' summaries, outcome weights, estimand metadata, endpoint error allocation, and
#' diagnostics.
#'
#' @examples
#' set.seed(10)
#' d <- rep(c(1, 0), each = 20)
#' y <- cbind(
#'   y1 = c(rbeta(20, 2, 6), rbeta(20, 4, 4)),
#'   y2 = c(rbeta(20, 5, 3), rbeta(20, 3, 5))
#' )
#' cmr_multiple_outcomes(y, d, weights = c(0.6, 0.4))
#'
#' @family CMR rules
#' @export
cmr_multiple_outcomes <- function(y,
                                  d,
                                  weights = NULL,
                                  estimand = c("coprimary", "index"),
                                  alpha = 0.05,
                                  method = c("auto", "bounded", "bernoulli",
                                             "maurer_pontil", "mp",
                                             "bernoulli_exact",
                                             "martinez_taboada_ramdas", "mtr"),
                                  beta = NULL,
                                  na.rm = TRUE,
                                  tol = 1e-11) {
  confidence_set <- rectangle_multiple_outcomes(
    y = y,
    d = d,
    weights = weights,
    estimand = estimand,
    alpha = alpha,
    method = method,
    beta = beta,
    na.rm = na.rm,
    tol = tol
  )

  out <- cmr_two_arm_from_rectangle(confidence_set$rectangle)
  out$confidence_set <- confidence_set
  out$pilot <- list(
    n = confidence_set$n,
    vhat = confidence_set$vhat,
    method = confidence_set$method,
    estimand = confidence_set$estimand,
    weights = confidence_set$weights
  )
  out$alpha <- confidence_set$alpha
  out$beta <- confidence_set$beta
  out$method <- confidence_set$method
  out$estimand <- confidence_set$estimand
  out$weights <- confidence_set$weights
  out$joint_error_bound <- confidence_set$joint_error_bound
  out$diagnostics$confidence_method <- confidence_set$method
  out$diagnostics$joint_error_bound <- confidence_set$joint_error_bound
  out$diagnostics$estimand <- confidence_set$estimand
  class(out) <- c("cmr_multiple_outcomes", class(out))
  out
}
