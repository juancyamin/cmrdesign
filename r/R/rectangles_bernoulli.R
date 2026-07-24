# Exact Bernoulli folded-binomial confidence rectangles.

.cmr_bernoulli_validate_m <- function(m, name = "m") {
  .cmr_check_scalar_integer(m, name, lower = 2L)
}

.cmr_bernoulli_rho <- function(v) {
  v <- .cmr_check_variance(v, "v")
  if (length(v) != 1L) {
    .cmr_stop("`v` must be a scalar.")
  }
  disc <- sqrt(pmax(0, 1 - 4 * v))
  rho <- 2 * v / (1 + disc)
  if (v >= 0.25) {
    rho <- 0.5
  }
  rho
}

.cmr_folded_sample_variance <- function(j, m) {
  m <- .cmr_bernoulli_validate_m(m)
  j <- .cmr_check_scalar_integer(j, "j", lower = 0L)
  if (j > floor(m / 2)) {
    .cmr_stop("`j` cannot exceed floor(m / 2).")
  }
  j * (m - j) / (m * (m - 1))
}

.cmr_folded_count <- function(y, na.rm = TRUE) {
  y <- .cmr_clean_outcome_01(y, na.rm = na.rm)
  if (!.cmr_is_dummy(y, na.rm = FALSE)) {
    .cmr_stop("Bernoulli exact bounds require a 0/1 outcome.")
  }
  m <- length(y)
  if (m < 2L) {
    .cmr_stop("At least two observations are required.")
  }
  x <- sum(round(y))
  j <- min(x, m - x)
  list(j = as.integer(j), x = as.integer(x), m = as.integer(m))
}

#' Folded-binomial distribution for Bernoulli sample variances
#'
#' Probability mass and tail probabilities for the folded count that determines
#' the exact Bernoulli sample variance.
#'
#' @param v Bernoulli variance in `[0, 1/4]`.
#' @param m Arm sample size, at least 2.
#'
#' @return
#' `folded_binomial_pmf()` returns a named probability vector over folded
#' counts `0, ..., floor(m / 2)`. `folded_binomial_tails()` returns a list with
#' lower and upper cumulative tail probabilities.
#'
#' @examples
#' folded_binomial_pmf(v = 0.20, m = 8)
#' folded_binomial_tails(v = 0.20, m = 8)
#'
#' @family rectangle helpers
#' @export
folded_binomial_pmf <- function(v, m) {
  v <- .cmr_check_variance(v, "v")
  if (length(v) != 1L) {
    .cmr_stop("`v` must be a scalar.")
  }
  m <- .cmr_bernoulli_validate_m(m)
  rho <- .cmr_bernoulli_rho(v)
  j <- 0:floor(m / 2)

  p_left <- stats::dbinom(j, size = m, prob = rho)
  p_right <- stats::dbinom(m - j, size = m, prob = rho)
  p_right[2 * j == m] <- 0
  pmf <- p_left + p_right
  pmf <- pmf / sum(pmf)
  names(pmf) <- as.character(j)
  pmf
}

#' @rdname folded_binomial_pmf
#' @export
folded_binomial_tails <- function(v, m) {
  pmf <- folded_binomial_pmf(v, m)
  list(
    lower = cumsum(pmf),
    upper = rev(cumsum(rev(pmf)))
  )
}

.cmr_bernoulli_upper_bound <- function(j, m, beta_u, tol = 1e-11) {
  m <- .cmr_bernoulli_validate_m(m)
  j <- .cmr_check_scalar_integer(j, "j", lower = 0L)
  beta_u <- .cmr_check_tail_error(beta_u, "beta_u")
  if (j > floor(m / 2)) {
    .cmr_stop("`j` cannot exceed floor(m / 2).")
  }
  if (beta_u <= 0) {
    return(0.25)
  }

  tail_at <- function(v) folded_binomial_tails(v, m)$lower[j + 1L]
  if (tail_at(0.25) > beta_u) {
    return(0.25)
  }
  if (tail_at(0) <= beta_u) {
    return(0)
  }

  lo <- 0
  hi <- 0.25
  while (hi - lo > tol) {
    mid <- (lo + hi) / 2
    if (tail_at(mid) > beta_u) {
      lo <- mid
    } else {
      hi <- mid
    }
  }
  .cmr_clip(hi, 0, 0.25)
}

