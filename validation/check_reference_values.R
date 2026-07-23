#!/usr/bin/env Rscript

suppressPackageStartupMessages(library(cmrdesign))

failures <- character()

record_failure <- function(message) {
  failures <<- c(failures, message)
}

expect_close <- function(actual, expected, label, tolerance = 1e-10) {
  actual <- unname(as.numeric(actual))
  expected <- unname(as.numeric(expected))
  if (length(actual) != length(expected)) {
    record_failure(sprintf(
      "%s length mismatch: got %s, expected %s",
      label,
      length(actual),
      length(expected)
    ))
    return(invisible(FALSE))
  }
  delta <- max(abs(actual - expected))
  if (!is.finite(delta) || delta > tolerance) {
    record_failure(sprintf(
      "%s mismatch: max |actual - expected| = %.17g > %.17g",
      label,
      delta,
      tolerance
    ))
    return(invisible(FALSE))
  }
  invisible(TRUE)
}

expect_equal <- function(actual, expected, label) {
  if (!identical(actual, expected)) {
    record_failure(sprintf(
      "%s mismatch: got %s, expected %s",
      label,
      paste(actual, collapse = ", "),
      paste(expected, collapse = ", ")
    ))
    return(invisible(FALSE))
  }
  invisible(TRUE)
}

run_check <- function(name, expr) {
  tryCatch(
    {
      force(expr)
      message("[PASS] ", name)
    },
    error = function(e) {
      record_failure(sprintf("%s errored: %s", name, conditionMessage(e)))
      message("[FAIL] ", name)
    }
  )
}

reference_regret <- function(pi, v1, v0) {
  v1 / pi + v0 / (1 - pi) - (sqrt(v1) + sqrt(v0))^2
}

reference_two_arm_cmr <- function(rectangle) {
  score_treatment <- sqrt(rectangle[["v_u1"]]) + sqrt(rectangle[["v_l1"]])
  score_control <- sqrt(rectangle[["v_u0"]]) + sqrt(rectangle[["v_l0"]])
  score_total <- score_treatment + score_control
  pi <- if (score_total > 0) score_treatment / score_total else 0.5
  regrets <- c(
    treatment_high_control_low = reference_regret(
      pi,
      rectangle[["v_u1"]],
      rectangle[["v_l0"]]
    ),
    treatment_low_control_high = reference_regret(
      pi,
      rectangle[["v_l1"]],
      rectangle[["v_u0"]]
    )
  )
  list(pi = pi, U_CMR = max(regrets), regrets = regrets)
}

reference_mp_bounds <- function(y, beta_l, beta_u) {
  vhat <- stats::var(y)
  sdhat <- sqrt(max(vhat, 0))
  lower <- if (beta_l <= 0) {
    0
  } else {
    max(0, sdhat - sqrt(2 * log(1 / beta_l) / (length(y) - 1)))^2
  }
  upper <- if (beta_u <= 0) {
    0.25
  } else {
    (sdhat + sqrt(2 * log(1 / beta_u) / (length(y) - 1)))^2
  }
  c(L = max(0, min(lower, 0.25)), U = max(0, min(upper, 0.25)), vhat = vhat)
}

reference_bernoulli_rho <- function(v) {
  if (v >= 0.25) {
    return(0.5)
  }
  2 * v / (1 + sqrt(max(0, 1 - 4 * v)))
}

reference_folded_pmf <- function(v, m) {
  rho <- reference_bernoulli_rho(v)
  j <- 0:floor(m / 2)
  p_left <- stats::dbinom(j, size = m, prob = rho)
  p_right <- stats::dbinom(m - j, size = m, prob = rho)
  p_right[2 * j == m] <- 0
  pmf <- p_left + p_right
  pmf / sum(pmf)
}

