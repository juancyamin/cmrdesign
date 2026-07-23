#!/usr/bin/env Rscript

if (!requireNamespace("jsonlite", quietly = TRUE)) {
  stop("The jsonlite package is required to generate fixtures.", call. = FALSE)
}

`%||%` <- function(x, y) if (is.null(x)) y else x

args <- commandArgs(trailingOnly = FALSE)
file_arg <- sub("^--file=", "", args[grepl("^--file=", args)])
script_path <- if (length(file_arg) > 0L) {
  normalizePath(file_arg[[1L]], mustWork = FALSE)
} else {
  normalizePath("spec/scripts/generate_fixtures.R", mustWork = FALSE)
}
repo_root <- normalizePath(file.path(dirname(script_path), "..", ".."), mustWork = FALSE)
if (!dir.exists(file.path(repo_root, "r", "R"))) {
  repo_root <- normalizePath(getwd())
}
fixture_dir <- file.path(repo_root, "spec", "test_fixtures")

source_files <- sort(list.files(file.path(repo_root, "r", "R"), pattern = "[.]R$", full.names = TRUE))
for (file in source_files) {
  source(file)
}

scalar <- function(x) {
  if (length(x) != 1L) {
    stop("Expected scalar.", call. = FALSE)
  }
  if (is.numeric(x)) {
    x <- unname(as.numeric(x))
    if (!is.finite(x)) {
      return(as.character(x))
    }
    return(x)
  }
  unname(x)
}

num_list <- function(x) {
  nms <- names(x)
  out <- lapply(as.numeric(x), scalar)
  if (!is.null(nms) && length(nms) == length(out) && all(nms != "")) {
    names(out) <- nms
  }
  out
}

matrix_by_row <- function(x) {
  out <- lapply(seq_len(nrow(x)), function(i) num_list(x[i, ]))
  row_names <- rownames(x)
  if (!is.null(row_names) && length(row_names) == length(out) && all(row_names != "")) {
    names(out) <- row_names
  }
  out
}

rectangle_list <- function(x) num_list(x)

fit_two <- function(fit) {
  list(
    pi = scalar(fit$pi),
    U_CMR = scalar(fit$U_CMR),
    rectangle = rectangle_list(fit$rectangle),
    method = fit$method %||% NULL
  )
}

write_fixture <- function(filename, purpose, cases, tolerance = 1e-10) {
  payload <- list(
    schema_version = 1L,
    source = "R reference implementation",
    generated_by = "spec/scripts/generate_fixtures.R",
    purpose = purpose,
    tolerance = tolerance,
    cases = cases
  )
  path <- file.path(fixture_dir, filename)
  json <- jsonlite::toJSON(payload, auto_unbox = TRUE, pretty = TRUE, digits = 16, null = "null")
  writeLines(json, path)
  message("wrote ", path)
}

two_full <- c(v_l1 = 0, v_u1 = 0.25, v_l0 = 0, v_u0 = 0.25)
two_collapsed <- c(v_l1 = 0.04, v_u1 = 0.04, v_l0 = 0.09, v_u0 = 0.09)
two_asym <- c(v_l1 = 0.01, v_u1 = 0.09, v_l0 = 0.04, v_u0 = 0.16)
two_zero <- c(v_l1 = 0, v_u1 = 0, v_l0 = 0, v_u0 = 0)
write_fixture(
  "rectangles_binary.json",
  "Closed-form two-arm CMR rectangle cases.",
  list(
    list(
      name = "full_rectangle",
      input = list(rectangle = rectangle_list(two_full)),
      expected = c(fit_two(cmr_two_arm_from_rectangle(two_full)),
                   list(diagnostics = list(full_rectangle = TRUE, collapsed_rectangle = FALSE)))
    ),
    list(
      name = "collapsed_rectangle",
      input = list(rectangle = rectangle_list(two_collapsed)),
      expected = c(fit_two(cmr_two_arm_from_rectangle(two_collapsed)),
                   list(diagnostics = list(full_rectangle = FALSE, collapsed_rectangle = TRUE)))
    ),
    list(
      name = "asymmetric_rectangle",
      input = list(rectangle = rectangle_list(two_asym)),
      expected = c(fit_two(cmr_two_arm_from_rectangle(two_asym)),
                   list(corner_regrets = num_list(cmr_two_arm_from_rectangle(two_asym)$corner_regrets)))
    ),
    list(
      name = "all_zero_rectangle",
      input = list(rectangle = rectangle_list(two_zero)),
      expected = fit_two(cmr_two_arm_from_rectangle(two_zero))
    )
  ),
  tolerance = 1e-12
)

