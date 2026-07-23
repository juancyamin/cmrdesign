.fixture_dir <- function() {
  candidates <- c(
    file.path(getwd(), "..", "spec", "test_fixtures"),
    file.path(getwd(), "..", "..", "..", "spec", "test_fixtures"),
    file.path(getwd(), "spec", "test_fixtures")
  )
  candidates[file.exists(candidates)][[1L]]
}

.fixture <- function(filename) {
  testthat::skip_if_not_installed("jsonlite")
  jsonlite::fromJSON(
    file.path(.fixture_dir(), filename),
    simplifyVector = FALSE
  )
}

.case <- function(fixture, name) {
  names <- vapply(fixture$cases, `[[`, character(1), "name")
  fixture$cases[[match(name, names)]]
}

.case_tolerance <- function(case, fixture) {
  if (is.null(case$tolerance)) fixture$tolerance else case$tolerance
}

.expect_close <- function(actual, expected, tolerance) {
  if (is.null(expected)) {
    testthat::expect_null(actual)
    return(invisible())
  }
  if (is.character(expected) && length(expected) == 1L && expected == "Inf") {
    testthat::expect_true(is.infinite(actual))
    return(invisible())
  }
  if (is.list(expected)) {
    if (!is.null(names(expected)) && all(names(expected) != "")) {
      for (nm in names(expected)) {
        .expect_close(actual[[nm]], expected[[nm]], tolerance)
      }
    } else {
      testthat::expect_equal(length(actual), length(expected))
      for (i in seq_along(expected)) {
        .expect_close(actual[[i]], expected[[i]], tolerance)
      }
    }
    return(invisible())
  }
  if (is.logical(expected)) {
    testthat::expect_identical(isTRUE(actual), isTRUE(expected))
    return(invisible())
  }
  if (is.character(expected)) {
    testthat::expect_identical(actual, expected)
    return(invisible())
  }
  testthat::expect_equal(as.numeric(actual), as.numeric(expected), tolerance = tolerance)
}

.two_summary <- function(fit) {
  out <- list(
    pi = fit$pi,
    U_CMR = fit$U_CMR,
    rectangle = fit$rectangle,
    method = fit$method
  )
  out$diagnostics <- fit$diagnostics
  if (!is.null(fit$corner_regrets)) {
    out$corner_regrets <- fit$corner_regrets
  }
  out
}

.as_matrix_rows <- function(rows) {
  do.call(rbind, lapply(rows, function(x) as.numeric(unlist(x))))
}

.as_stratified_rectangle <- function(input) {
  strata_share <- unlist(input$strata_share)
  lower <- .as_matrix_rows(input$rectangle$lower)
  upper <- .as_matrix_rows(input$rectangle$upper)
  colnames(lower) <- names(strata_share)
  colnames(upper) <- names(strata_share)
  rownames(lower) <- names(input$rectangle$lower)
  rownames(upper) <- names(input$rectangle$upper)
  list(lower = lower, upper = upper)
}

testthat::test_that("fixture schema is valid", {
  fixture_names <- c(
    "bernoulli_exact.json",
    "bounded_mp.json",
    "bounded_mtr.json",
    "multiarm.json",
    "multiple_outcomes.json",
    "pilot_planning.json",
    "proxy.json",
    "rectangles_binary.json",
    "stratified.json"
  )
  fixtures <- lapply(fixture_names, .fixture)
  testthat::expect_true(all(vapply(fixtures, function(x) x$schema_version == 1L, logical(1))))
  testthat::expect_true(all(vapply(fixtures, function(x) x$source == "R reference implementation", logical(1))))
})

testthat::test_that("two-arm rectangle fixtures match implementation", {
  fixture <- .fixture("rectangles_binary.json")
  for (case in fixture$cases) {
    fit <- cmr_two_arm_from_rectangle(unlist(case$input$rectangle))
    .expect_close(.two_summary(fit), case$expected, fixture$tolerance)
  }
})

