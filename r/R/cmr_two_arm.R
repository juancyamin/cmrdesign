# Two-arm Conditional Minimax Regret rule.

#' Two-arm CMR from a variance rectangle
#'
#' Compute the closed-form two-arm CMR allocation for a supplied confidence
#' rectangle over treatment and control variances.
#'
#' @param rectangle Two-arm variance rectangle, either a numeric vector with
#'   names `v_l1`, `v_u1`, `v_l0`, `v_u0` or a compatible rectangle object.
#' @param pi Treatment assignment share.
#' @param return_details If `TRUE`, return corner regrets and binding-corner
#'   information instead of only the maximum regret.
#'
#' @return
#' `cmr_two_arm_from_rectangle()` returns a list of class `cmr_two_arm` with
#'   `pi`, `U_CMR`, the input `rectangle`, rectangle corners, corner regrets,
#'   binding-corner diagnostics, and additional solver diagnostics.
#' `binary_rectangle_corners()` returns the two least-favorable rectangle
#'   corners. `binary_rectangle_regret()` returns the worst regret at `pi`, or
#'   a detailed list when `return_details = TRUE`.
#'
#' @examples
#' rect <- c(v_l1 = 0.02, v_u1 = 0.12, v_l0 = 0.01, v_u0 = 0.08)
#' fit <- cmr_two_arm_from_rectangle(rect)
#' fit$pi
#' fit$U_CMR
#' binary_rectangle_regret(0.5, rect)
#'
#' @family CMR rules
#' @family rectangle helpers
#' @export
binary_rectangle_corners <- function(rectangle) {
  rectangle <- .cmr_check_binary_rectangle(rectangle)
  rbind(
    treatment_high_control_low = c(v1 = rectangle[["v_u1"]], v0 = rectangle[["v_l0"]]),
    treatment_low_control_high = c(v1 = rectangle[["v_l1"]], v0 = rectangle[["v_u0"]])
  )
}

#' @rdname binary_rectangle_corners
#' @export
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

#' @rdname binary_rectangle_corners
#' @export
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

#' Two-arm Conditional Minimax Regret assignment
#'
#' Estimate a finite-sample variance confidence rectangle from pilot data and
#' return the two-arm Conditional Minimax Regret (CMR) assignment.
#'
#' @param y Pilot outcomes. For bounded and Bernoulli methods, outcomes must be
#'   in `[0, 1]` unless `normalize = TRUE`. For unbounded methods, outcomes are
#'   raw numeric values and `psi` is required.
#' @param d Pilot treatment indicator; treatment is `1` and control is `0`.
#' @param alpha Target joint error level for the variance confidence set.
#' @param method Confidence-set method. `"auto"` uses exact Bernoulli bounds for
#'   0/1 outcomes and bounded Maurer-Pontil bounds otherwise. `"bounded"`,
#'   `"maurer_pontil"`, and `"mp"` are synonyms. `"bernoulli"` and
#'   `"bernoulli_exact"` use folded-binomial exact bounds. `"mtr"` and
#'   `"martinez_taboada_ramdas"` use the empirical-Bernstein MTR bounds.
#'   `"unbounded"`, `"unbounded_mom"`, `"median_of_means"`, and `"mom"` dispatch
#'   to the unbounded-outcome median-of-means extension.
#' @param beta Optional endpoint error allocation. If `NULL`, error is split
#'   across lower and upper endpoints using `correction`.
#' @param correction Endpoint error correction, either `"bonferroni"` or
#'   `"sidak_arms"` for two-arm bounded/Bernoulli/proxy workflows.
#' @param normalize If `TRUE`, normalize bounded outcomes to `[0, 1]` before
#'   computing the rectangle.
#' @param lower,upper Optional lower and upper outcome bounds used when
#'   `normalize = TRUE`.
#' @param psi Bounded-kurtosis parameter for unbounded-outcome methods. Provide
#'   a scalar or a treatment/control pair.
#' @param na.rm If `TRUE`, drop rows with missing `y` or `d`.
#' @param tol Numerical tolerance for exact Bernoulli bound inversion.
#'
#' @return
#' A list of class `cmr_two_arm` with treatment share `pi`, regret certificate
#' `U_CMR`, confidence rectangle, pilot summaries, endpoint error allocation,
#' and diagnostics. The object has compact `print()` and `summary()` methods.
#'
#' @examples
#' set.seed(1)
#' d <- rep(c(1, 0), each = 40)
#' y <- c(rbeta(40, 2, 6), rbeta(40, 4, 4))
#'
#' fit <- cmr_two_arm(y, d, alpha = 0.05, method = "bounded")
#' fit
#' summary(fit)
#'
#' @family CMR rules
#' @export
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

#' @rdname binary_rectangle_corners
#' @export
cmr_binary_from_rectangle <- cmr_two_arm_from_rectangle

#' @rdname cmr_two_arm
#' @export
cmr_binary <- cmr_two_arm
