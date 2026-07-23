# Generic numerical solver for CMR vertex epigraph problems.
#
# The multi-arm and stratified extensions both reduce to
#
#   min_pi max_v { sum_i a[v, i] / pi[i] - oracle[v] }
#
# over a simplex. The helpers below keep that shared numerical layer in one
# place so the extension-specific files only construct the coefficient matrix.

.cmr_check_simplex <- function(pi, name = "pi", tol = 1e-10) {
  pi <- .cmr_check_numeric(pi, name)
  if (any(pi < -tol)) {
    .cmr_stop("`", name, "` must be nonnegative.")
  }
  pi <- pmax(pi, 0)
  total <- sum(pi)
  if (!is.finite(total) || abs(total - 1) > tol) {
    .cmr_stop("`", name, "` must sum to one.")
  }
  if (total > 0) {
    pi <- pi / total
  }
  pi
}

.cmr_normalize_simplex <- function(pi, name = "pi") {
  pi <- .cmr_check_numeric(pi, name)
  if (any(pi < -1e-12)) {
    .cmr_stop("`", name, "` must be nonnegative.")
  }
  pi <- pmax(pi, 0)
  total <- sum(pi)
  if (total <= 0) {
    .cmr_stop("`", name, "` must contain positive mass.")
  }
  pi / total
}

.cmr_hyperrectangle_vertices <- function(lower, upper, max_vertices = 65536L) {
  lower <- .cmr_check_variance(lower, "lower")
  upper <- .cmr_check_variance(upper, "upper")
  if (length(lower) != length(upper)) {
    .cmr_stop("`lower` and `upper` must have the same length.")
  }
  if (any(lower > upper + 1e-12)) {
    .cmr_stop("Lower endpoints cannot exceed upper endpoints.")
  }
  n_dim <- length(lower)
  n_vertices <- 2^n_dim
  max_vertices <- .cmr_check_scalar_integer(max_vertices, "max_vertices", lower = 1L)
  if (n_vertices > max_vertices) {
    .cmr_stop("The hyperrectangle has ", n_vertices, " vertices, exceeding `max_vertices`.")
  }

  grid <- expand.grid(rep(list(c(0, 1)), n_dim))
  vertices <- matrix(NA_real_, nrow = nrow(grid), ncol = n_dim)
  for (j in seq_len(n_dim)) {
    vertices[, j] <- ifelse(grid[[j]] == 0, lower[[j]], upper[[j]])
  }
  colnames(vertices) <- names(lower)
  rownames(vertices) <- paste0("vertex_", seq_len(nrow(vertices)))
  vertices
}

.cmr_check_vertex_problem <- function(A, oracle) {
  if (!is.matrix(A)) {
    A <- as.matrix(A)
  }
  storage.mode(A) <- "double"
  if (nrow(A) < 1L || ncol(A) < 1L) {
    .cmr_stop("`A` must have at least one row and one column.")
  }
  if (anyNA(A) || any(!is.finite(A)) || any(A < -1e-12)) {
    .cmr_stop("`A` must contain finite nonnegative entries.")
  }
  A <- pmax(A, 0)

  oracle <- .cmr_check_nonnegative(oracle, "oracle")
  if (length(oracle) != nrow(A)) {
    .cmr_stop("`oracle` must have one entry per row of `A`.")
  }

  if (is.null(colnames(A))) {
    colnames(A) <- paste0("component_", seq_len(ncol(A)))
  }

  list(A = A, oracle = oracle)
}

.cmr_inverse_share_sums <- function(pi, A) {
  pi <- as.numeric(pi)
  out <- numeric(nrow(A))
  for (j in seq_along(pi)) {
    if (pi[[j]] > 0) {
      out <- out + A[, j] / pi[[j]]
    } else if (any(A[, j] > 0)) {
      out[A[, j] > 0] <- Inf
    }
  }
  out
}

.cmr_vertex_regrets <- function(pi, A, oracle) {
  .cmr_inverse_share_sums(pi, A) - oracle
}

