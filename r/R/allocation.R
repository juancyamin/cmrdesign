# Integer allocation realization helpers.

.cmr_is_cmr_fit <- function(x) {
  is.list(x) && !is.null(x$pi) && !is.null(x$U_CMR)
}

.cmr_normalize_allocation_shares <- function(values, labels, name = "pi") {
  values <- .cmr_check_numeric(values, name)
  if (length(values) != length(labels)) {
    .cmr_stop("`pi` must have one share per label.")
  }
  if (any(values < -1e-12)) {
    .cmr_stop("Assignment shares must be nonnegative.")
  }
  values <- pmax(values, 0)
  total <- sum(values)
  if (total <= 0) {
    .cmr_stop("Assignment shares must contain positive mass.")
  }
  out <- values / total
  names(out) <- labels
  out
}

.cmr_allocation_vector_target <- function(target) {
  if (is.list(target) && !is.data.frame(target)) {
    target <- unlist(target, use.names = TRUE)
  }
  values <- .cmr_check_numeric(target, "pi")
  labels <- names(values)
  if (is.null(labels) || any(labels == "")) {
    labels <- as.character(seq_along(values) - 1L)
  }
  shares <- .cmr_normalize_allocation_shares(values, labels)
  list(labels = labels, shares = shares)
}

.cmr_largest_remainder_counts <- function(shares,
                                          labels,
                                          n_main,
                                          min_per_arm = 1L) {
  labels <- as.character(labels)
  n_main <- .cmr_check_scalar_integer(n_main, "n_main", lower = 0L)
  min_per_arm <- .cmr_check_scalar_integer(min_per_arm, "min_per_arm", lower = 0L)
  shares <- .cmr_normalize_allocation_shares(shares, labels)

  active <- shares > 1e-12
  min_counts <- ifelse(active, min_per_arm, 0L)
  if (sum(min_counts) > n_main) {
    .cmr_stop(
      "`n_main` is too small for `min_per_arm` and the positive target shares; ",
      "increase `n_main` or set `min_per_arm = 0`."
    )
  }
  if (n_main == 0L) {
    out <- rep(0L, length(labels))
    names(out) <- labels
    return(out)
  }

  remaining <- n_main - sum(min_counts)
  desired <- pmax(n_main * shares - min_counts, 0)
  if (remaining == 0L) {
    counts <- min_counts
  } else {
    weights <- if (sum(desired) > 0) desired else shares
    exact <- remaining * weights / sum(weights)
    extras <- floor(exact)
    leftover <- remaining - sum(extras)
    if (leftover > 0L) {
      remainders <- exact - extras
      order_index <- order(-remainders, seq_along(labels))
      extras[order_index[seq_len(leftover)]] <-
        extras[order_index[seq_len(leftover)]] + 1L
    }
    counts <- min_counts + extras
  }

  out <- as.integer(counts)
  names(out) <- labels
  out
}

.cmr_realize_vector_allocation <- function(labels,
                                           shares,
                                           n_main,
                                           min_per_arm) {
  counts <- .cmr_largest_remainder_counts(
    shares,
    labels,
    n_main = n_main,
    min_per_arm = min_per_arm
  )
  n_total <- sum(counts)
  if (n_total <= 0L) {
    .cmr_stop("`n_main` must contain at least one main-wave unit.")
  }
  realized <- counts / n_total
  names(realized) <- names(counts)
  list(counts = counts, shares = realized)
}

