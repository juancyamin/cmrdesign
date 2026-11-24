testthat::test_that("balance rules return the no-information allocations", {
  testthat::expect_equal(assign_balance(3), rep(0.5, 3))

  multiarm <- assign_multiarm_balance(4)
  testthat::expect_equal(sum(multiarm), 1)
  testthat::expect_equal(multiarm[["0"]], 1 / (1 + sqrt(4)))
  testthat::expect_equal(unname(multiarm[-1]), rep(1 / (2 * 3), 4))
  testthat::expect_equal(
    unname(multiarm),
    unname(assign_multiarm_neyman(c("0" = 0.25, "1" = 0.25, "2" = 0.25, "3" = 0.25, "4" = 0.25)))
  )

  stratified <- assign_stratified_balance(c(A = 0.4, B = 0.6))
  testthat::expect_identical(names(stratified), c("1:A", "0:A", "1:B", "0:B"))
  testthat::expect_equal(unname(stratified), c(0.2, 0.2, 0.3, 0.3))
})

testthat::test_that("feasible and trimmed Neyman rules agree with their definitions", {
  testthat::expect_equal(assign_feasible_neyman(0.16, 0.04), 2 / 3)
  testthat::expect_equal(assign_trimmed_neyman(0.25, 0.0001, trim = 0.10), 0.90)
  testthat::expect_equal(assign_trimmed_neyman(0.16, 0.04, trim = 0.10), 2 / 3)
  testthat::expect_error(assign_trimmed_neyman(0.16, 0.04, trim = 0.5), "\\[0, 0.5\\)")
})

testthat::test_that("regularized Neyman rules interpolate between balance and Neyman", {
  testthat::expect_equal(assign_additive_regularized_neyman(0.16, 0.04, nu = 0), 2 / 3)
  testthat::expect_equal(assign_additive_regularized_neyman(0.16, 0.04, nu = 1), 0.5)
  between <- assign_additive_regularized_neyman(0.16, 0.04, nu = 0.5)
  testthat::expect_gt(between, 0.5)
  testthat::expect_lt(between, 2 / 3)
  testthat::expect_error(assign_additive_regularized_neyman(0.16, 0.04, nu = -1), "nonnegative")

  testthat::expect_equal(assign_exponential_regularized_neyman(0.16, 0.04, tau = 0), 0.5)
  testthat::expect_equal(assign_exponential_regularized_neyman(0.16, 0.04, tau = 1), 2 / 3)
  testthat::expect_equal(assign_exponential_regularized_neyman(0.16, 0, tau = 1), 0.5)
  testthat::expect_equal(
    assign_exponential_regularized_neyman(0.16, 0, tau = 1, zero_guard = "none"),
    1
  )
  testthat::expect_equal(
    assign_exponential_regularized_neyman(0, 0, tau = 1, zero_guard = "both"),
    0.5
  )
})
