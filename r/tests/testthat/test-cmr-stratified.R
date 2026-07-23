testthat::test_that("stratified objective, oracle, and Neyman agree at optimum", {
  s <- c(A = 0.4, B = 0.6)
  variances <- rbind(
    treatment = c(A = 0.04, B = 0.16),
    control = c(A = 0.09, B = 0.01)
  )
  pi <- assign_stratified_neyman(variances, s)

  testthat::expect_equal(sum(pi), 1, tolerance = 1e-12)
  testthat::expect_equal(
    stratified_variance_objective(pi, variances, s),
    stratified_oracle_variance(variances, s),
    tolerance = 1e-12
  )
  testthat::expect_equal(stratified_regret(pi, variances, s), 0, tolerance = 1e-12)
})

testthat::test_that("stratified design with one stratum reduces to two-arm CMR", {
  s <- c(A = 1)
  rectangle <- list(
    lower = rbind(treatment = c(A = 0.01), control = c(A = 0.04)),
    upper = rbind(treatment = c(A = 0.09), control = c(A = 0.16))
  )
  rect_two <- c(v_l1 = 0.01, v_u1 = 0.09, v_l0 = 0.04, v_u0 = 0.16)

  fit_two <- cmr_two_arm_from_rectangle(rect_two)
  fit_stratified <- cmr_stratified_from_rectangle(rectangle, s)

  testthat::expect_equal(fit_stratified$pi[["1:A"]], fit_two$pi, tolerance = 1e-6)
  testthat::expect_equal(fit_stratified$pi[["0:A"]], 1 - fit_two$pi, tolerance = 1e-6)
  testthat::expect_equal(fit_stratified$U_CMR, fit_two$U_CMR, tolerance = 1e-6)
})

testthat::test_that("full stratified rectangle returns representative balance", {
  s <- c(A = 0.2, B = 0.3, C = 0.5)
  rectangle <- list(
    lower = matrix(0, nrow = 2L, ncol = 3L,
                   dimnames = list(c("treatment", "control"), names(s))),
    upper = matrix(0.25, nrow = 2L, ncol = 3L,
                   dimnames = list(c("treatment", "control"), names(s)))
  )
  fit <- cmr_stratified_from_rectangle(rectangle, s)
  expected <- rep(s / 2, each = 2L)
  names(expected) <- c("1:A", "0:A", "1:B", "0:B", "1:C", "0:C")

  testthat::expect_equal(fit$pi[names(expected)], expected, tolerance = 1e-5)
  testthat::expect_equal(fit$sampling_margin, s, tolerance = 1e-5)
  testthat::expect_equal(unname(fit$treatment_margin), rep(0.5, length(s)), tolerance = 1e-5)
  testthat::expect_true(fit$diagnostics$full_rectangle)
  testthat::expect_equal(fit$diagnostics$solver, "full_rectangle_closed_form")
})

testthat::test_that("collapsed stratified rectangle uses closed form", {
  s <- c(A = 1)
  rectangle <- list(
    lower = rbind(treatment = c(A = 0.04), control = c(A = 0.09)),
    upper = rbind(treatment = c(A = 0.04), control = c(A = 0.09))
  )
  fit <- cmr_stratified_from_rectangle(rectangle, s)

  testthat::expect_true(fit$diagnostics$collapsed_rectangle)
  testthat::expect_equal(fit$diagnostics$solver, "collapsed_closed_form")
  testthat::expect_equal(fit$U_CMR, 0, tolerance = 1e-12)
})

testthat::test_that("shrinking a stratified rectangle weakly lowers certificate", {
  s <- c(A = 0.4, B = 0.6)
  big <- list(
    lower = matrix(0, nrow = 2L, ncol = 2L,
                   dimnames = list(c("treatment", "control"), names(s))),
    upper = matrix(0.25, nrow = 2L, ncol = 2L,
                   dimnames = list(c("treatment", "control"), names(s)))
  )
  small <- list(
    lower = rbind(treatment = c(A = 0.01, B = 0.04),
                  control = c(A = 0.02, B = 0.03)),
    upper = rbind(treatment = c(A = 0.08, B = 0.12),
                  control = c(A = 0.09, B = 0.10))
  )

  fit_big <- cmr_stratified_from_rectangle(big, s)
  fit_small <- cmr_stratified_from_rectangle(small, s)

  testthat::expect_lte(fit_small$U_CMR, fit_big$U_CMR + 1e-8)
})
