# Two-arm CMR extension for unbounded outcomes with bounded kurtosis.

.cmr_unbounded_methods <- c(
  "unbounded",
  "unbounded_mom",
  "median_of_means",
  "mom"
)

.cmr_is_unbounded_method <- function(method) {
  method %in% .cmr_unbounded_methods
}

.cmr_check_unbounded_unused_options <- function(beta,
                                                correction,
                                                normalize,
                                                lower,
                                                upper) {
  if (!is.null(beta)) {
    .cmr_stop("`beta` is not used with `method = \"unbounded\"`; use `alpha` and `psi`.")
  }
  if (correction != "bonferroni") {
    .cmr_stop("`correction` is not used with `method = \"unbounded\"`.")
  }
  if (isTRUE(normalize) || !is.null(lower) || !is.null(upper)) {
    .cmr_stop("Unbounded-outcome bounds use raw numeric outcomes; do not set `normalize`, `lower`, or `upper`.")
  }
  invisible(TRUE)
}

.cmr_check_psi_scalar <- function(psi, name = "psi") {
  if (is.null(psi)) {
    .cmr_stop("`", name, "` is required for unbounded-outcome bounds.")
  }
  psi <- .cmr_check_numeric(psi, name)
  if (length(psi) != 1L) {
    .cmr_stop("`", name, "` must be a scalar.")
  }
  if (psi < 1) {
    .cmr_stop("`", name, "` must be at least 1.")
  }
  psi
}

.cmr_check_psi_pair <- function(psi) {
  if (is.null(psi)) {
    .cmr_stop("`psi` is required for unbounded-outcome CMR.")
  }
  if (is.list(psi) && !is.data.frame(psi)) {
    psi <- unlist(psi, use.names = TRUE)
  }
  if (!is.numeric(psi) && !is.integer(psi)) {
    .cmr_stop("`psi` must be a scalar or treatment/control pair.")
  }
  names_in <- names(psi)
  psi <- unname(as.numeric(psi))
  if (anyNA(psi) || any(!is.finite(psi))) {
    .cmr_stop("`psi` must contain only finite values.")
  }
  if (any(psi < 1)) {
    .cmr_stop("All `psi` values must be at least 1.")
  }

  if (length(psi) == 1L) {
    return(c("1" = psi, "0" = psi))
  }
  if (length(psi) != 2L) {
    .cmr_stop("`psi` must be a scalar or length-two treatment/control pair.")
  }

  if (!is.null(names_in) && all(names_in != "")) {
    labels <- tolower(names_in)
    treatment <- labels %in% c("1", "treatment", "treated", "d1", "arm1")
    control <- labels %in% c("0", "control", "untreated", "d0", "arm0")
    if (sum(treatment) != 1L || sum(control) != 1L) {
      .cmr_stop(
        "Named `psi` must identify treatment and control, for example ",
        "`c(treatment = ..., control = ...)`."
      )
    }
    return(c("1" = psi[which(treatment)], "0" = psi[which(control)]))
  }

  c("1" = psi[[1L]], "0" = psi[[2L]])
}

.cmr_clean_unbounded_outcome <- function(y, na.rm = TRUE, name = "y") {
  if (is.logical(y)) {
    y <- as.numeric(y)
  }
  if (!is.numeric(y) && !is.integer(y)) {
    .cmr_stop("`", name, "` must be numeric or logical.")
  }
  y <- as.numeric(y)
  if (na.rm) {
    y <- y[!is.na(y)]
  } else if (anyNA(y)) {
    .cmr_stop("`", name, "` contains missing values.")
  }
  if (length(y) == 0L) {
    .cmr_stop("`", name, "` has no observed values.")
  }
  if (any(!is.finite(y))) {
    .cmr_stop("`", name, "` must contain only finite values.")
  }
  y
}

.cmr_unbounded_inactive_bounds <- function(status,
                                           y,
                                           alpha,
                                           psi,
                                           k,
                                           b,
                                           n_pairs,
                                           used_pairs,
                                           vhat = NA_real_,
                                           rho = Inf,
                                           block_means = numeric(0)) {
  list(
    L = NA_real_,
    U = Inf,
    vhat = vhat,
    method = "unbounded_mom",
    n = length(y),
    active = FALSE,
    status = status,
    statistic = list(
      alpha = alpha,
      psi = psi,
      k = k,
      b = b,
      n_pairs = n_pairs,
      used_pairs = used_pairs,
      discarded_pairs = n_pairs - used_pairs,
      rho = rho,
      vhat = vhat,
      block_means = block_means
    )
  )
}

