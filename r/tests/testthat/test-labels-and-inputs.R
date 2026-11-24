testthat::test_that("multi-arm pilots accept arm labels that start with v", {
  set.seed(101)
  y <- c(stats::rbeta(60, 4, 4), stats::rbeta(60, 2, 6), stats::rbeta(60, 5, 3))
  for (labels in list(
    c("control", "variant_a", "variant_b"),
    c("control", "v1", "v2"),
    c("control", "video", "vaccine")
  )) {
    arm <- rep(labels, each = 60)
    fit <- cmr_multiarm(y, arm, control_arm = "control", method = "bounded")
    testthat::expect_identical(names(fit$pi), c("0", labels[-1]))
    testthat::expect_identical(names(fit$pilot$n), c("0", labels[-1]))
    testthat::expect_equal(sum(fit$pi), 1, tolerance = 1e-12)
  }

  reference <- cmr_multiarm(y, rep(c(0, 1, 2), each = 60), method = "bounded")
  relabeled <- cmr_multiarm(
    y,
    rep(c("control", "variant_a", "variant_b"), each = 60),
    control_arm = "control",
    method = "bounded"
  )
  testthat::expect_equal(unname(relabeled$pi), unname(reference$pi))
  testthat::expect_equal(relabeled$U_CMR, reference$U_CMR)
})

testthat::test_that("the v prefix is removed only for v0, v1, ... variance names", {
  prefixed <- assign_multiarm_neyman(c(v0 = 0.05, v1 = 0.10, v2 = 0.04))
  testthat::expect_identical(names(prefixed), c("0", "1", "2"))

  kept <- assign_multiarm_neyman(c("0" = 0.05, vaccine = 0.10, video = 0.04))
  testthat::expect_identical(names(kept), c("0", "vaccine", "video"))

  rect <- rbind("0" = c(0.02, 0.08), vaccine = c(0.04, 0.12), v2 = c(0.01, 0.07))
  colnames(rect) <- c("lower", "upper")
  fit <- cmr_multiarm_from_rectangle(rect)
  testthat::expect_identical(names(fit$pi), c("0", "vaccine", "v2"))

  balance <- assign_multiarm_balance(c("0", "variant_a", "variant_b"))
  testthat::expect_identical(names(balance), c("0", "variant_a", "variant_b"))
})

testthat::test_that("unnamed matrix rectangles use positional arm labels", {
  rect <- cbind(lower = c(0.02, 0.04, 0.01), upper = c(0.08, 0.12, 0.07))
  fit <- cmr_multiarm_from_rectangle(rect)
  testthat::expect_identical(names(fit$pi), c("0", "1", "2"))
})

testthat::test_that("stratum labels may contain colons", {
  set.seed(102)
  y <- stats::runif(160)
  d <- rep(c(1, 0), 80)
  plain <- cmr_stratified(y, d, rep(c("a", "b"), each = 80), c(a = 0.4, b = 0.6))
  colon_labels <- c("age:18-30", "age:31+")
  share <- stats::setNames(c(0.4, 0.6), colon_labels)
  fit <- cmr_stratified(y, d, rep(colon_labels, each = 80), share)

  testthat::expect_identical(colnames(fit$pilot$n), colon_labels)
  testthat::expect_equal(unname(fit$pilot$n), unname(plain$pilot$n))
  testthat::expect_equal(unname(fit$pi), unname(plain$pi))
  testthat::expect_identical(
    names(fit$pi),
    c("1:age:18-30", "0:age:18-30", "1:age:31+", "0:age:31+")
  )

  counts <- stats::setNames(c(40, 60), colon_labels)
  allocation <- realize_allocation(fit, strata_counts = counts)
  testthat::expect_equal(sum(allocation$counts), 100L)
})

testthat::test_that("a scalar beta is accepted in every two-arm workflow", {
  set.seed(103)
  d <- rep(c(1, 0), each = 60)
  y <- c(stats::rbeta(60, 0.5, 0.5), stats::rbeta(60, 8, 8))
  named <- c(beta_l1 = 0.01, beta_u1 = 0.01, beta_l0 = 0.01, beta_u0 = 0.01)

  testthat::expect_equal(
    cmr_two_arm(y, d, beta = 0.01)$rectangle,
    cmr_two_arm(y, d, beta = named)$rectangle
  )
  testthat::expect_equal(cmr_proxy(y, d, zeta = 0.02, beta = 0.01)$beta, named)
  testthat::expect_error(cmr_two_arm(y, d, beta = 0.02), "exceeds `alpha`")

  outcomes <- cbind(y, rev(y))
  index_fit <- cmr_multiple_outcomes(outcomes, d, estimand = "index", beta = 0.01)
  testthat::expect_equal(index_fit$beta, named)
  coprimary_fit <- cmr_multiple_outcomes(outcomes, d, estimand = "coprimary", beta = 0.005)
  testthat::expect_equal(coprimary_fit$beta, 0.005)
})

