.multiarm_problem <- function(rect) {
  vertices <- multiarm_rectangle_vertices(rect)
  weights <- c(ncol(vertices) - 1, rep(1, ncol(vertices) - 1))
  A <- sweep(vertices, 2L, weights, `*`)
  list(A = A, oracle = rowSums(sqrt(A))^2)
}

testthat::test_that("the general solver certifies its optimality gap", {
  rect <- c(
    v_l0 = 0.020, v_u0 = 0.090,
    v_l1 = 0.050, v_u1 = 0.200,
    v_l2 = 0.010, v_u2 = 0.040,
    v_l3 = 0.080, v_u3 = 0.110,
    v_l4 = 0.000, v_u4 = 0.150
  )
  fit <- cmr_multiarm_from_rectangle(rect)

  testthat::expect_identical(fit$diagnostics$solver, "barrier_newton")
  testthat::expect_true(fit$diagnostics$converged)
  testthat::expect_gte(fit$diagnostics$optimality_gap, 0)
  testthat::expect_lte(fit$diagnostics$optimality_gap, 1e-7)
  testthat::expect_equal(sum(fit$pi), 1, tolerance = 1e-12)

  # `U_CMR` is the exact worst-case regret of the returned allocation.
  problem <- .multiarm_problem(rect)
  recomputed <- max(as.numeric(problem$A %*% (1 / fit$pi)) - problem$oracle)
  testthat::expect_equal(fit$U_CMR, recomputed, tolerance = 1e-13)
})

testthat::test_that("the barrier method and the multi-start search agree", {
  rect <- c(v_l0 = 0.02, v_u0 = 0.08, v_l1 = 0.04, v_u1 = 0.12, v_l2 = 0.01, v_u2 = 0.07)
  barrier <- cmr_multiarm_from_rectangle(rect)
  search <- cmr_multiarm_from_rectangle(rect, control = list(barrier = FALSE))

  testthat::expect_identical(search$diagnostics$solver, "smooth_max_bfgs_nelder_mead")
  testthat::expect_lte(barrier$U_CMR, search$U_CMR + 1e-9)
  testthat::expect_equal(barrier$U_CMR, search$U_CMR, tolerance = 1e-6)
  testthat::expect_equal(barrier$pi, search$pi, tolerance = 1e-4)
})

testthat::test_that("the two-component problem recovers the two-arm closed form", {
  rect <- c(v_l0 = 0.04, v_u0 = 0.16, v_l1 = 0.01, v_u1 = 0.09)
  multiarm <- cmr_multiarm_from_rectangle(rect)
  two_arm <- cmr_two_arm_from_rectangle(c(v_l1 = 0.01, v_u1 = 0.09, v_l0 = 0.04, v_u0 = 0.16))

  testthat::expect_equal(multiarm$pi[["1"]], two_arm$pi, tolerance = 1e-7)
  testthat::expect_equal(multiarm$U_CMR, two_arm$U_CMR, tolerance = 1e-8)
})

testthat::test_that("the solver matches a brute-force grid on three components", {
  rect <- c(v_l0 = 0.02, v_u0 = 0.08, v_l1 = 0.04, v_u1 = 0.12, v_l2 = 0.01, v_u2 = 0.07)
  fit <- cmr_multiarm_from_rectangle(rect)
  problem <- .multiarm_problem(rect)
  grid <- expand.grid(p0 = seq(0.01, 0.98, by = 0.005), p1 = seq(0.01, 0.98, by = 0.005))
  grid <- grid[grid$p0 + grid$p1 < 0.995, ]
  values <- apply(grid, 1L, function(p) {
    pi <- c(p[[1]], p[[2]], 1 - p[[1]] - p[[2]])
    max(as.numeric(problem$A %*% (1 / pi)) - problem$oracle)
  })
  testthat::expect_lte(fit$U_CMR, min(values) + 1e-12)
  testthat::expect_gte(fit$U_CMR, min(values) - 5e-3)
})
