testthat::test_that("folded binomial PMF is valid over representative grids", {
  for (m in c(2L, 3L, 4L, 7L, 12L)) {
    for (v in c(0, 0.01, 0.10, 0.25)) {
      pmf <- folded_binomial_pmf(v, m)
      testthat::expect_length(pmf, floor(m / 2) + 1L)
      testthat::expect_equal(sum(pmf), 1, tolerance = 1e-12)
      testthat::expect_true(all(pmf >= -1e-14))
    }
  }
})

testthat::test_that("Bernoulli exact one-sided coverage holds on grid checks", {
  beta_l <- 0.05
  beta_u <- 0.05
  for (m in c(2L, 3L, 5L, 8L)) {
    j <- 0:floor(m / 2)
    lower <- vapply(j, .cmr_bernoulli_lower_bound, numeric(1), m = m, beta_l = beta_l)
    upper <- vapply(j, .cmr_bernoulli_upper_bound, numeric(1), m = m, beta_u = beta_u)

    for (v in seq(0, 0.25, length.out = 21L)) {
      pmf <- folded_binomial_pmf(v, m)
      lower_miss <- sum(pmf[lower > v + 1e-9])
      upper_miss <- sum(pmf[upper < v - 1e-9])
      testthat::expect_lte(lower_miss, beta_l + 1e-8)
      testthat::expect_lte(upper_miss, beta_u + 1e-8)
    }
  }
})

testthat::test_that("auto method dispatches to Bernoulli for dummy outcomes", {
  y_binary <- c(0, 1, 0, 1, 0, 0, 0, 1)
  d <- c(1, 1, 1, 1, 0, 0, 0, 0)
  rect_binary <- rectangle_two_arm(y_binary, d, alpha = 0.05, method = "auto")
  testthat::expect_equal(rect_binary$method, "bernoulli")

  y_bounded <- c(0.1, 0.9, 0.2, 0.7, 0.3, 0.4, 0.5, 0.6)
  rect_bounded <- rectangle_two_arm(y_bounded, d, alpha = 0.05, method = "auto")
  testthat::expect_equal(rect_bounded$method, "bounded")
})

testthat::test_that("auto method dispatch checks the raw scale before normalization", {
  y_two_valued <- c(2, 5, 2, 5, 5, 2, 5, 2)
  d <- c(1, 1, 1, 1, 0, 0, 0, 0)

  rect <- rectangle_two_arm(
    y_two_valued,
    d,
    alpha = 0.05,
    method = "auto",
    normalize = TRUE
  )
  testthat::expect_equal(rect$method, "bounded")
})