testthat::test_that("auto dispatch uses raw outcome values in every design", {
  d <- rep(c(1, 0), each = 20)
  arm <- rep(c(0, 1), each = 20)
  strata <- rep(c("a", "b"), 20)
  share <- c(a = 0.5, b = 0.5)
  coded <- c(rep(c(3, 7), c(5, 15)), rep(c(3, 7), c(10, 10)))

  # A two-valued outcome that is not coded 0/1 is treated as bounded.
  testthat::expect_identical(
    cmr_two_arm(coded, d, normalize = TRUE, lower = 3, upper = 7)$method,
    "bounded"
  )
  testthat::expect_identical(
    cmr_multiarm(coded, arm, normalize = TRUE, lower = 3, upper = 7)$method,
    "bounded"
  )
  testthat::expect_identical(
    cmr_stratified(coded, d, strata, share, normalize = TRUE, lower = 3, upper = 7)$method,
    "bounded"
  )

  # An explicit method is applied to the normalized outcome.
  explicit <- cmr_two_arm(coded, d, method = "bernoulli", normalize = TRUE, lower = 3, upper = 7)
  testthat::expect_identical(explicit$method, "bernoulli")
  testthat::expect_equal(explicit$pilot$normalization, list(lower = 3, upper = 7))
  testthat::expect_identical(
    cmr_multiarm(coded, arm, method = "bernoulli", normalize = TRUE, lower = 3, upper = 7)$method,
    "bernoulli"
  )

  # Raw 0/1 outcomes use exact Bernoulli bounds on the raw scale.
  binary <- rep(c(0, 1), 20)
  testthat::expect_warning(
    fit_two <- cmr_two_arm(binary, d, normalize = TRUE, lower = 0, upper = 10),
    "`normalize = TRUE` was ignored"
  )
  testthat::expect_warning(
    fit_multi <- cmr_multiarm(binary, arm, normalize = TRUE, lower = 0, upper = 10),
    "`normalize = TRUE` was ignored"
  )
  testthat::expect_identical(fit_two$method, "bernoulli")
  testthat::expect_identical(fit_multi$method, "bernoulli")
  testthat::expect_null(fit_two$pilot$normalization)
  testthat::expect_no_warning(cmr_two_arm(binary, d, normalize = TRUE, lower = 0, upper = 1))
})

testthat::test_that("constant outcomes with data-dependent normalization stay bounded", {
  arm <- rep(c(0, 1), each = 20)
  fit <- suppressWarnings(cmr_multiarm(rep(5, 40), arm, normalize = TRUE))
  testthat::expect_identical(fit$method, "bounded")
  testthat::expect_equal(fit$U_CMR, 0.25)
})

testthat::test_that("a stratum with no sample has an NA treatment margin", {
  rect <- list(
    lower = rbind("1" = c(A = 0, B = 0.02), "0" = c(A = 0, B = 0.03)),
    upper = rbind("1" = c(A = 0, B = 0.10), "0" = c(A = 0, B = 0.12))
  )
  fit <- cmr_stratified_from_rectangle(rect, c(A = 0.4, B = 0.6))
  testthat::expect_true(is.na(fit$treatment_margin[["A"]]))
  testthat::expect_false(is.nan(fit$treatment_margin[["A"]]))
  testthat::expect_true(is.finite(fit$treatment_margin[["B"]]))
})

testthat::test_that("errors name the arm, cell, or outcome that failed", {
  y <- c(0.1, 0.2, 0.3, 0.4, 0.5)
  testthat::expect_error(
    cmr_multiarm(y, c("ctl", "ctl", "a", "a", "b"), control_arm = "ctl"),
    "Arm `b`: At least two observations"
  )
  testthat::expect_error(
    cmr_stratified(
      c(y, 0.6, 0.7),
      c(1, 1, 0, 0, 1, 1, 0),
      c("A", "A", "A", "A", "B", "B", "B"),
      c(A = 0.5, B = 0.5)
    ),
    "Control cell of stratum `B`: At least two observations"
  )
})

testthat::test_that("Sidak-by-arm correction widens the per-endpoint error", {
  set.seed(104)
  d <- rep(c(1, 0), each = 80)
  y <- c(stats::rbeta(80, 0.5, 0.5), stats::rbeta(80, 8, 8))
  bonferroni <- cmr_two_arm(y, d, method = "bounded")
  sidak <- cmr_two_arm(y, d, method = "bounded", correction = "sidak_arms")

  testthat::expect_equal(unname(sidak$beta[[1]]), (1 - sqrt(1 - 0.05)) / 2)
  testthat::expect_gt(sidak$beta[[1]], bonferroni$beta[[1]])
  testthat::expect_equal(sidak$joint_error_bound, 0.05, tolerance = 1e-12)
  testthat::expect_lte(sidak$rectangle[["v_u1"]], bonferroni$rectangle[["v_u1"]])
  testthat::expect_gte(sidak$rectangle[["v_l1"]], bonferroni$rectangle[["v_l1"]])
})
