testthat::test_that("CMR results print compactly", {
  y <- c(0, 1, 0, 1, 1, 1, 0, 0, 0, 0)
  d <- c(1, 1, 1, 1, 1, 0, 0, 0, 0, 0)
  fit <- cmr_two_arm(y, d, alpha = 0.10, method = "bernoulli")

  printed <- capture.output(print(fit))
  testthat::expect_match(printed[[1]], "<cmr_two_arm>", fixed = TRUE)
  testthat::expect_true(any(grepl("pi:", printed, fixed = TRUE)))
  testthat::expect_true(any(grepl("U_CMR:", printed, fixed = TRUE)))
  testthat::expect_true(any(grepl("method: bernoulli", printed, fixed = TRUE)))
  testthat::expect_false(any(grepl("confidence_set", printed, fixed = TRUE)))
})

testthat::test_that("CMR summaries expose compact audit fields", {
  y <- c(0, 1, 0, 1, 1, 1, 0, 0, 0, 0)
  d <- c(1, 1, 1, 1, 1, 0, 0, 0, 0, 0)
  fit <- cmr_two_arm(y, d, alpha = 0.10, method = "bernoulli")
  s <- summary(fit)

  testthat::expect_s3_class(s, "summary.cmr_result")
  testthat::expect_equal(s$type, "cmr_two_arm")
  testthat::expect_equal(s$pi, fit$pi)
  testthat::expect_equal(s$U_CMR, fit$U_CMR)
  testthat::expect_equal(s$method, "bernoulli")
  testthat::expect_equal(s$n, 10)
})

testthat::test_that("unbounded fallback print includes status", {
  y <- rep(c(0, 2), 20)
  d <- rep(c(1, 0), each = 20)
  fit <- cmr_unbounded(y, d, psi = 1, alpha = 0.05)

  printed <- capture.output(print(fit))
  testthat::expect_match(printed[[1]], "<cmr_unbounded>", fixed = TRUE)
  testthat::expect_true(any(grepl("U_CMR: Inf", printed, fixed = TRUE)))
  testthat::expect_true(any(grepl("status:", printed, fixed = TRUE)))
  testthat::expect_true(any(grepl("pilot_too_small", printed, fixed = TRUE)))
})

testthat::test_that("multi-arm and stratified results print allocations without internals", {
  multi_rect <- c(v_l0 = 0.02, v_u0 = 0.08,
                  v_l1 = 0.04, v_u1 = 0.12,
                  v_l2 = 0.01, v_u2 = 0.07)
  multi <- cmr_multiarm_from_rectangle(multi_rect)
  multi_printed <- capture.output(print(multi))
  testthat::expect_match(multi_printed[[1]], "<cmr_multiarm>", fixed = TRUE)
  testthat::expect_false(any(grepl("vertex_regrets", multi_printed, fixed = TRUE)))

  strata_share <- c(A = 0.4, B = 0.6)
  strata_rect <- list(
    lower = rbind(treatment = c(A = 0.01, B = 0.04),
                  control = c(A = 0.02, B = 0.03)),
    upper = rbind(treatment = c(A = 0.08, B = 0.12),
                  control = c(A = 0.09, B = 0.10))
  )
  stratified <- cmr_stratified_from_rectangle(strata_rect, strata_share)
  stratified_printed <- capture.output(print(stratified))
  testthat::expect_match(stratified_printed[[1]], "<cmr_stratified>", fixed = TRUE)
  testthat::expect_false(any(grepl("vertex_regrets", stratified_printed, fixed = TRUE)))
})
