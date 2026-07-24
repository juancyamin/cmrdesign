# Stratified-design CMR rules.

.cmr_check_strata_share <- function(strata_share) {
  strata_share <- .cmr_check_numeric(strata_share, "strata_share")
  if (length(strata_share) < 1L) {
    .cmr_stop("`strata_share` must contain at least one stratum.")
  }
  if (any(strata_share <= 0)) {
    .cmr_stop("Every stratum share must be positive.")
  }
  total <- sum(strata_share)
  if (abs(total - 1) > 1e-10) {
    .cmr_stop("`strata_share` must sum to one.")
  }
  strata_share <- strata_share / total
  if (is.null(names(strata_share)) || any(names(strata_share) == "")) {
    names(strata_share) <- paste0("stratum_", seq_along(strata_share))
  }
  strata_share
}

.cmr_standardize_stratified_matrix <- function(x,
                                               strata_share,
                                               name,
                                               check_variance = TRUE) {
  if (is.data.frame(x)) {
    x <- as.matrix(x)
  }
  if (!is.matrix(x)) {
    .cmr_stop("`", name, "` must be a 2 x S matrix or data frame.")
  }
  storage.mode(x) <- "double"
  if (nrow(x) != 2L) {
    .cmr_stop("`", name, "` must have exactly two rows: treatment and control.")
  }
  if (ncol(x) != length(strata_share)) {
    .cmr_stop("`", name, "` must have one column per stratum.")
  }

  row_names <- rownames(x)
  if (!is.null(row_names)) {
    lower_rows <- tolower(row_names)
    treatment_row <- which(lower_rows %in% c("1", "treatment", "treated", "treat"))
    control_row <- which(lower_rows %in% c("0", "control", "ctrl"))
    if (length(treatment_row) == 1L && length(control_row) == 1L) {
      x <- x[c(treatment_row, control_row), , drop = FALSE]
    }
  }
  rownames(x) <- c("1", "0")

  if (is.null(colnames(x)) || any(colnames(x) == "")) {
    colnames(x) <- names(strata_share)
  }
  if (!identical(colnames(x), names(strata_share))) {
    if (all(names(strata_share) %in% colnames(x))) {
      x <- x[, names(strata_share), drop = FALSE]
    } else {
      .cmr_stop("Column names in `", name, "` must match `strata_share` names.")
    }
  }

  x[] <- if (check_variance) {
    .cmr_check_variance(as.numeric(x), name)
  } else {
    .cmr_check_numeric(as.numeric(x), name)
  }
  x
}

.cmr_stratified_cell_names <- function(strata_names) {
  as.vector(rbind(
    paste0("1:", strata_names),
    paste0("0:", strata_names)
  ))
}

.cmr_stratified_matrix_to_vector <- function(x) {
  out <- as.vector(x)
  names(out) <- .cmr_stratified_cell_names(colnames(x))
  out
}

.cmr_stratified_vector_to_matrix <- function(x, strata_names) {
  matrix(
    x,
    nrow = 2L,
    byrow = FALSE,
    dimnames = list(c("1", "0"), strata_names)
  )
}

.cmr_check_stratified_variances <- function(variances, strata_share, name = "variances") {
  strata_share <- .cmr_check_strata_share(strata_share)
  matrix_variances <- .cmr_standardize_stratified_matrix(variances, strata_share, name)
  list(
    matrix = matrix_variances,
    vector = .cmr_stratified_matrix_to_vector(matrix_variances),
    strata_share = strata_share,
    cell_names = .cmr_stratified_cell_names(names(strata_share)),
    weights = rep(strata_share^2, each = 2L)
  )
}

.cmr_check_stratified_pi <- function(pi, strata_share) {
  strata_share <- .cmr_check_strata_share(strata_share)
  if (is.matrix(pi) || is.data.frame(pi)) {
    pi <- .cmr_standardize_stratified_matrix(
      pi,
      strata_share,
      "pi",
      check_variance = FALSE
    )
    pi <- .cmr_stratified_matrix_to_vector(pi)
  } else {
    pi <- .cmr_check_numeric(pi, "pi")
    if (length(pi) != 2L * length(strata_share)) {
      .cmr_stop("`pi` must contain two cell shares per stratum.")
    }
    expected <- .cmr_stratified_cell_names(names(strata_share))
    if (!is.null(names(pi)) && all(expected %in% names(pi))) {
      pi <- pi[expected]
    } else {
      names(pi) <- expected
    }
  }
  .cmr_check_simplex(pi, "pi")
}