testthat::test_that("Maurer-Pontil fixtures match implementation", {
  fixture <- .fixture("bounded_mp.json")
  bounds_case <- .case(fixture, "variance_bounds_rep_01")
  bounds <- variance_bounds_maurer_pontil(
    unlist(bounds_case$input$y),
    beta_l = bounds_case$input$beta_l,
    beta_u = bounds_case$input$beta_u
  )
  .expect_close(bounds, bounds_case$expected, fixture$tolerance)

  rect_case <- .case(fixture, "two_arm_rectangle")
  rect <- rectangle_two_arm(
    y = unlist(rect_case$input$y),
    d = unlist(rect_case$input$d),
    alpha = rect_case$input$alpha,
    method = rect_case$input$method
  )
  fit <- cmr_two_arm(
    y = unlist(rect_case$input$y),
    d = unlist(rect_case$input$d),
    alpha = rect_case$input$alpha,
    method = rect_case$input$method
  )
  actual <- list(
    rectangle = rect$rectangle,
    n = rect$n,
    vhat = rect$vhat,
    beta = rect$beta,
    joint_error_bound = rect$joint_error_bound,
    pi = fit$pi,
    U_CMR = fit$U_CMR,
    method = fit$method
  )
  .expect_close(actual, rect_case$expected, fixture$tolerance)

  auto_case <- .case(fixture, "auto_normalize_raw_two_value")
  auto_rect <- rectangle_two_arm(
    y = unlist(auto_case$input$y),
    d = unlist(auto_case$input$d),
    alpha = auto_case$input$alpha,
    method = auto_case$input$method,
    normalize = auto_case$input$normalize
  )
  auto_fit <- cmr_two_arm(
    y = unlist(auto_case$input$y),
    d = unlist(auto_case$input$d),
    alpha = auto_case$input$alpha,
    method = auto_case$input$method,
    normalize = auto_case$input$normalize
  )
  actual <- list(
    rectangle = auto_rect$rectangle,
    method = auto_rect$method,
    pi = auto_fit$pi,
    U_CMR = auto_fit$U_CMR
  )
  .expect_close(actual, auto_case$expected, fixture$tolerance)
})

testthat::test_that("MTR fixtures match implementation", {
  fixture <- .fixture("bounded_mtr.json")
  bounds_case <- .case(fixture, "variance_bounds_regression")
  bounds <- variance_bounds_martinez_taboada_ramdas(
    unlist(bounds_case$input$y),
    beta_l = bounds_case$input$beta_l,
    beta_u = bounds_case$input$beta_u
  )
  .expect_close(bounds, bounds_case$expected, fixture$tolerance)

  fit_case <- .case(fixture, "two_arm_mtr")
  fit <- cmr_two_arm(
    y = unlist(fit_case$input$y),
    d = unlist(fit_case$input$d),
    alpha = fit_case$input$alpha,
    method = fit_case$input$method
  )
  .expect_close(.two_summary(fit), fit_case$expected, fixture$tolerance)
})

testthat::test_that("Bernoulli fixtures match implementation", {
  fixture <- .fixture("bernoulli_exact.json")
  pmf_case <- .case(fixture, "folded_pmf_m4_v010")
  .expect_close(
    list(pmf = as.list(as.numeric(folded_binomial_pmf(pmf_case$input$v, pmf_case$input$m)))),
    pmf_case$expected,
    fixture$tolerance
  )

  bounds_case <- .case(fixture, "variance_bounds_binary")
  bounds <- variance_bounds_bernoulli_exact(
    unlist(bounds_case$input$y),
    beta_l = bounds_case$input$beta_l,
    beta_u = bounds_case$input$beta_u
  )
  .expect_close(bounds, bounds_case$expected, fixture$tolerance)

  fit_case <- .case(fixture, "auto_dispatch_two_arm")
  fit <- cmr_two_arm(
    y = unlist(fit_case$input$y),
    d = unlist(fit_case$input$d),
    alpha = fit_case$input$alpha,
    method = fit_case$input$method
  )
  .expect_close(.two_summary(fit), fit_case$expected, fixture$tolerance)
})

testthat::test_that("multi-arm fixtures match implementation", {
  fixture <- .fixture("multiarm.json")
  neyman_case <- .case(fixture, "known_variance_neyman")
  variances <- unlist(neyman_case$input$variances)
  pi <- assign_multiarm_neyman(variances)
  actual <- list(
    pi = pi,
    objective = multiarm_variance_objective(pi, variances),
    oracle = multiarm_oracle_variance(variances),
    regret = multiarm_regret(pi, variances)
  )
  .expect_close(actual, neyman_case$expected, fixture$tolerance)

  for (name in c("one_treatment_reduction", "general_asymmetric_3_components", "full_rectangle_k4")) {
    case <- .case(fixture, name)
    fit <- cmr_multiarm_from_rectangle(unlist(case$input$rectangle))
    actual <- list(pi = fit$pi, U_CMR = fit$U_CMR)
    if (!is.null(case$expected$full_rectangle)) {
      actual$full_rectangle <- fit$diagnostics$full_rectangle
    }
    .expect_close(actual, case$expected, .case_tolerance(case, fixture))
  }
})

