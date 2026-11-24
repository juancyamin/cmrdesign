testthat::test_that("regret is zero at the Neyman allocation and positive elsewhere", {
  pi_star <- assign_neyman(0.20, 0.05)
  testthat::expect_equal(pi_star, 2 / 3)
  testthat::expect_equal(regret(pi_star, 0.20, 0.05), 0, tolerance = 1e-14)
  testthat::expect_equal(
    regret(0.5, 0.20, 0.05),
    variance_objective(0.5, 0.20, 0.05) - oracle_variance(0.20, 0.05)
  )
  testthat::expect_equal(regret(0.5, 0.20, 0.05), (sqrt(0.20) - sqrt(0.05))^2)
  testthat::expect_equal(assign_neyman(0, 0), 0.5)
  testthat::expect_identical(regret(0, 0.1, 0.1), Inf)
})

testthat::test_that("unit-scale helpers reject variances above 1/4 unless scale is nonnegative", {
  testthat::expect_error(regret(0.5, 2, 1), "must lie in \\[0, 1/4\\]")
  testthat::expect_equal(regret(0.5, 4, 1, scale = "nonnegative"), 1)
  testthat::expect_equal(oracle_variance(4, 1, scale = "nonnegative"), 9)
  testthat::expect_equal(assign_neyman(4, 1, scale = "nonnegative"), 2 / 3)
  testthat::expect_equal(variance_objective(0.5, 4, 1, scale = "nonnegative"), 10)
  testthat::expect_error(regret(0.5, -1, 1, scale = "nonnegative"), "nonnegative")
})

testthat::test_that("certificate and coverage checks agree with the rectangle", {
  rect <- c(v_l1 = 0.05, v_u1 = 0.15, v_l0 = 0.02, v_u0 = 0.10)
  fit <- cmr_two_arm_from_rectangle(rect)
  inside <- c(v1 = 0.10, v0 = 0.05)
  outside <- c(v1 = 0.24, v0 = 0.001)

  testthat::expect_true(coverage_indicator(rect, inside))
  testthat::expect_false(coverage_indicator(rect, outside))
  testthat::expect_true(certificate_valid(fit$pi, fit$U_CMR, inside))
  testthat::expect_false(certificate_valid(fit$pi, fit$U_CMR, outside))

  # The certificate binds at both off-diagonal corners.
  testthat::expect_equal(regret(fit$pi, 0.15, 0.02), fit$U_CMR)
  testthat::expect_equal(regret(fit$pi, 0.05, 0.10), fit$U_CMR)
})

testthat::test_that("diagnostics can audit an unbounded-outcome fit", {
  rect <- c(v_l1 = 0.5, v_u1 = 1.4, v_l0 = 0.2, v_u0 = 1.0)
  fit <- cmr_unbounded_from_rectangle(rect)
  truth <- c(v1 = 1.0, v0 = 0.5)

  testthat::expect_error(coverage_indicator(rect, truth), "must lie in \\[0, 1/4\\]")
  testthat::expect_true(coverage_indicator(rect, truth, scale = "nonnegative"))
  testthat::expect_true(certificate_valid(fit$pi, fit$U_CMR, truth, scale = "nonnegative"))
  testthat::expect_gte(saving_vs_balance(fit$pi, 1.0, 0.5, scale = "nonnegative"), -1)
  testthat::expect_equal(
    share_of_oracle_gain(assign_neyman(4, 1, scale = "nonnegative"), 4, 1, scale = "nonnegative"),
    1
  )
})

testthat::test_that("savings and oracle-gain shares have the right benchmarks", {
  testthat::expect_equal(saving_vs_balance(0.5, 0.20, 0.05), 0)
  testthat::expect_equal(share_of_oracle_gain(assign_neyman(0.20, 0.05), 0.20, 0.05), 1)
  testthat::expect_equal(share_of_oracle_gain(0.5, 0.20, 0.05), 0)
  testthat::expect_true(is.na(share_of_oracle_gain(0.5, 0.10, 0.10)))
  testthat::expect_equal(
    saving_vs_balance(2 / 3, 0.20, 0.05),
    1 - oracle_variance(0.20, 0.05) / variance_objective(0.5, 0.20, 0.05)
  )
})

testthat::test_that("boundary helpers flag allocations at 0 and 1", {
  testthat::expect_identical(boundary_indicator(c(0, 0.5, 1)), c(TRUE, FALSE, TRUE))
  testthat::expect_identical(boundary_indicator(c(0.01, 0.5), tol = 0.02), c(TRUE, FALSE))
  testthat::expect_equal(boundary_rate(c(0, 0.5, 1, 0.3)), 0.5)
  testthat::expect_error(boundary_indicator(0.5, tol = 0.5), "\\[0, 0.5\\)")
})