.cmr_check_stratified_rectangle <- function(rectangle, strata_share) {
  strata_share <- .cmr_check_strata_share(strata_share)
  if (!is.list(rectangle) || is.null(rectangle$lower) || is.null(rectangle$upper)) {
    .cmr_stop("`rectangle` must be a list with `lower` and `upper` 2 x S matrices.")
  }
  lower <- .cmr_standardize_stratified_matrix(rectangle$lower, strata_share, "rectangle$lower")
  upper <- .cmr_standardize_stratified_matrix(rectangle$upper, strata_share, "rectangle$upper")
  if (any(lower > upper + 1e-12)) {
    .cmr_stop("Lower endpoints cannot exceed upper endpoints.")
  }
  lower_vec <- .cmr_stratified_matrix_to_vector(lower)
  upper_vec <- .cmr_stratified_matrix_to_vector(upper)
  list(
    lower = lower_vec,
    upper = upper_vec,
    lower_matrix = lower,
    upper_matrix = upper,
    strata_share = strata_share,
    cell_names = names(lower_vec),
    weights = rep(strata_share^2, each = 2L)
  )
}

#' Stratified variance objectives and Neyman allocation
#'
#' Helper functions for stratified two-arm variance objectives, oracle values,
#' Neyman allocations, regret, and rectangle vertices.
#'
#' @param pi Assignment shares for each treatment/control by stratum cell. A
#'   vector should be named like `"1:A"` and `"0:A"`, or a `2 x S` matrix with
#'   treatment and control rows.
#' @param variances Cell variances as a `2 x S` matrix or data frame with
#'   treatment and control rows.
#' @param strata_share Named stratum population shares that sum to one.
#' @param rectangle Stratified variance rectangle, a list with `lower` and
#'   `upper` `2 x S` matrices.
#' @param max_vertices Maximum number of hyperrectangle vertices to enumerate.
#'
#' @return
#' Numeric objective/regret values, named assignment vectors, or a vertex matrix.
#' `assign_stratified_neyman()` returns total assignment shares over
#' treatment/control by stratum cells.
#'
#' @examples
#' strata_share <- c(A = 0.4, B = 0.6)
#' variances <- rbind(
#'   treatment = c(A = 0.10, B = 0.04),
#'   control = c(A = 0.05, B = 0.08)
#' )
#' pi <- assign_stratified_neyman(variances, strata_share)
#' stratified_variance_objective(pi, variances, strata_share)
#'
#' @family assignment helpers
#' @family rectangle helpers
#' @export
stratified_variance_objective <- function(pi, variances, strata_share) {
  checked <- .cmr_check_stratified_variances(variances, strata_share)
  pi <- .cmr_check_stratified_pi(pi, checked$strata_share)
  A <- matrix(checked$weights * checked$vector, nrow = 1L)
  .cmr_inverse_share_sums(pi, A)
}

#' @rdname stratified_variance_objective
#' @export
stratified_oracle_variance <- function(variances, strata_share) {
  checked <- .cmr_check_stratified_variances(variances, strata_share)
  sum(sqrt(checked$weights * checked$vector))^2
}

#' @rdname stratified_variance_objective
#' @export
assign_stratified_neyman <- function(variances, strata_share) {
  checked <- .cmr_check_stratified_variances(variances, strata_share)
  scores <- sqrt(checked$weights * checked$vector)
  if (sum(scores) > 0) {
    out <- scores / sum(scores)
  } else {
    out <- rep(checked$strata_share / 2, each = 2L)
  }
  names(out) <- checked$cell_names
  out
}

#' @rdname stratified_variance_objective
#' @export
stratified_regret <- function(pi, variances, strata_share) {
  stratified_variance_objective(pi, variances, strata_share) -
    stratified_oracle_variance(variances, strata_share)
}

