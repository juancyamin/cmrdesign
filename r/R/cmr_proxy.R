# Proxy or delayed-primary-outcome Conditional Minimax Regret rule.

cmr_proxy <- function(proxy_y,
                      d,
                      zeta,
                      alpha = 0.05,
                      method = c("auto", "bounded", "bernoulli",
                                 "maurer_pontil", "mp", "bernoulli_exact",
                                 "martinez_taboada_ramdas", "mtr"),
                      beta = NULL,
                      correction = c("bonferroni", "sidak_arms"),
                      normalize = FALSE,
                      lower = NULL,
                      upper = NULL,
                      na.rm = TRUE,
                      tol = 1e-11) {
  confidence_set <- rectangle_proxy(
    proxy_y = proxy_y,
    d = d,
    zeta = zeta,
    alpha = alpha,
    method = method,
    beta = beta,
    correction = correction,
    normalize = normalize,
    lower = lower,
    upper = upper,
    na.rm = na.rm,
    tol = tol
  )

  out <- cmr_two_arm_from_rectangle(confidence_set$rectangle)
  out$confidence_set <- confidence_set
  out$pilot <- list(
    n = confidence_set$n,
    vhat = confidence_set$vhat,
    method = confidence_set$method,
    normalization = confidence_set$normalization,
    zeta = confidence_set$zeta
  )
  out$alpha <- confidence_set$alpha
  out$beta <- confidence_set$beta
  out$correction <- confidence_set$correction
  out$method <- confidence_set$method
  out$zeta <- confidence_set$zeta
  out$joint_error_bound <- confidence_set$joint_error_bound
  out$diagnostics$confidence_method <- confidence_set$method
  out$diagnostics$joint_error_bound <- confidence_set$joint_error_bound
  out$diagnostics$bridge <- confidence_set$bridge$assumption
  class(out) <- c("cmr_proxy", class(out))
  out
}

cmr_delayed_outcome <- cmr_proxy