mp_y_bounds <- rep(c(0, 1), 40)
mp_bounds <- variance_bounds_maurer_pontil(mp_y_bounds, beta_l = 0.0125, beta_u = 0.0125)
mp_y <- c(0, 1, 0, 1, 0.2, 0.3, 0.4, 0.5)
mp_d <- c(1, 1, 1, 1, 0, 0, 0, 0)
mp_rect <- rectangle_two_arm(mp_y, mp_d, alpha = 0.10, method = "bounded")
mp_fit <- cmr_two_arm(mp_y, mp_d, alpha = 0.10, method = "bounded")
auto_norm_y <- c(2, 5, 2, 5, 5, 2, 5, 2)
auto_norm_d <- c(1, 1, 1, 1, 0, 0, 0, 0)
auto_norm_rect <- rectangle_two_arm(
  auto_norm_y,
  auto_norm_d,
  alpha = 0.05,
  method = "auto",
  normalize = TRUE
)
auto_norm_fit <- cmr_two_arm(
  auto_norm_y,
  auto_norm_d,
  alpha = 0.05,
  method = "auto",
  normalize = TRUE
)
write_fixture(
  "bounded_mp.json",
  "Maurer-Pontil bounded-outcome variance bounds and two-arm rectangle.",
  list(
    list(
      name = "variance_bounds_rep_01",
      input = list(y = as.list(mp_y_bounds), beta_l = 0.0125, beta_u = 0.0125),
      expected = list(L = scalar(mp_bounds$L), U = scalar(mp_bounds$U), vhat = scalar(mp_bounds$vhat),
                      n = scalar(mp_bounds$n), method = mp_bounds$method)
    ),
    list(
      name = "two_arm_rectangle",
      input = list(y = as.list(mp_y), d = as.list(mp_d), alpha = 0.10, method = "bounded"),
      expected = list(rectangle = rectangle_list(mp_rect$rectangle), n = num_list(mp_rect$n),
                      vhat = num_list(mp_rect$vhat), beta = num_list(mp_rect$beta),
                      joint_error_bound = scalar(mp_rect$joint_error_bound),
                      pi = scalar(mp_fit$pi), U_CMR = scalar(mp_fit$U_CMR),
                      method = mp_fit$method)
    ),
    list(
      name = "auto_normalize_raw_two_value",
      input = list(y = as.list(auto_norm_y), d = as.list(auto_norm_d), alpha = 0.05,
                   method = "auto", normalize = TRUE),
      expected = list(rectangle = rectangle_list(auto_norm_rect$rectangle),
                      method = auto_norm_rect$method,
                      pi = scalar(auto_norm_fit$pi),
                      U_CMR = scalar(auto_norm_fit$U_CMR))
    )
  )
)

mtr_y_bounds <- rep(seq(0.05, 0.95, by = 0.10), 50)
mtr_bounds <- variance_bounds_martinez_taboada_ramdas(mtr_y_bounds, beta_l = 0.0125, beta_u = 0.0125)
mtr_y <- c(rep(seq(0.05, 0.95, by = 0.10), 10), rep(seq(0.10, 0.90, by = 0.10), 12))
mtr_d <- c(rep(1, 100), rep(0, 108))
mtr_fit <- cmr_two_arm(mtr_y, mtr_d, alpha = 0.10, method = "mtr")
write_fixture(
  "bounded_mtr.json",
  "Martinez-Taboada-Ramdas bounded-outcome variance bounds and applied CMR.",
  list(
    list(
      name = "variance_bounds_regression",
      input = list(y = as.list(mtr_y_bounds), beta_l = 0.0125, beta_u = 0.0125),
      expected = list(L = scalar(mtr_bounds$L), U = scalar(mtr_bounds$U),
                      vhat = scalar(mtr_bounds$vhat), n = scalar(mtr_bounds$n),
                      method = mtr_bounds$method)
    ),
    list(
      name = "two_arm_mtr",
      input = list(y = as.list(mtr_y), d = as.list(mtr_d), alpha = 0.10, method = "mtr"),
      expected = fit_two(mtr_fit)
    )
  )
)

