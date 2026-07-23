testthat::test_that("proxy CMR with zero bridge reduces to two-arm CMR", {
  y <- c(0, 1, 0, 1, 1, 0, 0, 1)
  d <- c(1, 1, 1, 1, 0, 0, 0, 0)

  direct <- cmr_two_arm(y, d, method = "bernoulli")
  proxy <- cmr_proxy(y, d, zeta = 0, method = "bernoulli")

  testthat::expect_equal(proxy$pi, direct$pi, tolerance = 1e-12)
  testthat::expect_equal(proxy$U_CMR, direct$U_CMR, tolerance = 1e-12)
  testthat::expect_equal(proxy$rectangle, direct$rectangle, tolerance = 1e-12)
})

testthat::test_that("large proxy bridge returns the full primary variance space", {
  y <- c(0, 1, 0, 1, 1, 0, 0, 1)
  d <- c(1, 1, 1, 1, 0, 0, 0, 0)
  fit <- cmr_proxy(y, d, zeta = 0.5, method = "bernoulli")

  testthat::expect_equal(fit$rectangle, c(v_l1 = 0, v_u1 = 0.25, v_l0 = 0, v_u0 = 0.25))
  testthat::expect_equal(fit$pi, 0.5)
  testthat::expect_equal(fit$U_CMR, 0.25)
})

