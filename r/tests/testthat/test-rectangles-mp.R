testthat::test_that("Maurer-Pontil variance bounds are valid endpoints", {
  y <- rep(c(0, 1), 40)
  bounds <- variance_bounds_maurer_pontil(y, beta_l = 0.0125, beta_u = 0.0125)

  testthat::expect_gte(bounds$L, 0)
  testthat::expect_lte(bounds$U, 0.25)
  testthat::expect_lte(bounds$L, bounds$U)
  testthat::expect_equal(bounds$method, "bounded")
  testthat::expect_equal(bounds$n, length(y))
})

testthat::test_that("bounded two-arm rectangles split treatment and control arms", {
  y <- c(0, 1, 0, 1, 0.2, 0.3, 0.4, 0.5)
  d <- c(1, 1, 1, 1, 0, 0, 0, 0)
  rect <- rectangle_two_arm(y, d, alpha = 0.10, method = "bounded")

  testthat::expect_s3_class(rect, "cmr_binary_rectangle")
  testthat::expect_named(rect$rectangle, c("v_l1", "v_u1", "v_l0", "v_u0"))
  testthat::expect_true(all(rect$rectangle >= 0))
  testthat::expect_true(all(rect$rectangle <= 0.25))
  testthat::expect_lte(rect$rectangle[["v_l1"]], rect$rectangle[["v_u1"]])
  testthat::expect_lte(rect$rectangle[["v_l0"]], rect$rectangle[["v_u0"]])
  testthat::expect_equal(rect$n, c(n1 = 4, n0 = 4))
  testthat::expect_equal(rect$method, "bounded")
})