unbounded_y_bounds <- rep(c(0, 2), 180)
unbounded_bounds <- variance_bounds_unbounded_mom(unbounded_y_bounds, alpha = 0.05, psi = 1)
unbounded_y1 <- rep(c(0, 2), 180)
unbounded_y0 <- rep(c(0, 4), 180)
unbounded_y <- c(unbounded_y1, unbounded_y0)
unbounded_d <- c(rep(1, length(unbounded_y1)), rep(0, length(unbounded_y0)))
unbounded_rect <- rectangle_unbounded(unbounded_y, unbounded_d, alpha = 0.05, psi = 1)
unbounded_fit <- cmr_two_arm(unbounded_y, unbounded_d, alpha = 0.05,
                             method = "unbounded", psi = 1)
write_fixture(
  "unbounded.json",
  "Unbounded-outcome median-of-means variance bounds and applied CMR.",
  list(
    list(
      name = "variance_bounds_pair_blocks",
      input = list(y = as.list(unbounded_y_bounds), alpha = 0.05, psi = 1),
      expected = list(L = scalar(unbounded_bounds$L), U = scalar(unbounded_bounds$U),
                      vhat = scalar(unbounded_bounds$vhat), n = scalar(unbounded_bounds$n),
                      method = unbounded_bounds$method, active = unbounded_bounds$active,
                      status = unbounded_bounds$status,
                      statistic = list(k = scalar(unbounded_bounds$statistic$k),
                                       b = scalar(unbounded_bounds$statistic$b),
                                       n_pairs = scalar(unbounded_bounds$statistic$n_pairs),
                                       used_pairs = scalar(unbounded_bounds$statistic$used_pairs),
                                       rho = scalar(unbounded_bounds$statistic$rho)))
    ),
    list(
      name = "two_arm_unbounded",
      input = list(y = as.list(unbounded_y), d = as.list(unbounded_d),
                   alpha = 0.05, method = "unbounded", psi = 1),
      expected = list(rectangle = rectangle_list(unbounded_rect$rectangle),
                      n = num_list(unbounded_rect$n),
                      vhat = num_list(unbounded_rect$vhat),
                      rho = num_list(unbounded_rect$rho),
                      k = num_list(unbounded_rect$k),
                      b = num_list(unbounded_rect$b),
                      psi = num_list(unbounded_rect$psi),
                      joint_error_bound = scalar(unbounded_rect$joint_error_bound),
                      active = unbounded_rect$active,
                      status = unbounded_rect$status,
                      pi = scalar(unbounded_fit$pi),
                      U_CMR = scalar(unbounded_fit$U_CMR),
                      method = unbounded_fit$method)
    )
  )
)

bern_pmf <- folded_binomial_pmf(0.10, 4)
bern_y <- c(0, 1, 0, 1, 1, 0, 0, 1)
bern_bounds <- variance_bounds_bernoulli_exact(bern_y, beta_l = 0.0125, beta_u = 0.0125)
bern_d <- c(1, 1, 1, 1, 0, 0, 0, 0)
bern_fit <- cmr_two_arm(bern_y, bern_d, alpha = 0.05, method = "auto")
write_fixture(
  "bernoulli_exact.json",
  "Exact Bernoulli folded-binomial PMF, bounds, and auto dispatch.",
  list(
    list(
      name = "folded_pmf_m4_v010",
      input = list(v = 0.10, m = 4),
      expected = list(pmf = as.list(as.numeric(bern_pmf)))
    ),
    list(
      name = "variance_bounds_binary",
      input = list(y = as.list(bern_y), beta_l = 0.0125, beta_u = 0.0125),
      expected = list(L = scalar(bern_bounds$L), U = scalar(bern_bounds$U),
                      vhat = scalar(bern_bounds$vhat), n = scalar(bern_bounds$n),
                      method = bern_bounds$method)
    ),
    list(
      name = "auto_dispatch_two_arm",
      input = list(y = as.list(bern_y), d = as.list(bern_d), alpha = 0.05, method = "auto"),
      expected = fit_two(bern_fit)
    )
  )
)

