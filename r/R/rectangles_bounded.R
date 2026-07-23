# Distribution-free bounded-outcome confidence rectangles.

.cmr_sample_variance_01 <- function(y, na.rm = TRUE) {
  y <- .cmr_clean_outcome_01(y, na.rm = na.rm)
  if (length(y) < 2L) {
    .cmr_stop("At least two observations are required to estimate a variance.")
  }
  .cmr_clip(stats::var(y), 0, 0.25)
}

.cmr_binary_rectangle_object <- function(rectangle,
                                         treatment,
                                         control,
                                         alpha,
                                         beta,
                                         correction,
                                         method,
                                         normalization = NULL) {
  rectangle <- .cmr_check_binary_rectangle(rectangle)
  beta <- .cmr_check_beta_vector(beta, alpha = alpha, correction = correction)

  out <- list(
    rectangle = rectangle,
    treatment = treatment,
    control = control,
    alpha = alpha,
    beta = beta,
    correction = correction,
    joint_error_bound = .cmr_joint_error_bound(beta, correction = correction),
    method = method,
    n = c(n1 = treatment$n, n0 = control$n),
    vhat = c(vhat1 = treatment$vhat, vhat0 = control$vhat),
    normalization = normalization
  )
  class(out) <- c("cmr_binary_rectangle", "list")
  out
}

#' Bounded-outcome variance bounds
#'
#' One-arm distribution-free variance confidence bounds for outcomes in
#' `[0, 1]`.
#'
#' @param y Pilot outcomes for one arm.
#' @param beta_l One-sided endpoint error for the lower variance bound.
#' @param beta_u One-sided endpoint error for the upper variance bound.
#' @param na.rm If `TRUE`, drop missing outcomes.
#' @param lower_alpha_split MTR split of the lower-tail error between variance
#'   and mean components.
#' @param c1,c2,c3,c4,c5 Martinez-Taboada-Ramdas tuning constants.
#' @param cs,tilde_cs Logical flags for the MTR predictable-mixture variants.
#'
#' @return
#' A list with lower bound `L`, upper bound `U`, sample variance `vhat`,
#' method name, arm sample size `n`, and method-specific `statistic` details.
#'
#' @examples
#' y <- c(0.10, 0.30, 0.40, 0.20, 0.70, 0.50)
#' variance_bounds_maurer_pontil(y, beta_l = 0.025, beta_u = 0.025)
#'
#' @family rectangle helpers
#' @export
variance_bounds_maurer_pontil <- function(y,
                                          beta_l,
                                          beta_u,
                                          na.rm = TRUE) {
  beta_l <- .cmr_check_tail_error(beta_l, "beta_l")
  beta_u <- .cmr_check_tail_error(beta_u, "beta_u")
  y <- .cmr_clean_outcome_01(y, na.rm = na.rm)
  m <- length(y)
  if (m < 2L) {
    .cmr_stop("At least two observations are required.")
  }

  vhat <- .cmr_sample_variance_01(y, na.rm = FALSE)
  sdhat <- sqrt(vhat)

  lower <- if (beta_l <= 0) {
    0
  } else {
    eta_l <- sqrt(2 * log(1 / beta_l) / (m - 1))
    max(0, sdhat - eta_l)^2
  }

  upper <- if (beta_u <= 0) {
    0.25
  } else {
    eta_u <- sqrt(2 * log(1 / beta_u) / (m - 1))
    (sdhat + eta_u)^2
  }

  list(
    L = .cmr_clip(lower, 0, 0.25),
    U = .cmr_clip(upper, 0, 0.25),
    vhat = vhat,
    method = "bounded",
    n = m,
    statistic = list(
      vhat = vhat,
      sdhat = sdhat,
      beta_l = beta_l,
      beta_u = beta_u
    )
  )
}

.cmr_mtr_psi_e <- function(lambda) {
  -lambda - log1p(-lambda)
}

.cmr_mtr_psi_p <- function(lambda) {
  exp(lambda) - lambda - 1
}