.cmr_realize_stratified_counts <- function(target, strata_counts, min_per_arm) {
  if (is.null(names(target)) || any(names(target) == "")) {
    .cmr_stop("Stratified targets must use cell labels like `1:A` and `0:A`.")
  }
  if (any(!grepl(":", names(target), fixed = TRUE))) {
    .cmr_stop("Stratified targets must use cell labels like `1:A` and `0:A`.")
  }
  strata <- unique(sub("^[^:]+:", "", names(target)))

  if (is.list(strata_counts) && !is.data.frame(strata_counts)) {
    strata_counts <- unlist(strata_counts, use.names = TRUE)
  }
  strata_counts <- .cmr_check_numeric(strata_counts, "strata_counts")
  if (is.null(names(strata_counts)) || any(names(strata_counts) == "")) {
    .cmr_stop("`strata_counts` must be named by stratum.")
  }

  counts <- integer(0)
  for (stratum in strata) {
    if (!stratum %in% names(strata_counts)) {
      .cmr_stop("`strata_counts` is missing stratum `", stratum, "`.")
    }
    n_stratum <- .cmr_check_scalar_integer(
      strata_counts[[stratum]],
      paste0("strata_counts[", stratum, "]"),
      lower = 0L
    )
    labels <- paste0(c("1:", "0:"), stratum)
    missing <- setdiff(labels, names(target))
    if (length(missing) > 0L) {
      .cmr_stop("Stratified targets are missing cells: ", paste(missing, collapse = ", "), ".")
    }
    positive <- pmax(target[labels], 0)
    denom <- sum(positive)
    within <- if (denom <= 0) rep(0.5, 2L) else positive / denom
    counts <- c(
      counts,
      .cmr_largest_remainder_counts(
        within,
        labels,
        n_main = n_stratum,
        min_per_arm = min_per_arm
      )
    )
  }

  n_total <- sum(counts)
  if (n_total <= 0L) {
    .cmr_stop("`strata_counts` must contain at least one main-wave unit.")
  }
  shares <- counts / n_total
  names(shares) <- names(counts)
  list(counts = counts, shares = shares)
}

.cmr_is_stratified_target <- function(labels) {
  all(grepl(":", labels, fixed = TRUE))
}

.cmr_two_arm_allocation_certificate <- function(fit, pi) {
  if (is.null(fit$rectangle)) {
    return(NULL)
  }
  rectangle <- .cmr_check_unbounded_rectangle(fit$rectangle)
  corners <- .cmr_unbounded_rectangle_corners(rectangle)
  regret_plus <- .cmr_unbounded_regret(
    pi = pi,
    v1 = corners["treatment_high_control_low", "v1"],
    v0 = corners["treatment_high_control_low", "v0"]
  )
  regret_minus <- .cmr_unbounded_regret(
    pi = pi,
    v1 = corners["treatment_low_control_high", "v1"],
    v0 = corners["treatment_low_control_high", "v0"]
  )
  corner_regrets <- c(
    treatment_high_control_low = regret_plus,
    treatment_low_control_high = regret_minus
  )
  list(
    value = max(corner_regrets),
    corner_regrets = corner_regrets
  )
}

.cmr_multiarm_allocation_certificate <- function(fit, shares, max_vertices) {
  rectangle <- .cmr_check_multiarm_rectangle(fit$rectangle)
  arms <- rownames(rectangle)
  missing <- setdiff(arms, names(shares))
  if (length(missing) > 0L) {
    .cmr_stop("Realized shares are missing arms: ", paste(missing, collapse = ", "), ".")
  }
  pi <- .cmr_normalize_simplex(shares[arms], "pi")
  vertices <- multiarm_rectangle_vertices(rectangle, max_vertices = max_vertices)
  weights <- .cmr_multiarm_weights(arms)
  A <- sweep(vertices, 2L, weights, `*`)
  oracle <- rowSums(sqrt(A))^2
  details <- .cmr_vertex_certificate(pi, A, oracle, return_details = TRUE)
  list(
    value = details$value,
    vertex_regrets = details$vertex_regrets,
    binding_vertices = rownames(vertices)[details$active_vertices]
  )
}

.cmr_checked_stratified_rectangle_for_allocation <- function(fit) {
  rectangle <- fit$rectangle
  if (is.list(rectangle) &&
      !is.null(rectangle$lower_matrix) &&
      !is.null(rectangle$upper_matrix) &&
      !is.null(rectangle$strata_share)) {
    return(rectangle)
  }
  strata_share <- fit$strata_share %||%
    fit$confidence_set$strata_share %||%
    rectangle$strata_share %||%
    NULL
  if (is.null(strata_share)) {
    return(NULL)
  }
  .cmr_check_stratified_rectangle(rectangle, strata_share)
}

