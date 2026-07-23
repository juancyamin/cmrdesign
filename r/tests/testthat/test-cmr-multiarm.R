testthat::test_that("multi-arm objective, oracle, and Neyman agree at optimum", {
  variances <- c("0" = 0.04, "1" = 0.09, "2" = 0.16)
  pi <- assign_multiarm_neyman(variances)

  testthat::expect_equal(sum(pi), 1, tolerance = 1e-12)
  testthat::expect_equal(
    multiarm_variance_objective(pi, variances),
    multiarm_oracle_variance(variances),
    tolerance = 1e-12
  )
  testthat::expect_equal(multiarm_regret(pi, variances), 0, tolerance = 1e-12)
})

testthat::test_that("multi-arm with one treatment reduces to two-arm CMR", {
  rect_two <- c(v_l1 = 0.01, v_u1 = 0.09, v_l0 = 0.04, v_u0 = 0.16)
  rect_multi <- c(v_l0 = 0.04, v_u0 = 0.16, v_l1 = 0.01, v_u1 = 0.09)

  fit_two <- cmr_two_arm_from_rectangle(rect_two)
  fit_multi <- cmr_multiarm_from_rectangle(rect_multi)

  testthat::expect_equal(fit_multi$pi[["1"]], fit_two$pi, tolerance = 1e-6)
  testthat::expect_equal(fit_multi$pi[["0"]], 1 - fit_two$pi, tolerance = 1e-6)
  testthat::expect_equal(fit_multi$U_CMR, fit_two$U_CMR, tolerance = 1e-6)
})

testthat::test_that("full multi-arm rectangle returns no-information allocation", {
  K <- 4L
  rect <- c(v_l0 = 0, v_u0 = 0.25)
  for (k in seq_len(K)) {
    rect[paste0("v_l", k)] <- 0
    rect[paste0("v_u", k)] <- 0.25
  }

  fit <- cmr_multiarm_from_rectangle(rect)
  expected <- c("0" = 1 / (1 + sqrt(K)))
  for (k in seq_len(K)) {
    expected[as.character(k)] <- 1 / (sqrt(K) * (1 + sqrt(K)))
  }

  testthat::expect_equal(fit$pi[names(expected)], expected, tolerance = 1e-5)
  testthat::expect_true(fit$diagnostics$full_rectangle)
  testthat::expect_equal(fit$diagnostics$solver, "full_rectangle_closed_form")
})

testthat::test_that("collapsed multi-arm rectangle uses closed form", {
  rect <- c(v_l0 = 0.04, v_u0 = 0.04, v_l1 = 0.09, v_u1 = 0.09)
  fit <- cmr_multiarm_from_rectangle(rect)

  testthat::expect_true(fit$diagnostics$collapsed_rectangle)
  testthat::expect_equal(fit$diagnostics$solver, "collapsed_closed_form")
  testthat::expect_equal(fit$U_CMR, 0, tolerance = 1e-12)
})

testthat::test_that("shrinking a multi-arm rectangle weakly lowers certificate", {
  big <- c(v_l0 = 0, v_u0 = 0.25, v_l1 = 0, v_u1 = 0.25, v_l2 = 0, v_u2 = 0.25)
  small <- c(v_l0 = 0.02, v_u0 = 0.08, v_l1 = 0.04, v_u1 = 0.12, v_l2 = 0.01, v_u2 = 0.07)

  fit_big <- cmr_multiarm_from_rectangle(big)
  fit_small <- cmr_multiarm_from_rectangle(small)

  testthat::expect_lte(fit_small$U_CMR, fit_big$U_CMR + 1e-8)
})
