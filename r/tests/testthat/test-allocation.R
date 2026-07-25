testthat::test_that("two-arm fit rounds counts and recomputes certificate", {
  rect <- c(v_l1 = 0.01, v_u1 = 0.09, v_l0 = 0.04, v_u0 = 0.16)
  fit <- cmr_two_arm_from_rectangle(rect)

  alloc <- realize_allocation(fit, n_main = 101)

  testthat::expect_s3_class(alloc, "cmr_allocation")
  testthat::expect_equal(sum(alloc$counts), 101)
  testthat::expect_setequal(names(alloc$counts), c("treatment", "control"))
  testthat::expect_equal(sum(alloc$shares), 1)
  testthat::expect_gte(alloc$realized_U_CMR, fit$U_CMR - 1e-12)
  testthat::expect_true(alloc$diagnostics$certificate_recomputed)
})

testthat::test_that("unbounded two-arm fit recomputes raw-scale certificate", {
  rect <- c(v_l1 = 0.5, v_u1 = 1.4, v_l0 = 0.2, v_u0 = 1.0)
  fit <- cmr_unbounded_from_rectangle(rect)

  alloc <- realize_allocation(fit, n_main = 99)

  testthat::expect_equal(sum(alloc$counts), 99)
  testthat::expect_true(is.finite(alloc$realized_U_CMR))
  testthat::expect_gte(alloc$realized_U_CMR, fit$U_CMR - 1e-12)
})

testthat::test_that("raw multi-arm shares use largest-remainder rounding", {
  alloc <- realize_allocation(
    c("0" = 0.34, "1" = 0.33, "2" = 0.33),
    n_main = 10,
    min_per_arm = 0
  )

  testthat::expect_equal(alloc$counts, c("0" = 4L, "1" = 3L, "2" = 3L))
  testthat::expect_equal(alloc$shares, c("0" = 0.4, "1" = 0.3, "2" = 0.3))
  testthat::expect_null(alloc$realized_U_CMR)
  testthat::expect_false(alloc$diagnostics$certificate_recomputed)
})

testthat::test_that("minimum per positive target share is enforced", {
  alloc <- realize_allocation(c(a = 0.98, b = 0.01, c = 0.01), n_main = 5)

  testthat::expect_equal(alloc$counts, c(a = 3L, b = 1L, c = 1L))
})

testthat::test_that("multi-arm fit recomputes certificate at realized shares", {
  rect <- c(
    v_l0 = 0.02, v_u0 = 0.08,
    v_l1 = 0.04, v_u1 = 0.12,
    v_l2 = 0.01, v_u2 = 0.07
  )
  fit <- cmr_multiarm_from_rectangle(rect)

  alloc <- realize_allocation(fit, n_main = 100)

  testthat::expect_equal(sum(alloc$counts), 100)
  testthat::expect_setequal(names(alloc$counts), c("0", "1", "2"))
  testthat::expect_true(is.finite(alloc$realized_U_CMR))
  testthat::expect_true("binding_vertices" %in% names(alloc$diagnostics))
})

testthat::test_that("stratified counts respect fixed stratum sizes", {
  shares <- c("1:A" = 0.24, "0:A" = 0.16, "1:B" = 0.30, "0:B" = 0.30)

  alloc <- realize_allocation(shares, strata_counts = c(A = 40, B = 60))

  testthat::expect_equal(alloc$counts[["1:A"]] + alloc$counts[["0:A"]], 40)
  testthat::expect_equal(alloc$counts[["1:B"]] + alloc$counts[["0:B"]], 60)
  testthat::expect_equal(sum(alloc$counts), 100)
  testthat::expect_equal(alloc$diagnostics$design, "stratified")
})

testthat::test_that("stratified fit recomputes certificate with fixed stratum sizes", {
  rect <- list(
    lower = rbind(treatment = c(A = 0.01, B = 0.04),
                  control = c(A = 0.02, B = 0.03)),
    upper = rbind(treatment = c(A = 0.08, B = 0.12),
                  control = c(A = 0.09, B = 0.10))
  )
  fit <- cmr_stratified_from_rectangle(rect, c(A = 0.4, B = 0.6))

  alloc <- realize_allocation(fit, strata_counts = c(A = 40, B = 60))

  testthat::expect_equal(alloc$counts[["1:A"]] + alloc$counts[["0:A"]], 40)
  testthat::expect_equal(alloc$counts[["1:B"]] + alloc$counts[["0:B"]], 60)
  testthat::expect_true(is.finite(alloc$realized_U_CMR))
  testthat::expect_true(alloc$diagnostics$certificate_recomputed)
})

testthat::test_that("allocation errors when minimum counts do not fit", {
  testthat::expect_error(
    realize_allocation(c(a = 0.5, b = 0.5, c = 0), n_main = 1),
    "`n_main` is too small"
  )
})

testthat::test_that("allocation has compact print method", {
  alloc <- realize_allocation(c("0" = 0.5, "1" = 0.5), n_main = 8)
  printed <- utils::capture.output(print(alloc))

  testthat::expect_match(printed[[1]], "<cmr_allocation>", fixed = TRUE)
  testthat::expect_match(paste(printed, collapse = "\n"), "counts:", fixed = TRUE)
})
