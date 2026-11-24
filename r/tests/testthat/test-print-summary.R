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

testthat::test_that("pilot plans print a short summary", {
  plan <- cmr_plan(n = 3000, sigma1 = 0.18, sigma0 = 0.28, desired_pilot = 120)
  printed <- capture.output(print(plan))

  testthat::expect_match(printed[[1]], "<cmr_pilot_plan>", fixed = TRUE)
  testthat::expect_lte(length(printed), 10L)
  testthat::expect_true(any(grepl("viability band: 72 to 134", printed, fixed = TRUE)))
  testthat::expect_true(any(grepl("210 (above_break_even_cap)", printed, fixed = TRUE)))
  testthat::expect_true(any(grepl("120 (inside_viability_band)", printed, fixed = TRUE)))

  band_printed <- capture.output(print(plan$band))
  testthat::expect_match(band_printed[[1]], "<cmr_pilot_viability_band>", fixed = TRUE)
  testthat::expect_lte(length(band_printed), 8L)

  empty <- capture.output(print(cmr_plan(n = 1000, sigma1 = 0.30, sigma0 = 0.29)))
  testthat::expect_true(any(grepl("viability band: empty", empty, fixed = TRUE)))
})

testthat::test_that("confidence rectangles print a short summary", {
  set.seed(105)
  d <- rep(c(1, 0), each = 30)
  y <- stats::runif(60)

  two_arm <- capture.output(print(rectangle_two_arm(y, d)))
  testthat::expect_match(two_arm[[1]], "<cmr_binary_rectangle>", fixed = TRUE)
  testthat::expect_lte(length(two_arm), 8L)
  testthat::expect_true(any(grepl("v_l1=", two_arm, fixed = TRUE)))

  multiarm <- capture.output(print(rectangle_multiarm(y, rep(0:2, 20))))
  testthat::expect_match(multiarm[[1]], "<cmr_multiarm_rectangle>", fixed = TRUE)
  testthat::expect_true(any(grepl("lower:", multiarm, fixed = TRUE)))

  stratified <- capture.output(print(
    rectangle_stratified(y, d, rep(c("A", "B"), 30), c(A = 0.5, B = 0.5))
  ))
  testthat::expect_match(stratified[[1]], "<cmr_stratified_rectangle>", fixed = TRUE)
  testthat::expect_true(any(grepl("1:A=", stratified, fixed = TRUE)))

  unbounded <- capture.output(print(rectangle_unbounded(stats::rnorm(40), rep(c(1, 0), 20), psi = 3)))
  testthat::expect_true(any(grepl("rectangle: none", unbounded, fixed = TRUE)))
  testthat::expect_true(any(grepl("status:", unbounded, fixed = TRUE)))
})
