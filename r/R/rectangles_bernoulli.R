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

rectangle_bernoulli_two_arm <- rectangle_bernoulli_binary