multi_variances <- c("0" = 0.04, "1" = 0.09, "2" = 0.16)
multi_pi <- assign_multiarm_neyman(multi_variances)
multi_one_rect <- c(v_l0 = 0.04, v_u0 = 0.16, v_l1 = 0.01, v_u1 = 0.09)
multi_one <- cmr_multiarm_from_rectangle(multi_one_rect)
multi_full_rect <- c(v_l0 = 0, v_u0 = 0.25)
for (k in 1:4) {
  multi_full_rect[paste0("v_l", k)] <- 0
  multi_full_rect[paste0("v_u", k)] <- 0.25
}
multi_full <- cmr_multiarm_from_rectangle(multi_full_rect)
multi_general_rect <- c(v_l0 = 0.02, v_u0 = 0.08,
                        v_l1 = 0.04, v_u1 = 0.12,
                        v_l2 = 0.01, v_u2 = 0.07)
multi_general <- cmr_multiarm_from_rectangle(multi_general_rect)
write_fixture(
  "multiarm.json",
  "Shared-control multi-arm objective, general rectangle, one-treatment reduction, and full rectangle.",
  list(
    list(
      name = "known_variance_neyman",
      input = list(variances = num_list(multi_variances)),
      expected = list(pi = num_list(multi_pi),
                      objective = scalar(multiarm_variance_objective(multi_pi, multi_variances)),
                      oracle = scalar(multiarm_oracle_variance(multi_variances)),
                      regret = scalar(multiarm_regret(multi_pi, multi_variances)))
    ),
    list(
      name = "one_treatment_reduction",
      input = list(rectangle = rectangle_list(multi_one_rect)),
      expected = list(pi = num_list(multi_one$pi), U_CMR = scalar(multi_one$U_CMR))
    ),
    list(
      name = "general_asymmetric_3_components",
      tolerance = 1e-6,
      input = list(rectangle = rectangle_list(multi_general_rect)),
      expected = list(pi = num_list(multi_general$pi), U_CMR = scalar(multi_general$U_CMR))
    ),
    list(
      name = "full_rectangle_k4",
      input = list(rectangle = rectangle_list(multi_full_rect)),
      expected = list(pi = num_list(multi_full$pi), U_CMR = scalar(multi_full$U_CMR),
                      full_rectangle = TRUE)
    )
  ),
  tolerance = 1e-8
)

strata_share <- c(A = 0.4, B = 0.6)
strata_variances <- rbind(treatment = c(A = 0.04, B = 0.16),
                          control = c(A = 0.09, B = 0.01))