#' Unbounded-outcome median-of-means variance bounds
#'
#' Compute one-arm median-of-means variance bounds for raw numeric outcomes
#' under a bounded-kurtosis input `psi`.
#'
#' @param y One-arm pilot outcomes.
#' @param alpha Target one-arm error level.
#' @param psi Bounded-kurtosis parameter. Must be at least 1.
#' @param na.rm If `TRUE`, drop missing outcomes.
#'
#' @return
#' A list with lower bound `L`, upper bound `U`, median-of-means variance
#' estimate `vhat`, method name, sample size `n`, activation flag `active`,
#' status string, and block-level statistic details. If the pilot is too small
#' or the relative-error radius is too large, `active = FALSE`, `L = NA`, and
#' `U = Inf`.
#'
#' @examples
#' set.seed(2)
#' y <- rnorm(200)
#' variance_bounds_unbounded_mom(y, alpha = 0.05, psi = 3)
#'
#' @family rectangle helpers
#' @export
variance_bounds_unbounded_mom <- function(y,
                                          alpha = 0.05,
                                          psi = NULL,
                                          na.rm = TRUE) {
  alpha <- .cmr_check_alpha(alpha)
  psi <- .cmr_check_psi_scalar(psi)
  y <- .cmr_clean_unbounded_outcome(y, na.rm = na.rm)

  k <- as.integer(ceiling(8 * log(2 / alpha)))
  n_pairs <- floor(length(y) / 2)
  b <- floor(n_pairs / k)

  if (b < 1L) {
    return(.cmr_unbounded_inactive_bounds(
      status = "pilot_too_small",
      y = y,
      alpha = alpha,
      psi = psi,
      k = k,
      b = b,
      n_pairs = n_pairs,
      used_pairs = 0L
    ))
  }

  pair_index <- seq_len(n_pairs)
  paired <- 0.5 * (y[2L * pair_index] - y[2L * pair_index - 1L])^2
  used_pairs <- k * b
  paired <- paired[seq_len(used_pairs)]
  block_id <- rep(seq_len(k), each = b)
  block_means <- as.numeric(tapply(paired, block_id, mean))
  names(block_means) <- paste0("block_", seq_along(block_means))

  vhat <- stats::median(block_means)
  rho <- sqrt(2 * (psi + 1) / b)

  if (rho >= 1) {
    return(.cmr_unbounded_inactive_bounds(
      status = "relative_error_at_least_one",
      y = y,
      alpha = alpha,
      psi = psi,
      k = k,
      b = b,
      n_pairs = n_pairs,
      used_pairs = used_pairs,
      vhat = vhat,
      rho = rho,
      block_means = block_means
    ))
  }

  if (vhat <= 0) {
    return(.cmr_unbounded_inactive_bounds(
      status = "zero_mom_variance",
      y = y,
      alpha = alpha,
      psi = psi,
      k = k,
      b = b,
      n_pairs = n_pairs,
      used_pairs = used_pairs,
      vhat = vhat,
      rho = rho,
      block_means = block_means
    ))
  }

  list(
    L = vhat / (1 + rho),
    U = vhat / (1 - rho),
    vhat = vhat,
    method = "unbounded_mom",
    n = length(y),
    active = TRUE,
    status = "active",
    statistic = list(
      alpha = alpha,
      psi = psi,
      k = k,
      b = b,
      n_pairs = n_pairs,
      used_pairs = used_pairs,
      discarded_pairs = n_pairs - used_pairs,
      rho = rho,
      vhat = vhat,
      block_means = block_means
    )
  )
}

.cmr_check_unbounded_rectangle <- function(rectangle) {
  if (is.list(rectangle) && !is.null(rectangle$rectangle)) {
    rectangle <- rectangle$rectangle
  }
  required <- c("v_l1", "v_u1", "v_l0", "v_u0")
  rectangle <- .cmr_check_named_vector(rectangle, required, "rectangle")
  rectangle <- .cmr_check_nonnegative(rectangle, "rectangle", allow_infinite = FALSE)
  names(rectangle) <- required
  if (rectangle[["v_l1"]] > rectangle[["v_u1"]] + 1e-12) {
    .cmr_stop("Treatment lower endpoint cannot exceed treatment upper endpoint.")
  }
  if (rectangle[["v_l0"]] > rectangle[["v_u0"]] + 1e-12) {
    .cmr_stop("Control lower endpoint cannot exceed control upper endpoint.")
  }
  rectangle
}

