# Bridge-widened rectangles for proxy or delayed-primary-outcome designs.

.cmr_check_zeta_pair <- function(zeta) {
  zeta <- .cmr_check_numeric(zeta, "zeta")
  if (length(zeta) == 1L) {
    zeta <- c("1" = zeta, "0" = zeta)
  } else if (length(zeta) == 2L) {
    if (!is.null(names(zeta)) && all(c("1", "0") %in% names(zeta))) {
      zeta <- zeta[c("1", "0")]
    } else if (!is.null(names(zeta)) && all(c("treatment", "control") %in% names(zeta))) {
      zeta <- c("1" = zeta[["treatment"]], "0" = zeta[["control"]])
    } else {
      names(zeta) <- c("1", "0")
    }
  } else {
    .cmr_stop("`zeta` must be a scalar or a length-two treatment/control vector.")
  }
  if (any(zeta < 0)) {
    .cmr_stop("`zeta` must be nonnegative.")
  }
  zeta
}

.cmr_widen_sd_interval <- function(v_l, v_u, zeta) {
  s_l <- sqrt(v_l)
  s_u <- sqrt(v_u)
  c(
    lower = max(0, s_l - zeta)^2,
    upper = min(0.5, s_u + zeta)^2
  )
}

#' Proxy or delayed-outcome confidence rectangle
#'
#' Construct a primary-outcome variance rectangle by estimating a proxy-outcome
#' rectangle and widening each arm's standard-deviation interval by `zeta`.
#'
#' @param proxy_y Pilot proxy or delayed-primary outcomes.
#' @param d Pilot treatment indicator; treatment is `1` and control is `0`.
#' @param zeta Nonnegative standard-deviation bridge radius. Provide a scalar
#'   shared across arms or a treatment/control pair.
#' @param alpha Target joint error level.
#' @param method Confidence-set method. `"auto"` chooses exact Bernoulli bounds
#'   for 0/1 outcomes and bounded Maurer-Pontil bounds otherwise.
#' @param beta Optional endpoint error allocation. If `NULL`, error is split
#'   according to `correction`.
#' @param correction Endpoint error correction, either `"bonferroni"` or
#'   `"sidak_arms"`.
#' @param normalize If `TRUE`, normalize bounded proxy outcomes to `[0, 1]`
#'   before computing variances.
#' @param lower,upper Optional lower and upper outcome bounds used when
#'   `normalize = TRUE`.
#' @param na.rm If `TRUE`, drop rows with missing `proxy_y` or `d`.
#' @param tol Numerical tolerance for exact Bernoulli bound inversion.
#'
#' @return
#' A list of class `cmr_proxy_rectangle` and `cmr_binary_rectangle` with the
#' widened primary-outcome rectangle, the underlying proxy confidence set,
#' `zeta`, bridge metadata, endpoint error allocation, pilot summaries, and
#' method metadata.
#'
#' @examples
#' set.seed(11)
#' d <- rep(c(1, 0), each = 30)
#' proxy_y <- c(rbeta(30, 2, 6), rbeta(30, 4, 4))
#' rectangle_proxy(proxy_y, d, zeta = 0.05)
#'
#' @family rectangle helpers
#' @export
rectangle_proxy <- function(proxy_y,
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
  method <- match.arg(method)
  correction <- match.arg(correction)
  zeta <- .cmr_check_zeta_pair(zeta)
  proxy_set <- rectangle_two_arm(
    y = proxy_y,
    d = d,
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

  treatment <- .cmr_widen_sd_interval(
    proxy_set$rectangle[["v_l1"]],
    proxy_set$rectangle[["v_u1"]],
    zeta[["1"]]
  )
  control <- .cmr_widen_sd_interval(
    proxy_set$rectangle[["v_l0"]],
    proxy_set$rectangle[["v_u0"]],
    zeta[["0"]]
  )
  rectangle <- c(
    v_l1 = treatment[["lower"]],
    v_u1 = treatment[["upper"]],
    v_l0 = control[["lower"]],
    v_u0 = control[["upper"]]
  )

  treatment_result <- proxy_set$treatment
  control_result <- proxy_set$control
  treatment_result$L_proxy <- proxy_set$rectangle[["v_l1"]]
  treatment_result$U_proxy <- proxy_set$rectangle[["v_u1"]]
  treatment_result$L <- rectangle[["v_l1"]]
  treatment_result$U <- rectangle[["v_u1"]]
  control_result$L_proxy <- proxy_set$rectangle[["v_l0"]]
  control_result$U_proxy <- proxy_set$rectangle[["v_u0"]]
  control_result$L <- rectangle[["v_l0"]]
  control_result$U <- rectangle[["v_u0"]]

  out <- .cmr_binary_rectangle_object(
    rectangle = rectangle,
    treatment = treatment_result,
    control = control_result,
    alpha = proxy_set$alpha,
    beta = proxy_set$beta,
    correction = proxy_set$correction,
    method = paste0("proxy_", proxy_set$method),
    normalization = proxy_set$normalization
  )
  out$proxy_confidence_set <- proxy_set
  out$zeta <- zeta
  out$bridge <- list(
    assumption = "abs(primary_sd - proxy_sd) <= zeta by arm",
    proxy_rectangle = proxy_set$rectangle,
    primary_rectangle = rectangle
  )
  class(out) <- c("cmr_proxy_rectangle", class(out))
  out
}

#' @rdname rectangle_proxy
#' @export
rectangle_delayed_outcome <- rectangle_proxy
