EXPECTED_R_EXPORTS <- c(
  "activation_threshold_bernoulli",
  "activation_threshold_bounded",
  "assign_additive_regularized_neyman",
  "assign_balance",
  "assign_exponential_regularized_neyman",
  "assign_feasible_neyman",
  "assign_multiarm_balance",
  "assign_multiarm_neyman",
  "assign_neyman",
  "assign_stratified_balance",
  "assign_stratified_neyman",
  "assign_trimmed_neyman",
  "binary_rectangle_corners",
  "binary_rectangle_regret",
  "boundary_indicator",
  "boundary_rate",
  "break_even_pilot_share",
  "certificate_valid",
  "cmr_binary",
  "cmr_binary_from_rectangle",
  "cmr_delayed_outcome",
  "cmr_multiarm",
  "cmr_multiarm_from_rectangle",
  "cmr_multiple_outcomes",
  "cmr_plan",
  "cmr_proxy",
  "cmr_stratified",
  "cmr_stratified_from_rectangle",
  "cmr_two_arm",
  "cmr_two_arm_from_rectangle",
  "cmr_unbounded",
  "cmr_unbounded_from_rectangle",
  "coverage_indicator",
  "folded_binomial_pmf",
  "folded_binomial_tails",
  "multiarm_oracle_variance",
  "multiarm_rectangle_vertices",
  "multiarm_regret",
  "multiarm_variance_objective",
  "oracle_variance",
  "pilot_plan",
  "pilot_viability_band",
  "rectangle_bernoulli_binary",
  "rectangle_bernoulli_two_arm",
  "rectangle_binary",
  "rectangle_bounded_binary",
  "rectangle_bounded_two_arm",
  "rectangle_delayed_outcome",
  "rectangle_multiarm",
  "rectangle_multiple_outcomes",
  "rectangle_proxy",
  "rectangle_stratified",
  "rectangle_two_arm",
  "rectangle_unbounded",
  "regret",
  "saving_vs_balance",
  "share_of_oracle_gain",
  "stratified_oracle_variance",
  "stratified_rectangle_vertices",
  "stratified_regret",
  "stratified_variance_objective",
  "variance_bounds_bernoulli_exact",
  "variance_bounds_martinez_taboada_ramdas",
  "variance_bounds_maurer_pontil",
  "variance_bounds_unbounded_mom",
  "variance_objective"
)

testthat::test_that("R namespace exports match reviewed public surface", {
  testthat::expect_setequal(
    getNamespaceExports("cmrdesign"),
    EXPECTED_R_EXPORTS
  )
})

testthat::test_that("aliases remain available", {
  rect <- c(v_l1 = 0, v_u1 = 0.25, v_l0 = 0, v_u0 = 0.25)
  y <- c(0, 1, 0, 1, 0, 1, 0, 1)
  d <- c(1, 1, 1, 1, 0, 0, 0, 0)

  testthat::expect_equal(cmr_binary_from_rectangle(rect), cmr_two_arm_from_rectangle(rect))
  testthat::expect_equal(cmr_binary(y, d, method = "bernoulli"), cmr_two_arm(y, d, method = "bernoulli"))
  testthat::expect_equal(cmr_plan(1000, 0.5, 0.25), pilot_plan(1000, 0.5, 0.25))
  testthat::expect_equal(rectangle_bounded_two_arm(y, d), rectangle_bounded_binary(y, d))
  testthat::expect_equal(rectangle_bernoulli_two_arm(y, d), rectangle_bernoulli_binary(y, d))
})
