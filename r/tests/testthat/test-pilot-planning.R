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
  # The paper's band is 72 <= m <= 100 in this example: the cap is feasible.
  testthat::expect_equal(plan$band$max_feasible, 100L)
  testthat::expect_equal(plan$desired_status, "inside_viability_band")
  testthat::expect_equal(plan$two_thirds_status, "inside_viability_band")
})

testthat::test_that("strict_upper = TRUE excludes a pilot equal to the break-even cap", {
  plan <- cmr_plan(
    n = 1000,
    sigma1 = 0.5,
    sigma0 = 0.25,
    desired_pilot = 100,
    strict_upper = TRUE
  )

  testthat::expect_equal(plan$band$max_feasible, 98L)
  testthat::expect_equal(plan$desired_status, "above_break_even_cap")
  testthat::expect_equal(plan$two_thirds_status, "above_break_even_cap")
})

testthat::test_that("viability band reproduces the paper's worked examples", {
  two_to_one <- pilot_viability_band(n = 1000, sigma1 = 0.5, sigma0 = 0.25)
  testthat::expect_equal(c(two_to_one$min_feasible, two_to_one$max_feasible), c(72L, 100L))

  strict_level <- pilot_viability_band(n = 1000, sigma1 = 0.5, sigma0 = 0.25, alpha = 0.01)
  testthat::expect_equal(c(strict_level$min_feasible, strict_level$max_feasible), c(96L, 100L))

  testthat::expect_equal(cmr_plan(600, 0.5, 0.25)$default_two_thirds_power, 72)
  testthat::expect_equal(cmr_plan(10000, 0.5, 0.25)$default_two_thirds_power, 466)
})

testthat::test_that("two-thirds status reports where the n^(2/3) size falls", {
  above <- cmr_plan(n = 3000, sigma1 = 0.18, sigma0 = 0.28)
  testthat::expect_equal(above$default_two_thirds_power, 210)
  testthat::expect_equal(above$two_thirds_status, "above_break_even_cap")

  pooled <- cmr_plan(n = 3000, sigma1 = 0.18, sigma0 = 0.28, accounting = "pooled")
  testthat::expect_equal(pooled$two_thirds_status, "inside_viability_band")

  below <- cmr_plan(n = 300, sigma1 = 0.5, sigma0 = 0.1)
  testthat::expect_equal(below$default_two_thirds_power, 46)
  testthat::expect_equal(below$two_thirds_status, "below_activation_threshold")
})

testthat::test_that("a pilot is never inside an empty band", {
  # With n = 50 no bounded-outcome pilot can activate, so the band is empty.
  plan <- cmr_plan(n = 50, sigma1 = 0.5, sigma0 = 0.1, accounting = "pooled", desired_pilot = 10)
  testthat::expect_false(plan$band$nonempty)
  testthat::expect_equal(plan$desired_status, "below_activation_threshold")
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