strata_pi <- assign_stratified_neyman(strata_variances, strata_share)
strata_one_share <- c(A = 1)
strata_one_rect <- list(
  lower = rbind(treatment = c(A = 0.01), control = c(A = 0.04)),
  upper = rbind(treatment = c(A = 0.09), control = c(A = 0.16))
)
strata_one <- cmr_stratified_from_rectangle(strata_one_rect, strata_one_share)
strata_full_share <- c(A = 0.2, B = 0.3, C = 0.5)
strata_full_rect <- list(
  lower = matrix(0, nrow = 2L, ncol = 3L, dimnames = list(c("treatment", "control"), names(strata_full_share))),
  upper = matrix(0.25, nrow = 2L, ncol = 3L, dimnames = list(c("treatment", "control"), names(strata_full_share)))
)
strata_full <- cmr_stratified_from_rectangle(strata_full_rect, strata_full_share)
strata_general_rect <- list(
  lower = rbind(treatment = c(A = 0.01, B = 0.04),
                control = c(A = 0.02, B = 0.03)),
  upper = rbind(treatment = c(A = 0.08, B = 0.12),
                control = c(A = 0.09, B = 0.10))
)
strata_general <- cmr_stratified_from_rectangle(strata_general_rect, strata_share)
write_fixture(
  "stratified.json",
  "Stratified objective, general rectangle, one-stratum reduction, and full rectangle.",
  list(
    list(
      name = "known_variance_neyman",
      input = list(variances = matrix_by_row(strata_variances), strata_share = num_list(strata_share)),
      expected = list(pi = num_list(strata_pi),
                      objective = scalar(stratified_variance_objective(strata_pi, strata_variances, strata_share)),
                      oracle = scalar(stratified_oracle_variance(strata_variances, strata_share)),
                      regret = scalar(stratified_regret(strata_pi, strata_variances, strata_share)))
    ),
    list(
      name = "one_stratum_reduction",
      input = list(rectangle = list(lower = matrix_by_row(strata_one_rect$lower),
                                    upper = matrix_by_row(strata_one_rect$upper)),
                   strata_share = num_list(strata_one_share)),
      expected = list(pi = num_list(strata_one$pi), U_CMR = scalar(strata_one$U_CMR))
    ),
    list(
      name = "general_asymmetric_2_strata",
      tolerance = 1e-6,
      input = list(rectangle = list(lower = matrix_by_row(strata_general_rect$lower),
                                    upper = matrix_by_row(strata_general_rect$upper)),
                   strata_share = num_list(strata_share)),
      expected = list(pi = num_list(strata_general$pi), U_CMR = scalar(strata_general$U_CMR))
    ),
    list(
      name = "full_rectangle_representative_balance",
      input = list(rectangle = list(lower = matrix_by_row(strata_full_rect$lower),
                                    upper = matrix_by_row(strata_full_rect$upper)),
                   strata_share = num_list(strata_full_share)),
      expected = list(pi = num_list(strata_full$pi), U_CMR = scalar(strata_full$U_CMR),
                      sampling_margin = num_list(strata_full$sampling_margin),
                      treatment_margin = num_list(strata_full$treatment_margin),
                      full_rectangle = TRUE)
    )
  ),
  tolerance = 1e-8
)

mo_y_index <- matrix(c(0.1, 0.2,
                       0.9, 0.7,
                       0.2, 0.3,
                       0.8, 0.9,
                       0.3, 0.4,
                       0.4, 0.3,
                       0.5, 0.7,
                       0.6, 0.5), ncol = 2L, byrow = TRUE)
mo_d <- c(1, 1, 1, 1, 0, 0, 0, 0)
mo_weights_index <- c(0.25, 0.75)
mo_index <- cmr_multiple_outcomes(mo_y_index, mo_d, weights = mo_weights_index,
                                  estimand = "index", method = "bounded")
mo_y_coprimary <- matrix(c(0, 1,
                           1, 0,
                           0, 1,
                           1, 0,
                           1, 0,
                           0, 1,
                           0, 1,
                           1, 0), ncol = 2L, byrow = TRUE)
mo_weights_coprimary <- c(0.4, 0.6)
mo_coprimary <- rectangle_multiple_outcomes(mo_y_coprimary, mo_d, weights = mo_weights_coprimary,
                                            method = "bernoulli")
write_fixture(
  "multiple_outcomes.json",
  "Multiple-outcome weighted-index and co-primary rectangle cases.",
  list(
    list(
      name = "weighted_index",
      input = list(y = unname(split(mo_y_index, row(mo_y_index))), d = as.list(mo_d),
                   weights = as.list(mo_weights_index), estimand = "index", method = "bounded"),
      expected = fit_two(mo_index)
    ),
    list(
      name = "coprimary_bernoulli",
      input = list(y = unname(split(mo_y_coprimary, row(mo_y_coprimary))), d = as.list(mo_d),
                   weights = as.list(mo_weights_coprimary), estimand = "coprimary", method = "bernoulli"),
      expected = list(rectangle = rectangle_list(mo_coprimary$rectangle),
                      joint_error_bound = scalar(mo_coprimary$joint_error_bound),
                      vhat = num_list(mo_coprimary$vhat),
                      beta = scalar(mo_coprimary$beta),
                      method = mo_coprimary$method)
    )
  )
)

