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

stratified_variance_objective <- function(pi, variances, strata_share) {
  checked <- .cmr_check_stratified_variances(variances, strata_share)
  pi <- .cmr_check_stratified_pi(pi, checked$strata_share)
  A <- matrix(checked$weights * checked$vector, nrow = 1L)
  .cmr_inverse_share_sums(pi, A)
}

stratified_oracle_variance <- function(variances, strata_share) {
  checked <- .cmr_check_stratified_variances(variances, strata_share)
  sum(sqrt(checked$weights * checked$vector))^2
}

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

stratified_regret <- function(pi, variances, strata_share) {
  stratified_variance_objective(pi, variances, strata_share) -
    stratified_oracle_variance(variances, strata_share)
}

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