.cmr_check_mtr_constants <- function(c1, c2, c3, c4, c5, lower_alpha_split) {
  c1 <- .cmr_check_numeric(c1, "c1")
  c2 <- .cmr_check_numeric(c2, "c2")
  c3 <- .cmr_check_numeric(c3, "c3")
  c4 <- .cmr_check_numeric(c4, "c4")
  c5 <- .cmr_check_numeric(c5, "c5")
  lower_alpha_split <- .cmr_check_numeric(lower_alpha_split, "lower_alpha_split")

  if (length(c1) != 1L || c1 <= 0 || c1 >= 1) {
    .cmr_stop("`c1` must be a scalar in (0, 1).")
  }
  if (length(c2) != 1L || c2 <= 0) {
    .cmr_stop("`c2` must be a positive scalar.")
  }
  if (length(c3) != 1L || c3 <= 0) {
    .cmr_stop("`c3` must be a positive scalar.")
  }
  if (length(c4) != 1L || c4 < 0 || c4 > 1) {
    .cmr_stop("`c4` must be a scalar in [0, 1].")
  }
  if (length(c5) != 1L || c5 <= 0) {
    .cmr_stop("`c5` must be a positive scalar.")
  }
  if (length(lower_alpha_split) != 1L ||
      lower_alpha_split <= 0 || lower_alpha_split >= 1) {
    .cmr_stop("`lower_alpha_split` must be a scalar in (0, 1).")
  }

  list(
    c1 = c1,
    c2 = c2,
    c3 = c3,
    c4 = c4,
    c5 = c5,
    lower_alpha_split = lower_alpha_split
  )
}

.cmr_mtr_upper_variance <- function(y,
                                    alpha,
                                    c1,
                                    c2,
                                    c3,
                                    c4,
                                    cs = FALSE) {
  n <- length(y)
  sumvarhat <- c2
  summuhat <- c3
  tilde_summuhat <- c4

  aux <- sqrt(2 * log(1 / alpha))
  part1 <- 0
  part2 <- log(1 / alpha)
  sum_lambdas <- 0
  sum_center <- 0

  lambda_path <- numeric(n)
  for (i in seq_len(n)) {
    x <- (y[[i]] - tilde_summuhat / i)^2
    radius <- (x - summuhat / i)^2

    denominator <- if (isTRUE(cs)) {
      sqrt(sumvarhat * log(i + 1))
    } else {
      sqrt(sumvarhat * n / i)
    }
    lambda <- min(aux / denominator, c1)
    lambda_path[[i]] <- lambda

    sum_lambdas <- sum_lambdas + lambda
    sum_center <- sum_center + lambda * x
    center <- sum_center / sum_lambdas
    part1 <- part1 + radius * .cmr_mtr_psi_e(lambda)
    bound_radius <- (part1 + part2) / sum_lambdas

    summuhat <- summuhat + x
    sumvarhat <- sumvarhat + radius
    tilde_summuhat <- tilde_summuhat + y[[i]]
  }

  list(
    center = center,
    radius = bound_radius,
    upper = center + bound_radius,
    lambda_path = lambda_path
  )
}