#' @rdname stratified_variance_objective
#' @export
stratified_rectangle_vertices <- function(rectangle,
                                          strata_share,
                                          max_vertices = 65536L) {
  checked <- .cmr_check_stratified_rectangle(rectangle, strata_share)
  .cmr_hyperrectangle_vertices(
    checked$lower,
    checked$upper,
    max_vertices = max_vertices
  )
}

#' Stratified CMR from a variance rectangle
#'
#' Compute a stratified CMR allocation from a supplied cell-level variance
#' rectangle.
#'
#' @param rectangle Stratified variance rectangle, a list with `lower` and
#'   `upper` `2 x S` matrices.
#' @param strata_share Named stratum population shares that sum to one.
#' @param control Optional list of solver controls for the general vertex
#'   epigraph solver.
#' @param max_vertices Maximum number of hyperrectangle vertices to enumerate.
#'
#' @return
#' A list of class `cmr_stratified` with assignment shares `pi`, `pi_matrix`,
#' stratum sampling margins, within-stratum treatment margins, CMR certificate
#' `U_CMR`, checked rectangle, vertex diagnostics, and solver diagnostics.
#'
#' @examples
#' strata_share <- c(A = 0.4, B = 0.6)
#' rect <- list(
#'   lower = rbind(treatment = c(A = 0.01, B = 0.04),
#'                 control = c(A = 0.02, B = 0.03)),
#'   upper = rbind(treatment = c(A = 0.08, B = 0.12),
#'                 control = c(A = 0.09, B = 0.10))
#' )
#' cmr_stratified_from_rectangle(rect, strata_share)
#'
#' @family CMR rules
#' @family rectangle helpers
#' @export
cmr_stratified_from_rectangle <- function(rectangle,
                                          strata_share,
                                          control = list(),
                                          max_vertices = 65536L) {
  checked <- .cmr_check_stratified_rectangle(rectangle, strata_share)
  vertices <- stratified_rectangle_vertices(
    rectangle,
    strata_share = checked$strata_share,
    max_vertices = max_vertices
  )
  A <- sweep(vertices, 2L, checked$weights, `*`)
  oracle <- rowSums(sqrt(A))^2
  default_start <- rep(checked$strata_share / 2, each = 2L)
  names(default_start) <- checked$cell_names
  collapsed_rectangle <- all(checked$lower == checked$upper)
  full_rectangle <- all(checked$lower == 0) && all(checked$upper == 0.25)

  if (collapsed_rectangle) {
    pi <- assign_stratified_neyman(checked$lower_matrix, checked$strata_share)
    details <- .cmr_vertex_certificate(pi, A, oracle, return_details = TRUE)
    solution <- list(
      pi = pi,
      value = details$value,
      vertex_regrets = details$vertex_regrets,
      active_vertices = details$active_vertices,
      diagnostics = list(
        solver = "collapsed_closed_form",
        active_components = checked$cell_names,
        directional_violation = 0,
        converged = TRUE
      )
    )
  } else if (full_rectangle) {
    # With no cell-level variance information, the minimax allocation preserves
    # target stratum shares and splits treatment/control evenly within stratum.
    pi <- default_start
    details <- .cmr_vertex_certificate(pi, A, oracle, return_details = TRUE)
    solution <- list(
      pi = pi,
      value = details$value,
      vertex_regrets = details$vertex_regrets,
      active_vertices = details$active_vertices,
      diagnostics = list(
        solver = "full_rectangle_closed_form",
        active_components = checked$cell_names,
        directional_violation = 0,
        converged = TRUE
      )
    )
  } else {
    solution <- .cmr_solve_vertex_epigraph(
      A = A,
      oracle = oracle,
      default_start = default_start,
      control = control
    )
  }

  sampling_margin <- tapply(
    solution$pi,
    rep(names(checked$strata_share), each = 2L),
    sum
  )
  sampling_margin <- as.numeric(sampling_margin[names(checked$strata_share)])
  names(sampling_margin) <- names(checked$strata_share)
  treatment_margin <- solution$pi[paste0("1:", names(checked$strata_share))] / sampling_margin
  names(treatment_margin) <- names(checked$strata_share)

  out <- list(
    pi = solution$pi,
    pi_matrix = .cmr_stratified_vector_to_matrix(solution$pi, names(checked$strata_share)),
    sampling_margin = sampling_margin,
    treatment_margin = treatment_margin,
    U_CMR = solution$value,
    rectangle = checked,
    vertices = vertices,
    vertex_regrets = solution$vertex_regrets,
    binding_vertices = rownames(vertices)[solution$active_vertices],
    diagnostics = c(
      solution$diagnostics,
      list(
        S = length(checked$strata_share),
        full_rectangle = full_rectangle,
        collapsed_rectangle = collapsed_rectangle
      )
    )
  )
  class(out) <- c("cmr_stratified", "list")
  out
}

