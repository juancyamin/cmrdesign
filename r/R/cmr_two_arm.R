# Two-arm Conditional Minimax Regret rule.

binary_rectangle_corners <- function(rectangle) {
  rectangle <- .cmr_check_binary_rectangle(rectangle)
  rbind(
    treatment_high_control_low = c(v1 = rectangle[["v_u1"]], v0 = rectangle[["v_l0"]]),
    treatment_low_control_high = c(v1 = rectangle[["v_l1"]], v0 = rectangle[["v_u0"]])
  )
}

binary_rectangle_regret <- function(pi, rectangle, return_details = FALSE) {
  rectangle <- .cmr_check_binary_rectangle(rectangle)
  pi <- .cmr_check_probability(pi, "pi", allow_boundary = TRUE)
  corners <- binary_rectangle_corners(rectangle)

  regret_plus <- regret(
    pi = pi,
    v1 = corners["treatment_high_control_low", "v1"],
    v0 = corners["treatment_high_control_low", "v0"]
  )
  regret_minus <- regret(
    pi = pi,
    v1 = corners["treatment_low_control_high", "v1"],
    v0 = corners["treatment_low_control_high", "v0"]
  )
  value <- pmax(regret_plus, regret_minus)

  if (!return_details) {
    return(value)
  }

  binding <- ifelse(
    abs(regret_plus - regret_minus) <= 1e-10,
    "both",
    ifelse(regret_plus > regret_minus,
           "treatment_high_control_low",
           "treatment_low_control_high")
  )

  list(
    value = value,
    corner_regrets = c(
      treatment_high_control_low = regret_plus,
      treatment_low_control_high = regret_minus
    ),
    binding = binding,
    corners = corners
  )
}

cmr_two_arm_from_rectangle <- function(rectangle) {
  rectangle <- .cmr_check_binary_rectangle(rectangle)

  s_l1 <- sqrt(rectangle[["v_l1"]])
  s_u1 <- sqrt(rectangle[["v_u1"]])
  s_l0 <- sqrt(rectangle[["v_l0"]])
  s_u0 <- sqrt(rectangle[["v_u0"]])

  score_treatment <- s_u1 + s_l1
  score_control <- s_u0 + s_l0
  score_total <- score_treatment + score_control

  pi <- if (score_total > 0) {
    score_treatment / score_total
  } else {
    0.5
  }

  cert_details <- binary_rectangle_regret(pi, rectangle, return_details = TRUE)

  collapsed <- rectangle[["v_l1"]] == rectangle[["v_u1"]] &&
    rectangle[["v_l0"]] == rectangle[["v_u0"]]
  full <- rectangle[["v_l1"]] == 0 &&
    rectangle[["v_l0"]] == 0 &&
    rectangle[["v_u1"]] == 0.25 &&
    rectangle[["v_u0"]] == 0.25

  out <- list(
    pi = pi,
    U_CMR = cert_details$value,
    rectangle = rectangle,
    corners = cert_details$corners,
    corner_regrets = cert_details$corner_regrets,
    binding = cert_details$binding,
    diagnostics = list(
      score_treatment = score_treatment,
      score_control = score_control,
      full_rectangle = full,
      collapsed_rectangle = collapsed
    )
  )

  class(out) <- c("cmr_two_arm", "cmr_binary", "list")
  out
}

cmr_two_arm <- function(y,
                        d,
                        alpha = 0.05,
                        method = c("auto", "bounded", "bernoulli",
                                   "maurer_pontil", "mp", "bernoulli_exact",
                                   "martinez_taboada_ramdas", "mtr",
                                   "unbounded", "unbounded_mom",
                                   "median_of_means", "mom"),
                        beta = NULL,
                        correction = c("bonferroni", "sidak_arms"),
                        normalize = FALSE,
                        lower = NULL,
                        upper = NULL,
                        psi = NULL,
                        na.rm = TRUE,
                        tol = 1e-11) {
  method <- match.arg(method)
  correction <- match.arg(correction)

  if (.cmr_is_unbounded_method(method)) {
    .cmr_check_unbounded_unused_options(
      beta = beta,
      correction = correction,
      normalize = normalize,
      lower = lower,
      upper = upper
    )
    return(cmr_unbounded(
      y = y,
      d = d,
      psi = psi,
      alpha = alpha,
      na.rm = na.rm
    ))
  }

  confidence_set <- rectangle_binary(
    y = y,
    d = d,
    alpha = alpha,
    method = method,
    beta = beta,
    correction = correction,
    normalize = normalize,
    lower = lower,
    upper = upper,
    psi = psi,
    na.rm = na.rm,
    tol = tol
  )

  out <- cmr_two_arm_from_rectangle(confidence_set$rectangle)
  out$confidence_set <- confidence_set
  out$pilot <- list(
    n = confidence_set$n,
    vhat = confidence_set$vhat,
    method = confidence_set$method,
    normalization = confidence_set$normalization
  )
  out$alpha <- confidence_set$alpha
  out$beta <- confidence_set$beta
  out$correction <- confidence_set$correction
  out$method <- confidence_set$method
  out$joint_error_bound <- confidence_set$joint_error_bound
  out$diagnostics$confidence_method <- confidence_set$method
  out$diagnostics$joint_error_bound <- confidence_set$joint_error_bound
  out
}

cmr_binary_from_rectangle <- cmr_two_arm_from_rectangle
cmr_binary <- cmr_two_arm