.cmr_mtr_lower_variance <- function(y,
                                    alpha_variance,
                                    alpha_mean,
                                    c1,
                                    c2,
                                    c3,
                                    c4,
                                    c5,
                                    cs = FALSE,
                                    tilde_cs = TRUE) {
  n <- length(y)
  sumvarhat <- c2
  tilde_sumvarhat <- c3
  tilde_summuhat <- c4

  aux <- sqrt(2 * log(1 / alpha_variance))
  part1 <- 0
  part2 <- log(1 / alpha_variance)
  sum_lambdas <- 0
  sum_center <- 0

  tilde_aux <- sqrt(2 * log(2 / alpha_mean))
  tilde_center_sum <- 0
  tilde_center <- 0
  sum_psi_tilde_lambdas <- 0
  sum_tilde_lambdas <- 0

  sum_at <- 0
  sum_bt <- 0
  sum_ct <- 0
  at <- NA_real_
  bt <- NA_real_
  ct <- NA_real_
  dt <- NA_real_
  rt <- NA_real_
  lambda_path <- numeric(n)
  tilde_lambda_path <- numeric(n)

  for (i in seq_len(n)) {
    x <- (y[[i]] - tilde_center)^2
    radius <- (x - tilde_sumvarhat / i)^2
    varhat <- tilde_sumvarhat / i

    lambda <- 0
    if (sum_tilde_lambdas > 0) {
      threshold <- (log(2 / alpha_mean) +
        varhat * sum_psi_tilde_lambdas) / sum_tilde_lambdas
      if (threshold < 1) {
        denominator <- if (isTRUE(cs)) {
          sqrt(sumvarhat * log(i + 1))
        } else {
          sqrt(sumvarhat * n / i)
        }
        lambda <- min(aux / denominator, c1)
      }
    }
    lambda_path[[i]] <- lambda

    sum_lambdas <- sum_lambdas + lambda
    sum_center <- sum_center + lambda * x
    part1 <- part1 + radius * .cmr_mtr_psi_e(lambda)

    if (sum_lambdas > 0) {
      center <- sum_center / sum_lambdas
      bound_radius <- (part1 + part2) / sum_lambdas
    } else {
      center <- NA_real_
      bound_radius <- NA_real_
    }

    if (lambda > 0) {
      tilde_at <- sum_psi_tilde_lambdas^2 / sum_tilde_lambdas^2
      tilde_bt <- 2 * log(2 / alpha_mean) *
        sum_psi_tilde_lambdas / sum_tilde_lambdas^2
      tilde_ct <- log(2 / alpha_mean)^2 / sum_tilde_lambdas^2

      dt <- center
      rt <- bound_radius
      sum_at <- sum_at + tilde_at * lambda
      at <- sum_at / sum_lambdas
      sum_bt <- sum_bt + tilde_bt * lambda
      bt <- 1 + sum_bt / sum_lambdas
      sum_ct <- sum_ct + tilde_ct * lambda
      ct <- sum_ct / sum_lambdas
    }

    tilde_radius <- (y[[i]] - tilde_summuhat / i)^2
    tilde_denominator <- if (isTRUE(tilde_cs)) {
      sqrt(tilde_sumvarhat * log(i + 1))
    } else {
      sqrt(tilde_sumvarhat * n / i)
    }
    tilde_lambda <- min(tilde_aux / tilde_denominator, c5)
    tilde_lambda_path[[i]] <- tilde_lambda
    sum_tilde_lambdas <- sum_tilde_lambdas + tilde_lambda
    sum_psi_tilde_lambdas <- sum_psi_tilde_lambdas + .cmr_mtr_psi_p(tilde_lambda)
    tilde_center_sum <- tilde_center_sum + tilde_lambda * y[[i]]
    tilde_center <- tilde_center_sum / sum_tilde_lambdas

    sumvarhat <- sumvarhat + radius
    tilde_summuhat <- tilde_summuhat + y[[i]]
    tilde_sumvarhat <- tilde_sumvarhat + tilde_radius
  }

  lower <- 0
  if (is.finite(dt) && is.finite(rt) && is.finite(at) && at > 0) {
    c_term <- dt - ct - rt
    if (c_term > 0) {
      lower <- (-bt + sqrt(bt^2 + 4 * at * c_term)) / (2 * at)
      lower <- max(lower, 0)
    }
  }

  list(
    center = dt,
    radius = rt,
    lower = lower,
    at = at,
    bt = bt,
    ct = ct,
    lambda_path = lambda_path,
    tilde_lambda_path = tilde_lambda_path
  )
}

