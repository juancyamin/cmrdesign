testthat::test_that("multiple-outcome index reduces to two-arm CMR on weighted index", {
  y <- cbind(
    a = c(0.1, 0.9, 0.2, 0.8, 0.3, 0.4, 0.5, 0.6),
    b = c(0.2, 0.7, 0.3, 0.9, 0.4, 0.3, 0.7, 0.5)
  )
  d <- c(1, 1, 1, 1, 0, 0, 0, 0)
  weights <- c(0.25, 0.75)

  fit_index <- cmr_multiple_outcomes(y, d, weights = weights, estimand = "index", method = "bounded")
  fit_manual <- cmr_two_arm(as.numeric(y %*% weights), d, method = "bounded")

  testthat::expect_equal(fit_index$pi, fit_manual$pi, tolerance = 1e-12)
  testthat::expect_equal(fit_index$U_CMR, fit_manual$U_CMR, tolerance = 1e-12)
})

testthat::test_that("co-primary multiple-outcome rectangle is weighted endpoint sum", {
  y <- cbind(
    a = c(0, 1, 0, 1, 1, 0, 0, 1),
    b = c(1, 0, 1, 0, 0, 1, 1, 0)
  )
  d <- c(1, 1, 1, 1, 0, 0, 0, 0)
  weights <- c(a = 0.4, b = 0.6)
  rect <- rectangle_multiple_outcomes(y, d, weights = weights, method = "bernoulli")

  l1 <- sum(weights * vapply(rect$outcome_bounds, function(x) x$treatment$L, numeric(1)))
  u0 <- sum(weights * vapply(rect$outcome_bounds, function(x) x$control$U, numeric(1)))

  testthat::expect_equal(rect$rectangle[["v_l1"]], l1, tolerance = 1e-12)
  testthat::expect_equal(rect$rectangle[["v_u0"]], u0, tolerance = 1e-12)
  testthat::expect_equal(rect$joint_error_bound, 0.05, tolerance = 1e-12)
})

