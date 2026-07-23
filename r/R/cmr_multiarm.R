# Multiple-treatment shared-control CMR rules.

.cmr_arm_order <- function(arms) {
  if (all(grepl("^[0-9]+$", arms))) {
    return(order(as.integer(arms)))
  }
  c(which(arms == "0"), which(arms != "0"))
}

.cmr_check_multiarm_variances <- function(variances, name = "variances") {
  if (is.list(variances) && !is.data.frame(variances)) {
    variances <- unlist(variances, use.names = TRUE)
  }
  variances <- .cmr_check_variance(variances, name)
  if (length(variances) < 2L) {
    .cmr_stop("`", name, "` must contain control plus at least one treatment arm.")
  }
  arms <- names(variances)
  if (is.null(arms) || any(arms == "")) {
    arms <- as.character(seq_along(variances) - 1L)
  }
  arms <- sub("^v", "", arms)
  names(variances) <- arms
  if (!"0" %in% arms) {
    .cmr_stop("`", name, "` must include control arm `0`.")
  }
  if (anyDuplicated(arms)) {
    .cmr_stop("Arm names in `", name, "` must be unique.")
  }
  variances[.cmr_arm_order(arms)]
}

.cmr_check_multiarm_rectangle <- function(rectangle) {
  if (is.list(rectangle) && !is.null(rectangle$rectangle)) {
    rectangle <- rectangle$rectangle
  }

  if (is.matrix(rectangle) || is.data.frame(rectangle)) {
    rect <- as.data.frame(rectangle)
    names(rect) <- tolower(names(rect))
    lower_col <- match(TRUE, names(rect) %in% c("lower", "l", "v_l"))
    upper_col <- match(TRUE, names(rect) %in% c("upper", "u", "v_u"))
    if (is.na(lower_col) || is.na(upper_col)) {
      .cmr_stop("Matrix/data-frame rectangles need lower and upper columns.")
    }
    arms <- if ("arm" %in% names(rect)) {
      as.character(rect$arm)
    } else {
      rownames(rect)
    }
    if (is.null(arms) || any(arms == "")) {
      arms <- as.character(seq_len(nrow(rect)) - 1L)
    }
    out <- cbind(
      lower = .cmr_check_variance(rect[[lower_col]], "lower"),
      upper = .cmr_check_variance(rect[[upper_col]], "upper")
    )
    rownames(out) <- sub("^v", "", arms)
  } else {
    if (is.list(rectangle)) {
      rectangle <- unlist(rectangle, use.names = TRUE)
    }
    rectangle <- .cmr_check_numeric(rectangle, "rectangle")
    nm <- names(rectangle)
    if (is.null(nm) || any(nm == "")) {
      .cmr_stop("Named-vector rectangles must have names like `v_l0` and `v_u0`.")
    }
    lower_names <- grep("^v_l", nm, value = TRUE)
    arms <- sub("^v_l", "", lower_names)
    if (length(arms) == 0L) {
      .cmr_stop("Named-vector rectangles must include lower endpoints named `v_l*`.")
    }
    upper_names <- paste0("v_u", arms)
    missing <- setdiff(upper_names, nm)
    if (length(missing) > 0L) {
      .cmr_stop("Rectangle is missing: ", paste(missing, collapse = ", "), ".")
    }
    out <- cbind(
      lower = .cmr_check_variance(rectangle[lower_names], "lower"),
      upper = .cmr_check_variance(rectangle[upper_names], "upper")
    )
    rownames(out) <- arms
  }

  if (nrow(out) < 2L) {
    .cmr_stop("A multi-arm rectangle must include control plus at least one treatment.")
  }
  if (!"0" %in% rownames(out)) {
    .cmr_stop("A multi-arm rectangle must include control arm `0`.")
  }
  if (anyDuplicated(rownames(out))) {
    .cmr_stop("Arm names in `rectangle` must be unique.")
  }
  if (any(out[, "lower"] > out[, "upper"] + 1e-12)) {
    .cmr_stop("Lower endpoints cannot exceed upper endpoints.")
  }
  out[.cmr_arm_order(rownames(out)), , drop = FALSE]
}

.cmr_multiarm_weights <- function(arms) {
  k <- length(arms) - 1L
  weights <- rep(1, length(arms))
  names(weights) <- arms
  weights[["0"]] <- k
  weights
}

multiarm_variance_objective <- function(pi, variances) {
  variances <- .cmr_check_multiarm_variances(variances)
  pi <- .cmr_check_simplex(pi, "pi")
  if (length(pi) != length(variances)) {
    .cmr_stop("`pi` and `variances` must have the same length.")
  }
  if (!is.null(names(pi))) {
    if (!all(names(variances) %in% names(pi))) {
      .cmr_stop("Named `pi` must include the same arms as `variances`.")
    }
    pi <- pi[names(variances)]
  }
  weights <- .cmr_multiarm_weights(names(variances))
  A <- matrix(weights * variances, nrow = 1L)
  .cmr_inverse_share_sums(pi, A)
}