#' @rdname variance_bounds_maurer_pontil
#' @export
variance_bounds_martinez_taboada_ramdas <- function(y,
                                                    beta_l,
                                                    beta_u,
                                                    na.rm = TRUE,
                                                    lower_alpha_split = 0.5,
                                                    c1 = 0.5,
                                                    c2 = 0.25^2,
                                                    c3 = 0.25,
                                                    c4 = 0.5,
                                                    c5 = 2,
                                                    cs = FALSE,
                                                    tilde_cs = TRUE) {
  beta_l <- .cmr_check_tail_error(beta_l, "beta_l")
  beta_u <- .cmr_check_tail_error(beta_u, "beta_u")
  constants <- .cmr_check_mtr_constants(
    c1 = c1,
    c2 = c2,
    c3 = c3,
    c4 = c4,
    c5 = c5,
    lower_alpha_split = lower_alpha_split
  )
  y <- .cmr_clean_outcome_01(y, na.rm = na.rm)
  m <- length(y)
  if (m < 2L) {
    .cmr_stop("At least two observations are required.")
  }

  vhat <- .cmr_sample_variance_01(y, na.rm = FALSE)

  if (beta_u <= 0) {
    upper_result <- list(center = NA_real_, radius = NA_real_, upper = 0.25)
  } else {
    upper_result <- .cmr_mtr_upper_variance(
      y = y,
      alpha = beta_u,
      c1 = constants$c1,
      c2 = constants$c2,
      c3 = constants$c3,
      c4 = constants$c4,
      cs = cs
    )
  }

  alpha_lower_variance <- beta_l * constants$lower_alpha_split
  alpha_lower_mean <- beta_l * (1 - constants$lower_alpha_split)
  if (beta_l <= 0) {
    lower_result <- list(
      center = NA_real_,
      radius = NA_real_,
      lower = 0,
      at = NA_real_,
      bt = NA_real_,
      ct = NA_real_
    )
  } else {
    lower_result <- .cmr_mtr_lower_variance(
      y = y,
      alpha_variance = alpha_lower_variance,
      alpha_mean = alpha_lower_mean,
      c1 = constants$c1,
      c2 = constants$c2,
      c3 = constants$c3,
      c4 = constants$c4,
      c5 = constants$c5,
      cs = cs,
      tilde_cs = tilde_cs
    )
  }

  list(
    L = .cmr_clip(lower_result$lower, 0, 0.25),
    U = .cmr_clip(upper_result$upper, 0, 0.25),
    vhat = vhat,
    method = "martinez_taboada_ramdas",
    n = m,
    statistic = list(
      vhat = vhat,
      beta_l = beta_l,
      beta_u = beta_u,
      alpha_lower_variance = alpha_lower_variance,
      alpha_lower_mean = alpha_lower_mean,
      lower_alpha_split = constants$lower_alpha_split,
      raw_lower = lower_result$lower,
      raw_upper = upper_result$upper,
      upper_center = upper_result$center,
      upper_radius = upper_result$radius,
      lower_center = lower_result$center,
      lower_radius = lower_result$radius,
      lower_quadratic = c(
        a = lower_result$at,
        b = lower_result$bt,
        c = lower_result$ct
      ),
      constants = constants,
      cs = isTRUE(cs),
      tilde_cs = isTRUE(tilde_cs)
    )
  )
}

.cmr_variance_bounds_by_method <- function(y,
                                           beta_l,
                                           beta_u,
                                           method,
                                           tol = 1e-11) {
  if (method == "bernoulli") {
    return(variance_bounds_bernoulli_exact(
      y,
      beta_l = beta_l,
      beta_u = beta_u,
      na.rm = FALSE,
      tol = tol
    ))
  }
  if (method == "martinez_taboada_ramdas") {
    return(variance_bounds_martinez_taboada_ramdas(
      y,
      beta_l = beta_l,
      beta_u = beta_u,
      na.rm = FALSE
    ))
  }
  variance_bounds_maurer_pontil(
    y,
    beta_l = beta_l,
    beta_u = beta_u,
    na.rm = FALSE
  )
}