run_check("two-arm closed-form CMR", {
  rect <- c(v_l1 = 0.01, v_u1 = 0.09, v_l0 = 0.04, v_u0 = 0.16)
  expected <- reference_two_arm_cmr(rect)
  fit <- cmr_two_arm_from_rectangle(rect)
  expect_close(fit$pi, expected$pi, "two-arm pi", tolerance = 1e-12)
  expect_close(fit$U_CMR, expected$U_CMR, "two-arm U_CMR", tolerance = 1e-12)
  expect_close(
    fit$corner_regrets,
    expected$regrets[names(fit$corner_regrets)],
    "two-arm corner regrets",
    tolerance = 1e-12
  )
})

run_check("MTR archived old-implementation reference values", {
  y <- rep(seq(0.05, 0.95, by = 0.10), 50)
  bounds <- variance_bounds_martinez_taboada_ramdas(
    y,
    beta_l = 0.0125,
    beta_u = 0.0125
  )
  expect_close(bounds$L, 0.04690604657062841, "MTR L", tolerance = 1e-12)
  expect_close(bounds$U, 0.10320241415971833, "MTR U", tolerance = 1e-12)
  expect_close(
    bounds$statistic$upper_center,
    0.08352562992913529,
    "MTR upper center",
    tolerance = 1e-12
  )
  expect_close(
    bounds$statistic$alpha_lower_variance,
    0.00625,
    "MTR alpha lower variance",
    tolerance = 1e-15
  )
  expect_close(
    bounds$statistic$alpha_lower_mean,
    0.00625,
    "MTR alpha lower mean",
    tolerance = 1e-15
  )
})

run_check("exact Bernoulli folded-binomial formula", {
  expected <- reference_folded_pmf(v = 0.10, m = 4)
  actual <- folded_binomial_pmf(v = 0.10, m = 4)
  expect_close(actual, expected, "folded-binomial pmf", tolerance = 1e-12)

  y <- c(0, 1, 0, 0, 1, 0, 0, 0)
  bounds <- variance_bounds_bernoulli_exact(y, beta_l = 0.0125, beta_u = 0.0125)
  expect_close(bounds$vhat, 2 * (8 - 2) / (8 * 7), "folded sample variance")
  expect_equal(bounds$method, "bernoulli", "Bernoulli method")
})

run_check("collapsed shared-control multi-arm reduces to Neyman", {
  variances <- c("0" = 0.04, "1" = 0.09, "2" = 0.16)
  scores <- c("0" = sqrt(2 * variances[["0"]]),
              "1" = sqrt(variances[["1"]]),
              "2" = sqrt(variances[["2"]]))
  expected_pi <- scores / sum(scores)
  rect <- c(v_l0 = 0.04, v_u0 = 0.04,
            v_l1 = 0.09, v_u1 = 0.09,
            v_l2 = 0.16, v_u2 = 0.16)
  fit <- cmr_multiarm_from_rectangle(rect)
  expect_close(fit$pi[names(expected_pi)], expected_pi, "multi-arm collapsed pi")
  expect_close(fit$U_CMR, 0, "multi-arm collapsed U_CMR", tolerance = 1e-9)
})

run_check("collapsed stratified rectangle reduces to stratified Neyman", {
  strata_share <- c(A = 0.6, B = 0.4)
  variances <- matrix(
    c(0.04, 0.09, 0.16, 0.01),
    nrow = 2,
    dimnames = list(c("1", "0"), c("A", "B"))
  )
  scores <- as.vector(t(t(variances) * strata_share))
  scores <- sqrt(scores * rep(strata_share, each = 2))
  names(scores) <- c("1:A", "0:A", "1:B", "0:B")
  expected_pi <- scores / sum(scores)
  rect <- list(lower = variances, upper = variances)
  fit <- cmr_stratified_from_rectangle(rect, strata_share)
  expect_close(
    fit$pi[names(expected_pi)],
    expected_pi,
    "stratified collapsed pi",
    tolerance = 1e-10
  )
  expect_close(fit$U_CMR, 0, "stratified collapsed U_CMR", tolerance = 1e-9)
})