.cmr_bernoulli_lower_bound <- function(j, m, beta_l, tol = 1e-11) {
  m <- .cmr_bernoulli_validate_m(m)
  j <- .cmr_check_scalar_integer(j, "j", lower = 0L)
  beta_l <- .cmr_check_tail_error(beta_l, "beta_l")
  if (j > floor(m / 2)) {
    .cmr_stop("`j` cannot exceed floor(m / 2).")
  }
  if (beta_l <= 0) {
    return(0)
  }

  tail_at <- function(v) folded_binomial_tails(v, m)$upper[j + 1L]
  if (tail_at(0) > beta_l) {
    return(0)
  }
  if (tail_at(0.25) <= beta_l) {
    return(0.25)
  }

  lo <- 0
  hi <- 0.25
  while (hi - lo > tol) {
    mid <- (lo + hi) / 2
    if (tail_at(mid) > beta_l) {
      hi <- mid
    } else {
      lo <- mid
    }
  }
  .cmr_clip(lo, 0, 0.25)
}

#' Exact Bernoulli variance bounds
#'
#' Exact one-arm variance confidence bounds for Bernoulli outcomes using the
#' folded-binomial distribution of the sample variance.
#'
#' @param y One-arm Bernoulli outcomes coded as `0` and `1`.
#' @param beta_l One-sided endpoint error for the lower variance bound.
#' @param beta_u One-sided endpoint error for the upper variance bound.
#' @param na.rm If `TRUE`, drop missing outcomes.
#' @param tol Numerical tolerance for endpoint inversion.
#'
#' @return
#' A list with lower bound `L`, upper bound `U`, folded-binomial variance
#' estimate `vhat`, method name, sample size `n`, and folded-count details in
#' `statistic`.
#'
#' @examples
#' y <- c(1, 0, 1, 1, 0, 0, 1, 0)
#' variance_bounds_bernoulli_exact(y, beta_l = 0.025, beta_u = 0.025)
#'
#' @family rectangle helpers
#' @export
variance_bounds_bernoulli_exact <- function(y,
                                            beta_l,
                                            beta_u,
                                            na.rm = TRUE,
                                            tol = 1e-11) {
  beta_l <- .cmr_check_tail_error(beta_l, "beta_l")
  beta_u <- .cmr_check_tail_error(beta_u, "beta_u")
  fc <- .cmr_folded_count(y, na.rm = na.rm)

  raw_vhat <- .cmr_folded_sample_variance(fc$j, fc$m)
  list(
    L = .cmr_bernoulli_lower_bound(fc$j, fc$m, beta_l, tol = tol),
    U = .cmr_bernoulli_upper_bound(fc$j, fc$m, beta_u, tol = tol),
    vhat = .cmr_clip(raw_vhat, 0, 0.25),
    method = "bernoulli",
    n = fc$m,
    statistic = list(
      j = fc$j,
      x = fc$x,
      m = fc$m,
      raw_sample_variance = raw_vhat,
      beta_l = beta_l,
      beta_u = beta_u
    )
  )
}