#' Bounded two-arm confidence rectangle
#'
#' Construct a two-arm variance confidence rectangle for bounded outcomes using
#' Maurer-Pontil or Martinez-Taboada-Ramdas one-arm bounds.
#'
#' @param y Pilot outcomes.
#' @param d Pilot treatment indicator; treatment is `1` and control is `0`.
#' @param alpha Target joint error level.
#' @param method Bounded-outcome method. `"bounded"`, `"maurer_pontil"`, and
#'   `"mp"` are synonyms; `"martinez_taboada_ramdas"` and `"mtr"` use MTR
#'   bounds.
#' @param beta Optional endpoint error allocation. If `NULL`, error is split
#'   according to `correction`.
#' @param correction Endpoint error correction, either `"bonferroni"` or
#'   `"sidak_arms"`.
#' @param normalize If `TRUE`, normalize outcomes to `[0, 1]` before computing
#'   variances.
#' @param lower,upper Optional lower and upper outcome bounds used when
#'   `normalize = TRUE`.
#' @param na.rm If `TRUE`, drop rows with missing `y` or `d`.
#'
#' @return
#' A `cmr_binary_rectangle` list with `rectangle`, one-arm bound objects for
#' treatment and control, endpoint error allocation, sample sizes, pilot
#' variance estimates, normalization details, and method metadata.
#'
#' @examples
#' d <- rep(c(1, 0), each = 5)
#' y <- c(0.20, 0.40, 0.30, 0.10, 0.60, 0.50, 0.30, 0.20, 0.40, 0.10)
#' rectangle_bounded_binary(y, d, method = "bounded")
#'
#' @family rectangle helpers
#' @export
rectangle_bounded_binary <- function(y,
                                     d,
                                     alpha = 0.05,
                                     method = c("bounded", "maurer_pontil", "mp",
                                                "martinez_taboada_ramdas", "mtr"),
                                     beta = NULL,
                                     correction = c("bonferroni", "sidak_arms"),
                                     normalize = FALSE,
                                     lower = NULL,
                                     upper = NULL,
                                     na.rm = TRUE) {
  method <- match.arg(method)
  correction <- match.arg(correction)
  alpha <- .cmr_check_alpha(alpha)
  beta <- .cmr_resolve_beta(alpha = alpha, beta = beta, correction = correction)
  resolved_method <- switch(
    method,
    bounded = "bounded",
    maurer_pontil = "bounded",
    mp = "bounded",
    martinez_taboada_ramdas = "martinez_taboada_ramdas",
    mtr = "martinez_taboada_ramdas"
  )

  pilot <- .cmr_split_binary_pilot(y, d, na.rm = na.rm)
  normalization <- NULL
  if (normalize) {
    normalized <- .cmr_normalize_01(
      pilot$y,
      lower = lower,
      upper = upper,
      na.rm = FALSE,
      return_params = TRUE
    )
    pilot$y <- normalized$values
    pilot$y1 <- pilot$y[pilot$d == 1L]
    pilot$y0 <- pilot$y[pilot$d == 0L]
    normalization <- list(lower = normalized$lower, upper = normalized$upper)
  }

  treatment <- .cmr_variance_bounds_by_method(
    pilot$y1,
    beta_l = beta[["beta_l1"]],
    beta_u = beta[["beta_u1"]],
    method = resolved_method
  )
  control <- .cmr_variance_bounds_by_method(
    pilot$y0,
    beta_l = beta[["beta_l0"]],
    beta_u = beta[["beta_u0"]],
    method = resolved_method
  )

  rectangle <- c(
    v_l1 = treatment$L,
    v_u1 = treatment$U,
    v_l0 = control$L,
    v_u0 = control$U
  )

  .cmr_binary_rectangle_object(
    rectangle = rectangle,
    treatment = treatment,
    control = control,
    alpha = alpha,
    beta = beta,
    correction = correction,
    method = resolved_method,
    normalization = normalization
  )
}