.cmr_stratified_allocation_certificate <- function(fit, shares, max_vertices) {
  checked <- .cmr_checked_stratified_rectangle_for_allocation(fit)
  if (is.null(checked)) {
    return(NULL)
  }
  missing <- setdiff(checked$cell_names, names(shares))
  if (length(missing) > 0L) {
    .cmr_stop("Realized shares are missing cells: ", paste(missing, collapse = ", "), ".")
  }
  vertices <- .cmr_hyperrectangle_vertices(
    checked$lower,
    checked$upper,
    max_vertices = max_vertices
  )
  A <- sweep(vertices, 2L, checked$weights, `*`)
  oracle <- rowSums(sqrt(A))^2
  pi <- .cmr_normalize_simplex(shares[checked$cell_names], "pi")
  details <- .cmr_vertex_certificate(pi, A, oracle, return_details = TRUE)
  list(
    value = details$value,
    vertex_regrets = details$vertex_regrets,
    binding_vertices = rownames(vertices)[details$active_vertices]
  )
}

.cmr_allocation_certificate <- function(fit,
                                        realized_pi,
                                        realized_shares,
                                        design,
                                        max_vertices) {
  if (is.null(fit)) {
    return(NULL)
  }
  if (inherits(fit, "cmr_stratified") || identical(design, "stratified")) {
    return(.cmr_stratified_allocation_certificate(
      fit,
      realized_shares,
      max_vertices = max_vertices
    ))
  }
  if (inherits(fit, "cmr_multiarm")) {
    return(.cmr_multiarm_allocation_certificate(
      fit,
      realized_shares,
      max_vertices = max_vertices
    ))
  }
  .cmr_two_arm_allocation_certificate(fit, realized_pi)
}

.cmr_allocation_excess <- function(realized, continuous) {
  if (is.null(realized) || is.null(continuous)) {
    return(NULL)
  }
  if (!is.finite(realized) || !is.finite(continuous)) {
    return(NULL)
  }
  realized - continuous
}