.cmr_vertex_certificate <- function(pi, A, oracle, return_details = FALSE) {
  values <- .cmr_vertex_regrets(pi, A, oracle)
  certificate <- max(values)
  if (!return_details) {
    return(certificate)
  }
  active <- which(values >= certificate - 1e-8)
  list(
    value = certificate,
    vertex_regrets = values,
    active_vertices = active
  )
}

.cmr_from_logits <- function(z) {
  z_full <- c(as.numeric(z), 0)
  z_full <- z_full - max(z_full)
  ez <- exp(z_full)
  ez / sum(ez)
}

.cmr_to_logits <- function(pi) {
  pi <- pmax(as.numeric(pi), .Machine$double.eps)
  pi <- pi / sum(pi)
  log(pi[-length(pi)] / pi[[length(pi)]])
}

.cmr_smooth_vertex_objective <- function(z, A, oracle, tau, gradient = FALSE) {
  pi <- .cmr_from_logits(z)
  values <- .cmr_vertex_regrets(pi, A, oracle)
  center <- max(values)
  weights <- exp((values - center) / tau)
  weights <- weights / sum(weights)
  value <- center + tau * log(sum(exp((values - center) / tau)))

  if (!gradient) {
    return(value)
  }

  grad_pi <- -colSums(A * matrix(weights, nrow = nrow(A), ncol = ncol(A)) /
                        matrix(pi^2, nrow = nrow(A), ncol = ncol(A), byrow = TRUE))
  mean_grad <- sum(pi * grad_pi)
  grad_z <- pi[-length(pi)] * (grad_pi[-length(pi)] - mean_grad)
  attr(value, "gradient") <- grad_z
  value
}

.cmr_true_vertex_objective_from_logits <- function(z, A, oracle) {
  pi <- .cmr_from_logits(z)
  max(.cmr_vertex_regrets(pi, A, oracle))
}

.cmr_directional_violation <- function(pi, A, oracle, eps = 1e-5) {
  pi <- as.numeric(pi)
  current <- max(.cmr_vertex_regrets(pi, A, oracle))
  best <- current
  n <- length(pi)
  for (from in seq_len(n)) {
    step <- min(eps, pi[[from]] / 2)
    if (step <= 0) {
      next
    }
    for (to in seq_len(n)) {
      if (to == from) {
        next
      }
      candidate <- pi
      candidate[[from]] <- candidate[[from]] - step
      candidate[[to]] <- candidate[[to]] + step
      best <- min(best, max(.cmr_vertex_regrets(candidate, A, oracle)))
    }
  }
  max(0, current - best)
}

.cmr_vertex_starts <- function(A, default_start = NULL, max_starts = 40L) {
  n <- ncol(A)
  starts <- list()

  if (!is.null(default_start)) {
    starts[[length(starts) + 1L]] <- .cmr_normalize_simplex(default_start, "default_start")
  }
  starts[[length(starts) + 1L]] <- rep(1 / n, n)

  mean_score <- sqrt(colMeans(A))
  if (sum(mean_score) > 0) {
    starts[[length(starts) + 1L]] <- mean_score / sum(mean_score)
  }

  max_score <- sqrt(apply(A, 2, max))
  if (sum(max_score) > 0) {
    starts[[length(starts) + 1L]] <- max_score / sum(max_score)
  }

  vertex_starts <- list()
  for (i in seq_len(nrow(A))) {
    score <- sqrt(A[i, ])
    if (sum(score) > 0) {
      vertex_starts[[length(vertex_starts) + 1L]] <- score / sum(score)
    }
  }
  if (length(vertex_starts) > 0L) {
    vertex_matrix <- do.call(rbind, vertex_starts)
    starts[[length(starts) + 1L]] <- colMeans(vertex_matrix)
    take <- seq_len(min(nrow(vertex_matrix), max(0L, max_starts - length(starts))))
    for (i in take) {
      starts[[length(starts) + 1L]] <- vertex_matrix[i, ]
    }
  }

  starts <- lapply(starts, function(x) {
    x <- pmax(as.numeric(x), .Machine$double.eps)
    x / sum(x)
  })
  unique_keys <- !duplicated(vapply(starts, function(x) paste(signif(x, 12), collapse = ","), character(1)))
  starts[unique_keys]
}

