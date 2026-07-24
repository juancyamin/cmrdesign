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

.expect_formal_names <- function(fun, expected) {
  testthat::expect_identical(names(formals(fun)), expected)
}

.expect_default <- function(fun, arg, expected) {
  testthat::expect_equal(formals(fun)[[arg]], expected)
}

testthat::test_that("main applied signatures match reviewed public surface", {
  .expect_formal_names(cmr_two_arm, c(
    "y", "d", "alpha", "method", "beta", "correction", "normalize",
    "lower", "upper", "psi", "na.rm", "tol"
  ))
  .expect_default(cmr_two_arm, "alpha", 0.05)
  .expect_default(cmr_two_arm, "beta", NULL)
  .expect_default(cmr_two_arm, "normalize", FALSE)
  .expect_default(cmr_two_arm, "psi", NULL)
  .expect_default(cmr_two_arm, "na.rm", TRUE)
  .expect_default(cmr_two_arm, "tol", 1e-11)

  .expect_formal_names(cmr_unbounded, c("y", "d", "psi", "alpha", "na.rm"))
  .expect_default(cmr_unbounded, "psi", NULL)
  .expect_default(cmr_unbounded, "alpha", 0.05)
  .expect_default(cmr_unbounded, "na.rm", TRUE)

  .expect_formal_names(cmr_multiarm, c(
    "y", "arm", "alpha", "method", "beta", "control_arm", "normalize",
    "lower", "upper", "na.rm", "tol", "solver_control", "max_vertices"
  ))
  .expect_default(cmr_multiarm, "alpha", 0.05)
  .expect_default(cmr_multiarm, "beta", NULL)
  .expect_default(cmr_multiarm, "control_arm", 0)
  .expect_default(cmr_multiarm, "normalize", FALSE)
  .expect_default(cmr_multiarm, "na.rm", TRUE)
  .expect_default(cmr_multiarm, "tol", 1e-11)
  .expect_default(cmr_multiarm, "max_vertices", 65536L)

  .expect_formal_names(cmr_stratified, c(
    "y", "d", "strata", "strata_share", "alpha", "method", "beta",
    "normalize", "lower", "upper", "na.rm", "tol", "solver_control",
    "max_vertices"
  ))
  .expect_default(cmr_stratified, "alpha", 0.05)
  .expect_default(cmr_stratified, "beta", NULL)
  .expect_default(cmr_stratified, "normalize", FALSE)
  .expect_default(cmr_stratified, "na.rm", TRUE)
  .expect_default(cmr_stratified, "tol", 1e-11)
  .expect_default(cmr_stratified, "max_vertices", 65536L)

  .expect_formal_names(cmr_multiple_outcomes, c(
    "y", "d", "weights", "estimand", "alpha", "method", "beta",
    "na.rm", "tol"
  ))
  .expect_default(cmr_multiple_outcomes, "weights", NULL)
  .expect_default(cmr_multiple_outcomes, "alpha", 0.05)
  .expect_default(cmr_multiple_outcomes, "beta", NULL)
  .expect_default(cmr_multiple_outcomes, "na.rm", TRUE)
  .expect_default(cmr_multiple_outcomes, "tol", 1e-11)

  .expect_formal_names(cmr_proxy, c(
    "proxy_y", "d", "zeta", "alpha", "method", "beta", "correction",
    "normalize", "lower", "upper", "na.rm", "tol"
  ))
  .expect_default(cmr_proxy, "alpha", 0.05)
  .expect_default(cmr_proxy, "beta", NULL)
  .expect_default(cmr_proxy, "normalize", FALSE)
  .expect_default(cmr_proxy, "na.rm", TRUE)
  .expect_default(cmr_proxy, "tol", 1e-11)

  .expect_formal_names(cmr_plan, c(
    "n", "sigma1", "sigma0", "alpha", "method", "input", "accounting",
    "desired_pilot", "strict_upper"
  ))
  .expect_default(cmr_plan, "alpha", 0.05)
  .expect_default(cmr_plan, "desired_pilot", NULL)
  .expect_default(cmr_plan, "strict_upper", TRUE)
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

.expect_cmr_fields <- function(fit, extra = character()) {
  required <- c(
    "pi",
    "U_CMR",
    "rectangle",
    "diagnostics",
    "confidence_set",
    "pilot",
    "alpha",
    "beta",
    "method",
    "joint_error_bound",
    extra
  )
  testthat::expect_true(
    all(required %in% names(fit)),
    info = paste("Missing fields:", paste(setdiff(required, names(fit)), collapse = ", "))
  )
  testthat::expect_true("confidence_method" %in% names(fit$diagnostics))
  testthat::expect_true("joint_error_bound" %in% names(fit$diagnostics))
}

testthat::test_that("main result fields match reviewed contract", {
  set.seed(2718)
  n <- 24L
  d <- c(rep(1, n), rep(0, n))
  y <- c(rbeta(n, 2, 5), rbeta(n, 4, 4))

  fit_two <- cmr_two_arm(y, d, method = "bounded")
  .expect_cmr_fields(fit_two, extra = c("corners", "corner_regrets", "binding", "correction"))

  y_unbounded <- c(rep(c(0, 2), 180), rep(c(0, 4), 180))
  d_unbounded <- c(rep(1, 360), rep(0, 360))
  fit_unbounded <- cmr_unbounded(y_unbounded, d_unbounded, psi = 1)
  .expect_cmr_fields(
    fit_unbounded,
    extra = c("corners", "corner_regrets", "binding", "correction")
  )
  testthat::expect_true("beta" %in% names(fit_unbounded))
  testthat::expect_null(fit_unbounded$beta)
  testthat::expect_true(fit_unbounded$diagnostics$unbounded_outcomes)
  testthat::expect_true(all(c("rho", "status") %in% names(fit_unbounded$pilot)))

  arm <- rep(c(0, 1, 2), each = n)
  y_multiarm <- c(rbeta(n, 4, 4), rbeta(n, 2, 6), rbeta(n, 5, 3))
  fit_multiarm <- cmr_multiarm(y_multiarm, arm, method = "bounded")
  .expect_cmr_fields(
    fit_multiarm,
    extra = c("vertices", "vertex_regrets", "binding_vertices")
  )

  strata <- rep(c("A", "B"), each = 2L * n)
  d_strata <- rep(c(rep(1, n), rep(0, n)), 2)
  y_strata <- c(
    rbeta(n, 2, 6),
    rbeta(n, 4, 4),
    rbeta(n, 5, 3),
    rbeta(n, 3, 5)
  )
  fit_stratified <- cmr_stratified(
    y_strata,
    d_strata,
    strata,
    c(A = 0.45, B = 0.55),
    method = "bounded"
  )
  .expect_cmr_fields(
    fit_stratified,
    extra = c(
      "pi_matrix",
      "sampling_margin",
      "treatment_margin",
      "vertices",
      "vertex_regrets",
      "binding_vertices"
    )
  )

  y_multioutcome <- cbind(y1 = y, y2 = c(rbeta(n, 5, 3), rbeta(n, 3, 5)))
  fit_multioutcome <- cmr_multiple_outcomes(
    y_multioutcome,
    d,
    weights = c(0.6, 0.4),
    method = "bounded"
  )
  .expect_cmr_fields(fit_multioutcome, extra = c("estimand", "weights"))

  fit_proxy <- cmr_proxy(y, d, zeta = 0.05, method = "bounded")
  .expect_cmr_fields(fit_proxy, extra = c("correction", "zeta"))
  testthat::expect_match(fit_proxy$diagnostics$bridge, "abs\\(primary_sd - proxy_sd\\)")

  plan <- cmr_plan(1000, 0.5, 0.25)
  testthat::expect_identical(
    names(plan),
    c(
      "band",
      "suggested_pilot",
      "default_two_thirds_power",
      "desired_pilot",
      "desired_status",
      "recommendation",
      "caveat"
    )
  )
})

testthat::test_that("main error messages are actionable", {
  testthat::expect_error(
    cmr_two_arm(c(0.1, 0.2), 1),
    "`y` and `d` must have the same length"
  )
  testthat::expect_error(
    cmr_unbounded(rep(c(0, 2), 180), c(rep(1, 180), rep(0, 180))),
    "`psi` is required"
  )
  testthat::expect_error(
    cmr_multiarm(c(0.1, 0.2, 0.3, 0.4), c(1, 1, 2, 2)),
    "control arm"
  )
  testthat::expect_error(
    cmr_stratified(c(0.1, 0.2, 0.3, 0.4), c(1, 0, 1, 0), c("A", "A", "B", "B"), c(A = 1)),
    "missing observed strata"
  )
  testthat::expect_error(
    cmr_multiple_outcomes(
      matrix(c(0.1, 0.2, 0.3, 0.4, 0.2, 0.3, 0.4, 0.5), ncol = 2),
      c(1, 1, 0, 0),
      weights = 1
    ),
    "`weights` must have one entry per outcome"
  )
  testthat::expect_error(
    cmr_proxy(c(0.1, 0.2, 0.3, 0.4), c(1, 1, 0, 0), zeta = -0.1),
    "`zeta` must be nonnegative"
  )
  testthat::expect_error(
    cmr_plan(1000, 0.5, 0.25, method = "unbounded"),
    "should be one of"
  )
})
