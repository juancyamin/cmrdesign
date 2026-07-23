testthat::test_that("activation thresholds match reference values", {
  testthat::expect_equal(activation_threshold_bounded(0.05), 72L)
  testthat::expect_equal(activation_threshold_bounded(0.10), 60L)
  testthat::expect_equal(activation_threshold_bounded(0.01), 96L)
  testthat::expect_equal(activation_threshold_bernoulli(0.05), 4L)
})

testthat::test_that("design-only pilot planning applies break-even cap", {
  plan <- cmr_plan(
    n = 1000,
    sigma1 = 0.5,
    sigma0 = 0.25,
    alpha = 0.05,
    method = "bounded",
    desired_pilot = 100,
    accounting = "design_only"
  )

  testthat::expect_equal(plan$band$activation_threshold, 72L)
  testthat::expect_equal(plan$band$break_even_share, 0.1, tolerance = 1e-12)
  testthat::expect_equal(plan$default_two_thirds_power, 100L)
  testthat::expect_equal(plan$desired_status, "above_break_even_cap")
})

testthat::test_that("pooled pilot planning keeps activation but drops design-only cap", {
  plan <- cmr_plan(
    n = 1000,
    sigma1 = 0.5,
    sigma0 = 0.25,
    alpha = 0.05,
    method = "bounded",
    desired_pilot = 100,
    accounting = "pooled"
  )

  testthat::expect_true(is.infinite(plan$band$break_even_total))
  testthat::expect_equal(plan$desired_status, "inside_viability_band")
})