.cmr_mirror_refine <- function(pi, A, oracle, iterations = 1000L) {
  iterations <- .cmr_check_scalar_integer(iterations, "iterations", lower = 1L)
  pi <- pmax(as.numeric(pi), .Machine$double.eps)
  pi <- pi / sum(pi)
  best_pi <- pi
  best_value <- max(.cmr_vertex_regrets(pi, A, oracle))

  for (iter in seq_len(iterations)) {
    values <- .cmr_vertex_regrets(pi, A, oracle)
    active <- which(values >= max(values) - 1e-9)
    grad <- -colMeans(A[active, , drop = FALSE] /
                        matrix(pi^2, nrow = length(active), ncol = length(pi), byrow = TRUE))
    step <- 0.25 / sqrt(iter) / max(1, max(abs(grad)))
    log_pi <- log(pmax(pi, .Machine$double.eps)) - step * grad
    log_pi <- log_pi - max(log_pi)
    pi <- exp(log_pi)
    pi <- pi / sum(pi)

    value <- max(.cmr_vertex_regrets(pi, A, oracle))
    if (value < best_value) {
      best_value <- value
      best_pi <- pi
    }
  }

  list(pi = best_pi, value = best_value)
}

.cmr_solve_vertex_epigraph <- function(A,
                                       oracle,
                                       default_start = NULL,
                                       control = list()) {
  checked <- .cmr_check_vertex_problem(A, oracle)
  A <- checked$A
  oracle <- checked$oracle
  component_names <- colnames(A)

  active_columns <- apply(A, 2, max) > 1e-14
  if (!any(active_columns)) {
    pi <- if (is.null(default_start)) {
      rep(1 / ncol(A), ncol(A))
    } else {
      .cmr_normalize_simplex(default_start, "default_start")
    }
    names(pi) <- component_names
    details <- .cmr_vertex_certificate(pi, A, oracle, return_details = TRUE)
    return(list(
      pi = pi,
      value = details$value,
      vertex_regrets = details$vertex_regrets,
      active_vertices = details$active_vertices,
      diagnostics = list(
        solver = "all_zero_coefficients",
        active_components = component_names,
        directional_violation = 0,
        converged = TRUE
      )
    ))
  }

  A_active <- A[, active_columns, drop = FALSE]
  default_active <- NULL
  if (!is.null(default_start)) {
    default_start <- .cmr_normalize_simplex(default_start, "default_start")
    default_active <- default_start[active_columns]
    if (sum(default_active) > 0) {
      default_active <- default_active / sum(default_active)
    } else {
      default_active <- NULL
    }
  }

  if (ncol(A_active) == 1L) {
    pi_active <- 1
    value_active <- max(.cmr_vertex_regrets(pi_active, A_active, oracle))
    pi <- numeric(ncol(A))
    pi[active_columns] <- pi_active
    names(pi) <- component_names
    details <- .cmr_vertex_certificate(pi, A, oracle, return_details = TRUE)
    return(list(
      pi = pi,
      value = details$value,
      vertex_regrets = details$vertex_regrets,
      active_vertices = details$active_vertices,
      diagnostics = list(
        solver = "single_active_component",
        active_components = component_names[active_columns],
        directional_violation = 0,
        converged = TRUE
      )
    ))
  }

  max_starts <- control$max_starts %||% 40L
  starts <- .cmr_vertex_starts(A_active, default_start = default_active, max_starts = max_starts)
  scale_value <- max(
    1,
    max(abs(oracle)),
    max(.cmr_inverse_share_sums(rep(1 / ncol(A_active), ncol(A_active)), A_active))
  )
  taus <- control$smooth_taus %||% (scale_value * c(1e-2, 3e-3, 1e-3, 3e-4, 1e-4))
  maxit <- control$maxit %||% 1000L

  candidates <- list()
  for (start in starts) {
    z <- .cmr_to_logits(start)
    convergence <- integer(0)
    for (tau in taus) {
      opt <- stats::optim(
        par = z,
        fn = function(par) .cmr_smooth_vertex_objective(par, A_active, oracle, tau),
        gr = function(par) {
          value <- .cmr_smooth_vertex_objective(par, A_active, oracle, tau, gradient = TRUE)
          attr(value, "gradient")
        },
        method = "BFGS",
        control = list(maxit = maxit, reltol = 1e-12)
      )
      z <- opt$par
      convergence <- c(convergence, opt$convergence)
    }

    if (length(z) == 1L) {
      opt_nm <- stats::optimize(
        f = function(par) .cmr_true_vertex_objective_from_logits(par, A_active, oracle),
        interval = c(-40, 40),
        tol = 1e-14
      )
      z <- opt_nm$minimum
      nm_convergence <- 0L
    } else {
      opt_nm <- stats::optim(
        par = z,
        fn = function(par) .cmr_true_vertex_objective_from_logits(par, A_active, oracle),
        method = "Nelder-Mead",
        control = list(maxit = maxit, reltol = 1e-12)
      )
      z <- opt_nm$par
      nm_convergence <- opt_nm$convergence
    }
    pi_active <- .cmr_from_logits(z)
    value <- max(.cmr_vertex_regrets(pi_active, A_active, oracle))
    candidates[[length(candidates) + 1L]] <- list(
      pi = pi_active,
      value = value,
      convergence = c(convergence, nm_convergence)
    )
  }

  values <- vapply(candidates, `[[`, numeric(1), "value")
  best <- candidates[[which.min(values)]]
  mirror_iterations <- control$mirror_iterations %||% 1000L
  if (mirror_iterations > 0) {
    refined <- .cmr_mirror_refine(best$pi, A_active, oracle, iterations = mirror_iterations)
    if (refined$value < best$value) {
      best$pi <- refined$pi
      best$value <- refined$value
    }
  }

  pi <- numeric(ncol(A))
  pi[active_columns] <- best$pi
  names(pi) <- component_names
  details <- .cmr_vertex_certificate(pi, A, oracle, return_details = TRUE)
  directional_violation <- .cmr_directional_violation(best$pi, A_active, oracle)

  list(
    pi = pi,
    value = details$value,
    vertex_regrets = details$vertex_regrets,
    active_vertices = details$active_vertices,
    diagnostics = list(
      solver = "smooth_max_bfgs_nelder_mead",
      active_components = component_names[active_columns],
      starts = length(starts),
      best_start_value = min(values),
      directional_violation = directional_violation,
      converged = directional_violation <= 1e-6,
      active_column_mask = active_columns
    )
  )
}

