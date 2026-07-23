testthat::test_that("unbounded MoM variance bounds use paired blocks", {
  y <- rep(c(0, 2), 180)
  bounds <- variance_bounds_unbounded_mom(y, alpha = 0.05, psi = 1)
  rho <- sqrt(2 * (1 + 1) / 6)

  testthat::expect_true(bounds$active)
  testthat::expect_equal(bounds$statistic$k, 30L)
  testthat::expect_equal(bounds$statistic$b, 6L)
  testthat::expect_equal(bounds$statistic$n_pairs, 180L)
  testthat::expect_equal(bounds$statistic$used_pairs, 180L)
  testthat::expect_equal(bounds$vhat, 2, tolerance = 1e-12)
  testthat::expect_equal(bounds$L, 2 / (1 + rho), tolerance = 1e-12)
  testthat::expect_equal(bounds$U, 2 / (1 - rho), tolerance = 1e-12)
  testthat::expect_true(bounds$U > 0.25)
})

testthat::test_that("unbounded CMR accepts finite variance rectangles above one quarter", {
  rect <- c(v_l1 = 1, v_u1 = 4, v_l0 = 9, v_u0 = 16)
  fit <- cmr_unbounded_from_rectangle(rect)

  testthat::expect_s3_class(fit, "cmr_unbounded")
  testthat::expect_equal(fit$pi, 0.3, tolerance = 1e-12)
  testthat::expect_true(fit$U_CMR >= 0)
  testthat::expect_true(fit$diagnostics$unbounded_outcomes)
})

testthat::test_that("unbounded applied API and two-arm dispatch agree", {
  y1 <- rep(c(0, 2), 180)
  y0 <- rep(c(0, 4), 180)
  y <- c(y1, y0)
  d <- c(rep(1, length(y1)), rep(0, length(y0)))

  rect <- rectangle_unbounded(y, d, psi = 1, alpha = 0.05)
  direct <- cmr_unbounded(y, d, psi = 1, alpha = 0.05)
  dispatched <- cmr_two_arm(y, d, method = "unbounded", psi = 1, alpha = 0.05)

  testthat::expect_s3_class(rect, "cmr_unbounded_rectangle")
  testthat::expect_true(rect$active)
  testthat::expect_true(rect$rectangle[["v_u1"]] > 0.25)
  testthat::expect_equal(direct$pi, dispatched$pi, tolerance = 1e-12)
  testthat::expect_equal(direct$U_CMR, dispatched$U_CMR, tolerance = 1e-12)
  testthat::expect_equal(direct$method, "unbounded_mom")
  testthat::expect_equal(dispatched$confidence_set$status, "active")
})

testthat::test_that("unbounded API falls back to balance without finite certificate", {
  y <- rep(c(0, 2), 20)
  d <- rep(c(1, 0), each = 20)
  fit <- cmr_unbounded(y, d, psi = 1, alpha = 0.05)

  testthat::expect_equal(fit$pi, 0.5)
  testthat::expect_true(is.infinite(fit$U_CMR))
  testthat::expect_false(fit$confidence_set$active)
  testthat::expect_match(fit$confidence_set$status, "pilot_too_small")
  testthat::expect_true(fit$diagnostics$no_finite_certificate)
})

testthat::test_that("unbounded API validates psi and incompatible options", {
  y <- rep(c(0, 2), 180)
  d <- rep(c(1, 0), each = 180)

  testthat::expect_error(cmr_unbounded(y, d, alpha = 0.05), "`psi` is required")
  testthat::expect_error(cmr_unbounded(y, d, psi = 0.9), "at least 1")
  testthat::expect_error(
    cmr_two_arm(y, d, method = "unbounded", psi = 1, normalize = TRUE),
    "raw numeric outcomes"
  )
  testthat::expect_error(
    cmr_two_arm(y, d, method = "unbounded", psi = 1, beta = 0.01),
    "`beta` is not used"
  )
})
