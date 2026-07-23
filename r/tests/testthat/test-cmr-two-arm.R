testthat::test_that("full rectangle returns balance and global certificate", {
  rect <- c(v_l1 = 0, v_u1 = 0.25, v_l0 = 0, v_u0 = 0.25)
  fit <- cmr_two_arm_from_rectangle(rect)

  testthat::expect_s3_class(fit, "cmr_two_arm")
  testthat::expect_equal(fit$pi, 0.5)
  testthat::expect_equal(fit$U_CMR, 0.25)
  testthat::expect_true(fit$diagnostics$full_rectangle)
})

testthat::test_that("collapsed rectangle returns Neyman and zero certificate", {
  rect <- c(v_l1 = 0.04, v_u1 = 0.04, v_l0 = 0.09, v_u0 = 0.09)
  fit <- cmr_two_arm_from_rectangle(rect)

  testthat::expect_equal(fit$pi, assign_neyman(0.04, 0.09), tolerance = 1e-12)
  testthat::expect_equal(fit$U_CMR, 0, tolerance = 1e-12)
  testthat::expect_true(fit$diagnostics$collapsed_rectangle)
})

testthat::test_that("CMR equalizes the two off-diagonal corner regrets", {
  rect <- c(v_l1 = 0.01, v_u1 = 0.09, v_l0 = 0.04, v_u0 = 0.16)
  fit <- cmr_two_arm_from_rectangle(rect)

  testthat::expect_equal(fit$pi, 0.4, tolerance = 1e-12)
  testthat::expect_equal(
    unname(fit$corner_regrets[1]),
    unname(fit$corner_regrets[2]),
    tolerance = 1e-12
  )
  testthat::expect_equal(fit$U_CMR, max(fit$corner_regrets), tolerance = 1e-12)
})

testthat::test_that("applied two-arm API builds a confidence set", {
  y <- c(0, 1, 0, 1, 1, 1, 0, 0, 0, 0)
  d <- c(1, 1, 1, 1, 1, 0, 0, 0, 0, 0)
  fit <- cmr_two_arm(y, d, alpha = 0.10, method = "bernoulli")

  testthat::expect_s3_class(fit, "cmr_two_arm")
  testthat::expect_s3_class(fit$confidence_set, "cmr_binary_rectangle")
  testthat::expect_named(fit$rectangle, c("v_l1", "v_u1", "v_l0", "v_u0"))
  testthat::expect_true(fit$U_CMR >= 0)
  testthat::expect_true(fit$U_CMR <= 0.25)
  testthat::expect_equal(fit$method, "bernoulli")
})

testthat::test_that("legacy binary aliases remain available", {
  rect <- c(v_l1 = 0, v_u1 = 0.25, v_l0 = 0, v_u0 = 0.25)
  testthat::expect_equal(cmr_binary_from_rectangle(rect)$pi, 0.5)
  y <- c(0, 1, 0, 1, 0, 1, 0, 1)
  d <- c(1, 1, 1, 1, 0, 0, 0, 0)
  testthat::expect_equal(cmr_binary(y, d, method = "bernoulli")$method, "bernoulli")
})

