# Multiple-outcome Conditional Minimax Regret rules.

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