.cmr_unbounded_rectangle_corners <- function(rectangle) {
  rectangle <- .cmr_check_unbounded_rectangle(rectangle)
  rbind(
    treatment_high_control_low = c(v1 = rectangle[["v_u1"]], v0 = rectangle[["v_l0"]]),
    treatment_low_control_high = c(v1 = rectangle[["v_l1"]], v0 = rectangle[["v_u0"]])
  )
}

.cmr_unbounded_regret <- function(pi, v1, v0) {
  pi <- .cmr_check_probability(pi, "pi", allow_boundary = TRUE)
  v1 <- .cmr_check_nonnegative(v1, "v1", allow_infinite = FALSE)
  v0 <- .cmr_check_nonnegative(v0, "v0", allow_infinite = FALSE)
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

#' Unbounded-outcome CMR from a variance rectangle
#'
#' Compute the closed-form two-arm CMR allocation for a supplied nonnegative
#' variance rectangle for unbounded outcomes.
#'
#' @param rectangle Two-arm nonnegative variance rectangle with names `v_l1`,
#'   `v_u1`, `v_l0`, and `v_u0`.
#'
#' @return
#' A list of class `cmr_unbounded` and `cmr_two_arm` with treatment share `pi`,
#' CMR certificate `U_CMR`, rectangle, corner regrets, binding diagnostics, and
#' method metadata.
#'
#' @examples
#' rect <- c(v_l1 = 0.5, v_u1 = 1.4, v_l0 = 0.2, v_u0 = 1.0)
#' cmr_unbounded_from_rectangle(rect)
#'
#' @family CMR rules
#' @family rectangle helpers
#' @export
cmr_unbounded_from_rectangle <- function(rectangle) {
  rectangle <- .cmr_check_unbounded_rectangle(rectangle)

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

  corners <- .cmr_unbounded_rectangle_corners(rectangle)
  regret_plus <- .cmr_unbounded_regret(
    pi = pi,
    v1 = corners["treatment_high_control_low", "v1"],
    v0 = corners["treatment_high_control_low", "v0"]
  )
  regret_minus <- .cmr_unbounded_regret(
    pi = pi,
    v1 = corners["treatment_low_control_high", "v1"],
    v0 = corners["treatment_low_control_high", "v0"]
  )
  corner_regrets <- c(
    treatment_high_control_low = regret_plus,
    treatment_low_control_high = regret_minus
  )
  binding <- ifelse(
    abs(regret_plus - regret_minus) <= 1e-10,
    "both",
    ifelse(regret_plus > regret_minus,
           "treatment_high_control_low",
           "treatment_low_control_high")
  )

  collapsed <- rectangle[["v_l1"]] == rectangle[["v_u1"]] &&
    rectangle[["v_l0"]] == rectangle[["v_u0"]]

  out <- list(
    pi = pi,
    U_CMR = max(corner_regrets),
    rectangle = rectangle,
    corners = corners,
    corner_regrets = corner_regrets,
    binding = binding,
    diagnostics = list(
      score_treatment = score_treatment,
      score_control = score_control,
      collapsed_rectangle = collapsed,
      unbounded_outcomes = TRUE
    ),
    method = "unbounded_mom"
  )

  class(out) <- c("cmr_unbounded", "cmr_two_arm", "list")
  out
}

#' Unbounded-outcome confidence rectangle
#'
#' Construct a two-arm median-of-means variance rectangle for raw numeric
#' outcomes under bounded-kurtosis inputs.
#'
#' @param y Pilot outcomes.
#' @param d Pilot treatment indicator; treatment is `1` and control is `0`.
#' @param psi Bounded-kurtosis parameter, either a scalar shared across arms or
#'   a treatment/control pair.
#' @param alpha Target joint error level.
#' @param na.rm If `TRUE`, drop rows with missing `y` or `d`.
#'
#' @return
#' A list of class `cmr_unbounded_rectangle` with `rectangle` when active,
#' one-arm treatment and control bound objects, pilot summaries, block
#' diagnostics, `psi`, and `status`. If either arm is inactive, `rectangle` is
#' `NULL` and `status` explains why.
#'
#' @examples
#' set.seed(3)
#' d <- rep(c(1, 0), each = 220)
#' y <- c(rnorm(220, sd = 1.3), rnorm(220, sd = 0.8))
#' rectangle_unbounded(y, d, psi = 3)
#'
#' @family rectangle helpers
#' @export
rectangle_unbounded <- function(y,
                                d,
                                psi = NULL,
                                alpha = 0.05,
                                na.rm = TRUE) {
  alpha <- .cmr_check_alpha(alpha)
  psi <- .cmr_check_psi_pair(psi)
  pilot <- .cmr_split_binary_pilot(y, d, na.rm = na.rm)

  treatment <- variance_bounds_unbounded_mom(
    pilot$y1,
    alpha = alpha,
    psi = psi[["1"]],
    na.rm = FALSE
  )
  control <- variance_bounds_unbounded_mom(
    pilot$y0,
    alpha = alpha,
    psi = psi[["0"]],
    na.rm = FALSE
  )

  active <- isTRUE(treatment$active) && isTRUE(control$active)
  status <- "active"
  rectangle <- NULL
  if (active) {
    rectangle <- c(
      v_l1 = treatment$L,
      v_u1 = treatment$U,
      v_l0 = control$L,
      v_u0 = control$U
    )
    rectangle <- .cmr_check_unbounded_rectangle(rectangle)
  } else {
    status_parts <- character()
    if (!isTRUE(treatment$active)) {
      status_parts <- c(status_parts, paste0("treatment:", treatment$status))
    }
    if (!isTRUE(control$active)) {
      status_parts <- c(status_parts, paste0("control:", control$status))
    }
    status <- paste(status_parts, collapse = ";")
  }

  out <- list(
    rectangle = rectangle,
    treatment = treatment,
    control = control,
    alpha = alpha,
    beta = NULL,
    correction = NULL,
    joint_error_bound = alpha,
    method = "unbounded_mom",
    n = c(n1 = treatment$n, n0 = control$n),
    vhat = c(vhat1 = treatment$vhat, vhat0 = control$vhat),
    rho = c(rho1 = treatment$statistic$rho, rho0 = control$statistic$rho),
    k = c(k1 = treatment$statistic$k, k0 = control$statistic$k),
    b = c(b1 = treatment$statistic$b, b0 = control$statistic$b),
    psi = c(psi1 = psi[["1"]], psi0 = psi[["0"]]),
    active = active,
    status = status,
    normalization = NULL
  )
  class(out) <- c("cmr_unbounded_rectangle", "list")
  out
}

#' Unbounded-outcome CMR assignment
#'
#' Estimate a median-of-means variance rectangle from raw pilot outcomes and
#' return the unbounded-outcome CMR assignment.
#'
#' @inheritParams rectangle_unbounded
#'
#' @return
#' A list of class `cmr_unbounded` and `cmr_two_arm`. If both one-arm bounds are
#' active, the object contains `pi`, finite `U_CMR`, rectangle, pilot summaries,
#' and diagnostics. If the pilot is inactive, the function returns balance
#' (`pi = 0.5`) with `U_CMR = Inf` and diagnostics explaining the fallback.
#'
#' @examples
#' set.seed(4)
#' d <- rep(c(1, 0), each = 220)
#' y <- c(rnorm(220, sd = 1.3), rnorm(220, sd = 0.8))
#' cmr_unbounded(y, d, psi = 3)
#'
#' @family CMR rules
#' @export
cmr_unbounded <- function(y,
                          d,
                          psi = NULL,
                          alpha = 0.05,
                          na.rm = TRUE) {
  confidence_set <- rectangle_unbounded(
    y = y,
    d = d,
    psi = psi,
    alpha = alpha,
    na.rm = na.rm
  )

  if (isTRUE(confidence_set$active)) {
    out <- cmr_unbounded_from_rectangle(confidence_set$rectangle)
  } else {
    out <- list(
      pi = 0.5,
      U_CMR = Inf,
      rectangle = NULL,
      corners = NULL,
      corner_regrets = NULL,
      binding = NULL,
      diagnostics = list(
        active = FALSE,
        status = confidence_set$status,
        no_finite_certificate = TRUE,
        unbounded_outcomes = TRUE
      ),
      method = "unbounded_mom"
    )
    class(out) <- c("cmr_unbounded", "cmr_two_arm", "list")
  }

  out$confidence_set <- confidence_set
  out$pilot <- list(
    n = confidence_set$n,
    vhat = confidence_set$vhat,
    rho = confidence_set$rho,
    k = confidence_set$k,
    b = confidence_set$b,
    psi = confidence_set$psi,
    method = confidence_set$method,
    active = confidence_set$active,
    status = confidence_set$status,
    normalization = NULL
  )
  out$alpha <- confidence_set$alpha
  out["beta"] <- list(NULL)
  out["correction"] <- list(NULL)
  out$method <- confidence_set$method
  out$joint_error_bound <- confidence_set$joint_error_bound
  out$diagnostics$confidence_method <- confidence_set$method
  out$diagnostics$joint_error_bound <- confidence_set$joint_error_bound
  out$diagnostics$active <- confidence_set$active
  out$diagnostics$status <- confidence_set$status
  out
}