proxy_y <- c(0, 1, 0, 1, 1, 0, 0, 1)
proxy_d <- c(1, 1, 1, 1, 0, 0, 0, 0)
proxy_direct <- cmr_two_arm(proxy_y, proxy_d, method = "bernoulli")
proxy_zero <- cmr_proxy(proxy_y, proxy_d, zeta = 0, method = "bernoulli")
proxy_full <- cmr_proxy(proxy_y, proxy_d, zeta = 0.5, method = "bernoulli")
proxy_bridge <- cmr_proxy(proxy_y, proxy_d, zeta = c(treatment = 0.04, control = 0.06),
                          method = "bernoulli")
write_fixture(
  "proxy.json",
  "Proxy/delayed-outcome bridge widening cases.",
  list(
    list(
      name = "zero_bridge_matches_direct",
      input = list(proxy_y = as.list(proxy_y), d = as.list(proxy_d), zeta = 0, method = "bernoulli"),
      expected = c(fit_two(proxy_zero), list(direct = fit_two(proxy_direct)))
    ),
    list(
      name = "large_bridge_full_rectangle",
      input = list(proxy_y = as.list(proxy_y), d = as.list(proxy_d), zeta = 0.5, method = "bernoulli"),
      expected = fit_two(proxy_full)
    ),
    list(
      name = "nonzero_bridge",
      input = list(proxy_y = as.list(proxy_y), d = as.list(proxy_d),
                   zeta = list(treatment = 0.04, control = 0.06), method = "bernoulli"),
      expected = c(fit_two(proxy_bridge),
                   list(proxy_rectangle = rectangle_list(proxy_bridge$confidence_set$bridge$proxy_rectangle),
                        bridge = proxy_bridge$confidence_set$bridge$assumption))
    )
  )
)

plan_design <- cmr_plan(n = 1000, sigma1 = 0.5, sigma0 = 0.25, alpha = 0.05,
                        method = "bounded", desired_pilot = 100, accounting = "design_only")
plan_pooled <- cmr_plan(n = 1000, sigma1 = 0.5, sigma0 = 0.25, alpha = 0.05,
                        method = "bounded", desired_pilot = 100, accounting = "pooled")
write_fixture(
  "pilot_planning.json",
  "Appendix E activation thresholds, break-even, and pilot-plan statuses.",
  list(
    list(
      name = "activation_thresholds",
      input = list(alpha = as.list(c(0.05, 0.10, 0.01))),
      expected = list(bounded_005 = activation_threshold_bounded(0.05),
                      bounded_010 = activation_threshold_bounded(0.10),
                      bounded_001 = activation_threshold_bounded(0.01),
                      bernoulli_005 = activation_threshold_bernoulli(0.05))
    ),
    list(
      name = "design_only_break_even",
      input = list(n = 1000, sigma1 = 0.5, sigma0 = 0.25, alpha = 0.05,
                   method = "bounded", desired_pilot = 100, accounting = "design_only"),
      expected = list(activation_threshold = plan_design$band$activation_threshold,
                      break_even_share = scalar(plan_design$band$break_even_share),
                      break_even_total = scalar(plan_design$band$break_even_total),
                      default_two_thirds_power = plan_design$default_two_thirds_power,
                      suggested_pilot = plan_design$suggested_pilot,
                      desired_status = plan_design$desired_status,
                      min_feasible = plan_design$band$min_feasible,
                      max_feasible = plan_design$band$max_feasible)
    ),
    list(
      name = "pooled_keeps_activation",
      input = list(n = 1000, sigma1 = 0.5, sigma0 = 0.25, alpha = 0.05,
                   method = "bounded", desired_pilot = 100, accounting = "pooled"),
      expected = list(activation_threshold = plan_pooled$band$activation_threshold,
                      break_even_total = "Inf",
                      default_two_thirds_power = plan_pooled$default_two_thirds_power,
                      desired_status = plan_pooled$desired_status)
    )
  ),
  tolerance = 1e-12
)