.cmr_integer_compositions <- function(total, parts) {
  total <- .cmr_check_scalar_integer(total, "total", lower = 0L)
  parts <- .cmr_check_scalar_integer(parts, "parts", lower = 1L)
  if (parts == 1L) {
    return(matrix(total, nrow = 1L, ncol = 1L))
  }

  rows <- vector("list", total + 1L)
  for (first in 0:total) {
    rest <- .cmr_integer_compositions(total - first, parts - 1L)
    rows[[first + 1L]] <- cbind(first, rest)
  }
  do.call(rbind, rows)
}

.cmr_simplex_grid <- function(n_components, denominator) {
  n_components <- .cmr_check_scalar_integer(n_components, "n_components", lower = 1L)
  denominator <- .cmr_check_scalar_integer(denominator, "denominator", lower = 1L)
  .cmr_integer_compositions(denominator, n_components) / denominator
}

.cmr_bruteforce_vertex_solution <- function(A, oracle, denominator = 40L) {
  checked <- .cmr_check_vertex_problem(A, oracle)
  A <- checked$A
  oracle <- checked$oracle
  grid <- .cmr_simplex_grid(ncol(A), denominator)
  values <- apply(grid, 1L, function(pi) max(.cmr_vertex_regrets(pi, A, oracle)))
  best <- which.min(values)
  pi <- grid[best, ]
  names(pi) <- colnames(A)
  list(
    pi = pi,
    value = values[[best]],
    denominator = denominator,
    grid_size = nrow(grid)
  )
}