#' Convert CMR target shares to integer allocation counts
#'
#' Convert the continuous assignment shares returned by a CMR rule into
#' executable integer counts for a main-wave sample. Counts are rounded by the
#' deterministic largest-remainder rule. When `x` is a CMR result object,
#' `realize_allocation()` also recomputes the regret certificate at the realized
#' integer shares whenever the result contains enough rectangle information.
#'
#' @param x A CMR result object, a two-arm treatment share, or a named vector of
#'   target assignment shares. Multi-arm targets should be named by arm, with
#'   control arm `"0"` when using CMR multi-arm fits. Stratified targets should
#'   use cell names like `"1:A"` and `"0:A"`.
#' @param n_main Main-wave sample size to allocate. Required unless
#'   `strata_counts` is supplied.
#' @param strata_counts Optional named vector or list of fixed main-wave counts
#'   by stratum. When supplied, treatment/control counts are rounded within each
#'   stratum while preserving the stratum totals exactly.
#' @param min_per_arm Minimum integer count assigned to each positive target
#'   share. Set to `0` when zero counts are acceptable.
#' @param max_vertices Maximum number of hyperrectangle vertices to enumerate
#'   when recomputing multi-arm or stratified certificates.
#' @param ... Reserved for future extensions.
#'
#' @return
#' A list of class `cmr_allocation` with integer `counts`, realized `shares`,
#' realized `pi`, normalized `target_pi`, total `n_main`, rounding metadata,
#' continuous and realized CMR certificates when available, and diagnostics.
#'
#' @examples
#' set.seed(21)
#' d <- rep(c(1, 0), each = 40)
#' y <- c(rbeta(40, 2, 6), rbeta(40, 4, 4))
#' fit <- cmr_two_arm(y, d)
#' realize_allocation(fit, n_main = 101)
#'
#' realize_allocation(c("0" = 0.34, "1" = 0.33, "2" = 0.33), n_main = 10,
#'                    min_per_arm = 0)
#'
#' @family assignment helpers
#' @export
realize_allocation <- function(x,
                               n_main = NULL,
                               strata_counts = NULL,
                               min_per_arm = 1L,
                               max_vertices = 65536L) {
  fit <- if (.cmr_is_cmr_fit(x)) x else NULL
  target <- if (!is.null(fit)) fit$pi else x
  max_vertices <- .cmr_check_scalar_integer(max_vertices, "max_vertices", lower = 1L)
  min_per_arm <- .cmr_check_scalar_integer(min_per_arm, "min_per_arm", lower = 0L)
  if (!is.null(n_main)) {
    n_main <- .cmr_check_scalar_integer(n_main, "n_main", lower = 1L)
  }

  if (is.numeric(target) && length(target) == 1L && is.null(strata_counts)) {
    if (is.null(n_main)) {
      .cmr_stop("`n_main` is required unless `strata_counts` is supplied.")
    }
    pi <- .cmr_check_probability(target, "pi", allow_boundary = TRUE)
    labels <- c("treatment", "control")
    target_pi <- as.numeric(pi)
    shares <- c(treatment = target_pi, control = 1 - target_pi)
    realized <- .cmr_realize_vector_allocation(
      labels,
      shares,
      n_main = n_main,
      min_per_arm = min_per_arm
    )
    realized_pi <- unname(realized$shares[["treatment"]])
    design <- "two_arm"
    diagnostics <- list(design = design)
  } else {
    prepared <- .cmr_allocation_vector_target(target)
    labels <- prepared$labels
    target_pi <- prepared$shares

    if (!is.null(strata_counts)) {
      realized <- .cmr_realize_stratified_counts(
        target_pi,
        strata_counts = strata_counts,
        min_per_arm = min_per_arm
      )
      n_main <- sum(realized$counts)
      realized_pi <- realized$shares
      design <- "stratified"
      diagnostics <- list(design = design, strata_counts = strata_counts)
    } else {
      if (is.null(n_main)) {
        .cmr_stop("`n_main` is required unless `strata_counts` is supplied.")
      }
      realized <- .cmr_realize_vector_allocation(
        labels,
        target_pi,
        n_main = n_main,
        min_per_arm = min_per_arm
      )
      realized_pi <- realized$shares
      design <- if (.cmr_is_stratified_target(labels)) "stratified" else "multiarm"
      diagnostics <- list(design = design)
    }
  }

  certificate <- .cmr_allocation_certificate(
    fit,
    realized_pi = realized_pi,
    realized_shares = realized$shares,
    design = design,
    max_vertices = max_vertices
  )
  continuous_U_CMR <- if (!is.null(fit)) fit$U_CMR else NULL
  realized_U_CMR <- if (!is.null(certificate)) certificate$value else NULL
  if (!is.null(fit) && is.null(fit$rectangle) && is.infinite(fit$U_CMR)) {
    realized_U_CMR <- Inf
  }
  if (!is.null(certificate)) {
    diagnostics <- c(diagnostics, certificate[setdiff(names(certificate), "value")])
  }
  diagnostics$certificate_recomputed <- !is.null(realized_U_CMR)

  out <- list(
    counts = realized$counts,
    shares = realized$shares,
    pi = realized_pi,
    target_pi = target_pi,
    n_main = as.integer(n_main),
    rounding = "largest_remainder",
    min_per_arm = min_per_arm,
    continuous_U_CMR = continuous_U_CMR,
    realized_U_CMR = realized_U_CMR,
    excess_U_CMR = .cmr_allocation_excess(realized_U_CMR, continuous_U_CMR),
    diagnostics = diagnostics
  )
  class(out) <- c("cmr_allocation", "list")
  out
}

.cmr_print_allocation <- function(x, ...) {
  cat("<cmr_allocation>\n")
  cat("  counts: ", .cmr_format_vector(x$counts), "\n", sep = "")
  cat("  n_main: ", .cmr_format_scalar(x$n_main), "\n", sep = "")
  if (!is.null(x$realized_U_CMR)) {
    cat("  realized_U_CMR: ", .cmr_format_scalar(x$realized_U_CMR), "\n", sep = "")
  }
  invisible(x)
}

#' @rdname realize_allocation
#' @method print cmr_allocation
#' @export
print.cmr_allocation <- .cmr_print_allocation
