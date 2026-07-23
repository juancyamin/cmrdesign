testthat::test_that("MTR bounds match regression values", {
  y <- rep(seq(0.05, 0.95, by = 0.10), 50)
  bounds <- variance_bounds_martinez_taboada_ramdas(
    y,
    beta_l = 0.0125,
    beta_u = 0.0125
  )

  testthat::expect_equal(bounds$method, "martinez_taboada_ramdas")
  testthat::expect_equal(bounds$n, length(y))
  testthat::expect_equal(bounds$L, 0.04690604657062841, tolerance = 1e-12)
  testthat::expect_equal(bounds$U, 0.10320241415971833, tolerance = 1e-12)
})

testthat::test_that("MTR is available through the applied API", {
  y <- c(rep(seq(0.05, 0.95, by = 0.10), 10),
         rep(seq(0.10, 0.90, by = 0.10), 12))
  d <- c(rep(1, 100), rep(0, 108))
  fit <- cmr_two_arm(y, d, alpha = 0.10, method = "mtr")

  testthat::expect_s3_class(fit, "cmr_two_arm")
  testthat::expect_equal(fit$method, "martinez_taboada_ramdas")
  testthat::expect_true(fit$U_CMR >= 0)
})