testthat::test_that("stratified fixtures match implementation", {
  fixture <- .fixture("stratified.json")
  neyman_case <- .case(fixture, "known_variance_neyman")
  variances <- .as_matrix_rows(neyman_case$input$variances)
  strata_share <- unlist(neyman_case$input$strata_share)
  pi <- assign_stratified_neyman(variances, strata_share)
  actual <- list(
    pi = pi,
    objective = stratified_variance_objective(pi, variances, strata_share),
    oracle = stratified_oracle_variance(variances, strata_share),
    regret = stratified_regret(pi, variances, strata_share)
  )
  .expect_close(actual, neyman_case$expected, fixture$tolerance)

  for (name in c("one_stratum_reduction", "general_asymmetric_2_strata", "full_rectangle_representative_balance")) {
    case <- .case(fixture, name)
    rectangle <- .as_stratified_rectangle(case$input)
    shares <- unlist(case$input$strata_share)
    fit <- cmr_stratified_from_rectangle(rectangle, shares)
    actual <- list(pi = fit$pi, U_CMR = fit$U_CMR)
    if (!is.null(case$expected$sampling_margin)) {
      actual$sampling_margin <- fit$sampling_margin
      actual$treatment_margin <- fit$treatment_margin
    }
    if (!is.null(case$expected$full_rectangle)) {
      actual$full_rectangle <- fit$diagnostics$full_rectangle
    }
    .expect_close(actual, case$expected, .case_tolerance(case, fixture))
  }
})

testthat::test_that("multiple-outcome fixtures match implementation", {
  fixture <- .fixture("multiple_outcomes.json")
  index_case <- .case(fixture, "weighted_index")
  fit <- cmr_multiple_outcomes(
    y = .as_matrix_rows(index_case$input$y),
    d = unlist(index_case$input$d),
    weights = unlist(index_case$input$weights),
    estimand = index_case$input$estimand,
    method = index_case$input$method
  )
  .expect_close(.two_summary(fit), index_case$expected, fixture$tolerance)

  coprimary_case <- .case(fixture, "coprimary_bernoulli")
  rect <- rectangle_multiple_outcomes(
    y = .as_matrix_rows(coprimary_case$input$y),
    d = unlist(coprimary_case$input$d),
    weights = unlist(coprimary_case$input$weights),
    estimand = coprimary_case$input$estimand,
    method = coprimary_case$input$method
  )
  actual <- list(
    rectangle = rect$rectangle,
    joint_error_bound = rect$joint_error_bound,
    vhat = rect$vhat,
    beta = rect$beta,
    method = rect$method
  )
  .expect_close(actual, coprimary_case$expected, fixture$tolerance)
})

testthat::test_that("proxy fixtures match implementation", {
  fixture <- .fixture("proxy.json")
  for (name in c("zero_bridge_matches_direct", "large_bridge_full_rectangle", "nonzero_bridge")) {
    case <- .case(fixture, name)
    zeta <- if (is.list(case$input$zeta)) unlist(case$input$zeta) else case$input$zeta
    fit <- cmr_proxy(
      proxy_y = unlist(case$input$proxy_y),
      d = unlist(case$input$d),
      zeta = zeta,
      method = case$input$method
    )
    actual <- .two_summary(fit)
    if (!is.null(case$expected$direct)) {
      direct <- cmr_two_arm(
        y = unlist(case$input$proxy_y),
        d = unlist(case$input$d),
        method = case$input$method
      )
      actual$direct <- .two_summary(direct)
    }
    if (!is.null(case$expected$proxy_rectangle)) {
      actual$proxy_rectangle <- fit$confidence_set$bridge$proxy_rectangle
      actual$bridge <- fit$confidence_set$bridge$assumption
    }
    .expect_close(actual, case$expected, fixture$tolerance)
  }
})

testthat::test_that("planning fixtures match implementation", {
  fixture <- .fixture("pilot_planning.json")
  activation_case <- .case(fixture, "activation_thresholds")
  actual <- list(
    bounded_005 = activation_threshold_bounded(0.05),
    bounded_010 = activation_threshold_bounded(0.10),
    bounded_001 = activation_threshold_bounded(0.01),
    bernoulli_005 = activation_threshold_bernoulli(0.05)
  )
  .expect_close(actual, activation_case$expected, fixture$tolerance)

  for (name in c("design_only_break_even", "pooled_keeps_activation")) {
    case <- .case(fixture, name)
    plan <- cmr_plan(
      n = case$input$n,
      sigma1 = case$input$sigma1,
      sigma0 = case$input$sigma0,
      alpha = case$input$alpha,
      method = case$input$method,
      desired_pilot = case$input$desired_pilot,
      accounting = case$input$accounting
    )
    actual <- list(
      activation_threshold = plan$band$activation_threshold,
      break_even_total = plan$band$break_even_total,
      default_two_thirds_power = plan$default_two_thirds_power,
      desired_status = plan$desired_status
    )
    for (field in c("break_even_share", "suggested_pilot", "min_feasible", "max_feasible")) {
      if (!is.null(case$expected[[field]])) {
        actual[[field]] <- if (!is.null(plan$band[[field]])) plan$band[[field]] else plan[[field]]
      }
    }
    .expect_close(actual, case$expected, fixture$tolerance)
  }
})