#' Stratified CMR assignment
#'
#' Estimate cell-specific variance confidence intervals from pilot data and
#' return the stratified CMR assignment across treatment/control by stratum
#' cells.
#'
#' @param y Pilot outcomes.
#' @param d Pilot treatment indicator; treatment is `1` and control is `0`.
#' @param strata Pilot stratum labels.
#' @param strata_share Named stratum population shares that sum to one.
#' @param alpha Target joint error level.
#' @param method Confidence-set method. `"auto"` chooses exact Bernoulli bounds
#'   for 0/1 outcomes and bounded Maurer–Pontil bounds otherwise.
#' @param beta Optional endpoint error allocation. If `NULL`, Bonferroni error
#'   is split across all lower and upper treatment/control by stratum endpoints.
#' @param normalize If `TRUE`, normalize bounded outcomes to `[0, 1]` before
#'   computing variances.
#' @param lower,upper Optional lower and upper outcome bounds used when
#'   `normalize = TRUE`.
#' @param na.rm If `TRUE`, drop rows with missing `y`, `d`, or `strata`.
#' @param tol Numerical tolerance for exact Bernoulli bound inversion.
#' @param solver_control Optional list of solver controls for the general
#'   vertex epigraph solver.
#' @param max_vertices Maximum number of hyperrectangle vertices to enumerate.
#'
#' @return
#' A list of class `cmr_stratified` with total cell assignment shares `pi`,
#' matrix form `pi_matrix`, sampling and treatment margins, CMR certificate
#' `U_CMR`, confidence set, pilot summaries, endpoint error allocation, and
#' diagnostics.
#'
#' @examples
#' set.seed(7)
#' strata <- rep(c("A", "B"), each = 40)
#' d <- rep(rep(c(1, 0), each = 20), 2)
#' y <- c(rbeta(20, 2, 6), rbeta(20, 4, 4),
#'        rbeta(20, 5, 3), rbeta(20, 3, 5))
#' cmr_stratified(y, d, strata, strata_share = c(A = 0.45, B = 0.55))
#'
#' @family CMR rules
#' @export
cmr_stratified <- function(y,
                           d,
                           strata,
                           strata_share,
                           alpha = 0.05,
                           method = c("auto", "bounded", "bernoulli",
                                      "maurer_pontil", "mp", "bernoulli_exact",
                                      "martinez_taboada_ramdas", "mtr"),
                           beta = NULL,
                           normalize = FALSE,
                           lower = NULL,
                           upper = NULL,
                           na.rm = TRUE,
                           tol = 1e-11,
                           solver_control = list(),
                           max_vertices = 65536L) {
  method <- match.arg(method)
  confidence_set <- rectangle_stratified(
    y = y,
    d = d,
    strata = strata,
    strata_share = strata_share,
    alpha = alpha,
    method = method,
    beta = beta,
    normalize = normalize,
    lower = lower,
    upper = upper,
    na.rm = na.rm,
    tol = tol
  )

  out <- cmr_stratified_from_rectangle(
    confidence_set$rectangle,
    strata_share = confidence_set$strata_share,
    control = solver_control,
    max_vertices = max_vertices
  )
  out$confidence_set <- confidence_set
  out$pilot <- list(
    n = confidence_set$n,
    vhat = confidence_set$vhat,
    method = confidence_set$method,
    normalization = confidence_set$normalization
  )
  out$alpha <- confidence_set$alpha
  out$beta <- confidence_set$beta
  out$method <- confidence_set$method
  out$joint_error_bound <- confidence_set$joint_error_bound
  out$diagnostics$confidence_method <- confidence_set$method
  out$diagnostics$joint_error_bound <- confidence_set$joint_error_bound
  out
}