run_check("multiple-outcome co-primary rectangle from independent MP endpoints", {
  pattern_treat <- cbind(
    outcome_1 = c(0.20, 0.40, 0.60, 0.80),
    outcome_2 = c(0.10, 0.20, 0.70, 0.90)
  )
  pattern_control <- cbind(
    outcome_1 = c(0.30, 0.45, 0.55, 0.70),
    outcome_2 = c(0.20, 0.25, 0.35, 0.40)
  )
  y <- rbind(pattern_treat[rep(seq_len(4), 50), ],
             pattern_control[rep(seq_len(4), 50), ])
  d <- c(rep(1, 200), rep(0, 200))
  weights <- c(outcome_1 = 0.7, outcome_2 = 0.3)
  beta <- 0.10 / (4 * ncol(y))
  expected_bounds <- lapply(seq_len(ncol(y)), function(j) {
    list(
      treatment = reference_mp_bounds(y[d == 1, j], beta, beta),
      control = reference_mp_bounds(y[d == 0, j], beta, beta)
    )
  })
  expected_rectangle <- c(
    v_l1 = sum(weights * vapply(expected_bounds, function(x) x$treatment[["L"]], numeric(1))),
    v_u1 = sum(weights * vapply(expected_bounds, function(x) x$treatment[["U"]], numeric(1))),
    v_l0 = sum(weights * vapply(expected_bounds, function(x) x$control[["L"]], numeric(1))),
    v_u0 = sum(weights * vapply(expected_bounds, function(x) x$control[["U"]], numeric(1)))
  )
  fit <- cmr_multiple_outcomes(
    y,
    d,
    weights = weights,
    estimand = "coprimary",
    alpha = 0.10,
    method = "bounded"
  )
  expect_close(
    fit$rectangle[names(expected_rectangle)],
    expected_rectangle,
    "multiple-outcome coprimary rectangle"
  )
})

run_check("proxy bridge widens standard-deviation intervals by zeta", {
  proxy_y <- c(0, 1, 0, 1, 1, 0, 0, 1)
  d <- c(1, 1, 1, 1, 0, 0, 0, 0)
  zeta <- c(treatment = 0.04, control = 0.06)
  fit <- cmr_proxy(proxy_y, d, zeta = zeta, method = "bernoulli", alpha = 0.05)
  proxy_rect <- fit$confidence_set$bridge$proxy_rectangle
  expected <- c(
    v_l1 = max(0, sqrt(proxy_rect[["v_l1"]]) - zeta[["treatment"]])^2,
    v_u1 = min(0.5, sqrt(proxy_rect[["v_u1"]]) + zeta[["treatment"]])^2,
    v_l0 = max(0, sqrt(proxy_rect[["v_l0"]]) - zeta[["control"]])^2,
    v_u0 = min(0.5, sqrt(proxy_rect[["v_u0"]]) + zeta[["control"]])^2
  )
  expect_close(fit$rectangle[names(expected)], expected, "proxy widened rectangle")
})

run_check("Appendix E pilot-planning formulas", {
  expect_close(
    break_even_pilot_share(0.5, 0.25),
    0.1,
    "break-even pilot share",
    tolerance = 1e-12
  )
  expect_equal(activation_threshold_bounded(alpha = 0.05), 72L, "bounded activation")
  expect_equal(activation_threshold_bernoulli(alpha = 0.05), 4L, "bernoulli activation")
  plan <- cmr_plan(
    n = 1000,
    sigma1 = 0.5,
    sigma0 = 0.25,
    alpha = 0.05,
    method = "bounded",
    desired_pilot = 100
  )
  expect_equal(plan$desired_status, "above_break_even_cap", "desired pilot status")
  expect_equal(plan$band$min_feasible, 72L, "planning min feasible")
  expect_equal(plan$band$max_feasible, 98L, "planning max feasible")
})

if (length(failures) > 0) {
  cat("\nReference validation failures:\n", file = stderr())
  cat(paste0("- ", failures, collapse = "\n"), "\n", file = stderr())
  quit(status = 1)
}

message("Reference/provenance validation checks passed.")