#' Two-arm confidence rectangles
#'
#' Construct a two-arm variance confidence rectangle from pilot data. These are
#' expert helpers used by `cmr_two_arm()` and related extension functions.
#'
#' @param y Pilot outcomes.
#' @param d Pilot treatment indicator; treatment is `1` and control is `0`.
#' @param alpha Target joint error level.
#' @param method Confidence-set method. `"auto"` chooses exact Bernoulli bounds
#'   for 0/1 outcomes and bounded Maurer–Pontil bounds otherwise.
#' @param beta Optional endpoint error allocation. If `NULL`, error is split
#'   according to `correction`.
#' @param correction Endpoint error correction, either `"bonferroni"` or
#'   `"sidak_arms"` for two-arm workflows.
#' @param normalize If `TRUE`, normalize bounded outcomes to `[0, 1]` before
#'   computing variances.
#' @param lower,upper Optional lower and upper outcome bounds used when
#'   `normalize = TRUE`.
#' @param psi Bounded-kurtosis parameter used only when `method` is an
#'   unbounded-outcome method.
#' @param na.rm If `TRUE`, drop rows with missing `y` or `d`.
#' @param tol Numerical tolerance for exact Bernoulli bound inversion.
#'
#' @return
#' A rectangle object. Bounded and Bernoulli methods return a
#' `cmr_binary_rectangle`; unbounded methods return a
#' `cmr_unbounded_rectangle`. The object contains the numeric `rectangle`,
#' one-arm bound details, endpoint error allocation, pilot sample sizes and
#' variance estimates, and method metadata.
#'
#' @examples
#' d <- rep(c(1, 0), each = 6)
#' y <- c(1, 0, 1, 1, 0, 1, 0, 0, 1, 0, 0, 1)
#' rectangle_two_arm(y, d, method = "bernoulli")
#' rectangle_binary(y, d, method = "auto")
#'
#' @family rectangle helpers
#' @export
rectangle_bernoulli_binary <- function(y,
                                       d,
                                       alpha = 0.05,
                                       beta = NULL,
                                       correction = c("bonferroni", "sidak_arms"),
                                       na.rm = TRUE,
                                       tol = 1e-11) {
  correction <- match.arg(correction)
  alpha <- .cmr_check_alpha(alpha)
  beta <- .cmr_resolve_beta(alpha = alpha, beta = beta, correction = correction)
  pilot <- .cmr_split_binary_pilot(y, d, na.rm = na.rm)

  treatment <- variance_bounds_bernoulli_exact(
    pilot$y1,
    beta_l = beta[["beta_l1"]],
    beta_u = beta[["beta_u1"]],
    na.rm = FALSE,
    tol = tol
  )
  control <- variance_bounds_bernoulli_exact(
    pilot$y0,
    beta_l = beta[["beta_l0"]],
    beta_u = beta[["beta_u0"]],
    na.rm = FALSE,
    tol = tol
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
    method = "bernoulli",
    normalization = NULL
  )
}

#' @rdname rectangle_bernoulli_binary
#' @export
rectangle_binary <- function(y,
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
  pilot <- .cmr_split_binary_pilot(y, d, na.rm = na.rm)

  if (.cmr_is_unbounded_method(method)) {
    .cmr_check_unbounded_unused_options(
      beta = beta,
      correction = correction,
      normalize = normalize,
      lower = lower,
      upper = upper
    )
    return(rectangle_unbounded(
      y = pilot$y,
      d = pilot$d,
      psi = psi,
      alpha = alpha,
      na.rm = FALSE
    ))
  }

  resolved_method <- switch(
    method,
    auto = if (.cmr_is_dummy(pilot$y, na.rm = FALSE)) "bernoulli" else "bounded",
    bounded = "bounded",
    maurer_pontil = "bounded",
    mp = "bounded",
    bernoulli = "bernoulli",
    bernoulli_exact = "bernoulli",
    martinez_taboada_ramdas = "martinez_taboada_ramdas",
    mtr = "martinez_taboada_ramdas"
  )

  if (resolved_method == "bernoulli") {
    return(rectangle_bernoulli_binary(
      y = pilot$y,
      d = pilot$d,
      alpha = alpha,
      beta = beta,
      correction = correction,
      na.rm = FALSE,
      tol = tol
    ))
  }

  rectangle_bounded_binary(
    y = pilot$y,
    d = pilot$d,
    alpha = alpha,
    method = resolved_method,
    beta = beta,
    correction = correction,
    normalize = normalize,
    lower = lower,
    upper = upper,
    na.rm = FALSE
  )
}

#' @rdname rectangle_bernoulli_binary
#' @export
rectangle_two_arm <- function(y,
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
  rectangle_binary(
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
}

#' @rdname rectangle_bounded_binary
#' @export
rectangle_bounded_two_arm <- function(y,
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
  rectangle_bounded_binary(
    y = y,
    d = d,
    alpha = alpha,
    method = method,
    beta = beta,
    correction = correction,
    normalize = normalize,
    lower = lower,
    upper = upper,
    na.rm = na.rm
  )
}

#' @rdname rectangle_bernoulli_binary
#' @export
rectangle_bernoulli_two_arm <- rectangle_bernoulli_binary