multiarm_oracle_variance <- function(variances) {
  variances <- .cmr_check_multiarm_variances(variances)
  weights <- .cmr_multiarm_weights(names(variances))
  sum(sqrt(weights * variances))^2
}

assign_multiarm_neyman <- function(variances) {
  variances <- .cmr_check_multiarm_variances(variances)
  weights <- .cmr_multiarm_weights(names(variances))
  scores <- sqrt(weights * variances)
  if (sum(scores) > 0) {
    out <- scores / sum(scores)
  } else {
    out <- rep(1 / length(scores), length(scores))
  }
  names(out) <- names(variances)
  out
}

multiarm_regret <- function(pi, variances) {
  multiarm_variance_objective(pi, variances) - multiarm_oracle_variance(variances)
}

multiarm_rectangle_vertices <- function(rectangle, max_vertices = 65536L) {
  rectangle <- .cmr_check_multiarm_rectangle(rectangle)
  lower <- rectangle[, "lower"]
  upper <- rectangle[, "upper"]
  names(lower) <- rownames(rectangle)
  names(upper) <- rownames(rectangle)
  .cmr_hyperrectangle_vertices(lower, upper, max_vertices = max_vertices)
}

cmr_multiarm_from_rectangle <- function(rectangle,
                                        control = list(),
                                        max_vertices = 65536L) {
  rectangle <- .cmr_check_multiarm_rectangle(rectangle)
  arms <- rownames(rectangle)
  weights <- .cmr_multiarm_weights(arms)
  vertices <- multiarm_rectangle_vertices(rectangle, max_vertices = max_vertices)
  A <- sweep(vertices, 2L, weights, `*`)
  oracle <- rowSums(sqrt(A))^2
  default_variances <- rep(0.25, length(arms))
  names(default_variances) <- arms
  default_start <- assign_multiarm_neyman(default_variances)
  collapsed_rectangle <- all(rectangle[, "lower"] == rectangle[, "upper"])
  full_rectangle <- all(rectangle[, "lower"] == 0) && all(rectangle[, "upper"] == 0.25)

  if (collapsed_rectangle) {
    variances <- rectangle[, "lower"]
    names(variances) <- arms
    pi <- assign_multiarm_neyman(variances)
    details <- .cmr_vertex_certificate(pi, A, oracle, return_details = TRUE)
    solution <- list(
      pi = pi,
      value = details$value,
      vertex_regrets = details$vertex_regrets,
      active_vertices = details$active_vertices,
      diagnostics = list(
        solver = "collapsed_closed_form",
        active_components = arms,
        directional_violation = 0,
        converged = TRUE
      )
    )
  } else if (full_rectangle) {
    # With no variance information, the minimax allocation is the Neyman rule
    # evaluated at the common maximum variance in every arm.
    pi <- default_start
    details <- .cmr_vertex_certificate(pi, A, oracle, return_details = TRUE)
    solution <- list(
      pi = pi,
      value = details$value,
      vertex_regrets = details$vertex_regrets,
      active_vertices = details$active_vertices,
      diagnostics = list(
        solver = "full_rectangle_closed_form",
        active_components = arms,
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

  out <- list(
    pi = solution$pi,
    U_CMR = solution$value,
    rectangle = rectangle,
    vertices = vertices,
    vertex_regrets = solution$vertex_regrets,
    binding_vertices = rownames(vertices)[solution$active_vertices],
    diagnostics = c(
      solution$diagnostics,
      list(
        K = length(arms) - 1L,
        full_rectangle = full_rectangle,
        collapsed_rectangle = collapsed_rectangle
      )
    )
  )
  class(out) <- c("cmr_multiarm", "list")
  out
}

cmr_multiarm <- function(y,
                         arm,
                         alpha = 0.05,
                         method = c("auto", "bounded", "bernoulli",
                                    "maurer_pontil", "mp", "bernoulli_exact",
                                    "martinez_taboada_ramdas", "mtr"),
                         beta = NULL,
                         control_arm = 0,
                         normalize = FALSE,
                         lower = NULL,
                         upper = NULL,
                         na.rm = TRUE,
                         tol = 1e-11,
                         solver_control = list(),
                         max_vertices = 65536L) {
  method <- match.arg(method)
  confidence_set <- rectangle_multiarm(
    y = y,
    arm = arm,
    alpha = alpha,
    method = method,
    beta = beta,
    control_arm = control_arm,
    normalize = normalize,
    lower = lower,
    upper = upper,
    na.rm = na.rm,
    tol = tol
  )

  out <- cmr_multiarm_from_rectangle(
    confidence_set$rectangle,
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
