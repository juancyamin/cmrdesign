# Effective two-arm rectangles for multiple-outcome designs.

.cmr_check_outcome_matrix <- function(y, name = "y") {
  if (is.data.frame(y)) {
    y <- as.matrix(y)
  }
  if (is.vector(y) && !is.list(y)) {
    y <- matrix(y, ncol = 1L)
  }
  if (!is.matrix(y)) {
    .cmr_stop("`", name, "` must be a numeric matrix, data frame, or vector.")
  }
  if (nrow(y) < 1L || ncol(y) < 1L) {
    .cmr_stop("`", name, "` must have at least one row and one outcome column.")
  }
  if (is.logical(y)) {
    y <- matrix(as.numeric(y), nrow = nrow(y), ncol = ncol(y),
                dimnames = dimnames(y))
  }
  storage.mode(y) <- "double"
  if (is.null(colnames(y)) || any(colnames(y) == "")) {
    colnames(y) <- paste0("outcome_", seq_len(ncol(y)))
  }
  y
}

.cmr_check_outcome_weights <- function(weights, n_outcomes) {
  n_outcomes <- .cmr_check_scalar_integer(n_outcomes, "n_outcomes", lower = 1L)
  if (is.null(weights)) {
    weights <- rep(1 / n_outcomes, n_outcomes)
  }
  weights <- .cmr_check_numeric(weights, "weights")
  if (length(weights) != n_outcomes) {
    .cmr_stop("`weights` must have one entry per outcome.")
  }
  if (any(weights < -1e-12)) {
    .cmr_stop("`weights` must be nonnegative.")
  }
  total <- sum(weights)
  if (total <= 0) {
    .cmr_stop("`weights` must contain positive mass.")
  }
  weights <- pmax(weights, 0) / total
  weights
}

.cmr_split_multiple_outcome_pilot <- function(y, d, na.rm = TRUE) {
  y <- .cmr_check_outcome_matrix(y)
  if (length(d) != nrow(y)) {
    .cmr_stop("`d` must have one entry per row of `y`.")
  }
  d <- .cmr_check_treatment_indicator(d)

  missing <- is.na(d) | apply(is.na(y), 1L, any)
  if (any(missing)) {
    if (!na.rm) {
      .cmr_stop("`y` and `d` cannot contain missing values when `na.rm = FALSE`.")
    }
    y <- y[!missing, , drop = FALSE]
    d <- d[!missing]
  }
  if (nrow(y) == 0L) {
    .cmr_stop("The pilot has no observed rows.")
  }
  if (any(!is.finite(y))) {
    .cmr_stop("`y` must contain only finite values.")
  }
  if (!any(d == 1L) || !any(d == 0L)) {
    .cmr_stop("The pilot must include both treatment (`d = 1`) and control (`d = 0`).")
  }

  list(y = y, d = d, y1 = y[d == 1L, , drop = FALSE],
       y0 = y[d == 0L, , drop = FALSE])
}

.cmr_resolve_multiple_beta <- function(alpha, n_outcomes, beta = NULL) {
  alpha <- .cmr_check_alpha(alpha)
  n_outcomes <- .cmr_check_scalar_integer(n_outcomes, "n_outcomes", lower = 1L)
  if (is.null(beta)) {
    return(alpha / (4 * n_outcomes))
  }
  beta <- .cmr_check_tail_error(beta, "beta")
  if (4 * n_outcomes * beta > alpha + 1e-12) {
    .cmr_stop("Scalar `beta` allocates joint error above `alpha`.")
  }
  beta
}

#' Multiple-outcome confidence rectangle
#'
#' Construct an effective two-arm variance rectangle for multiple outcomes.
#' For `estimand = "index"`, outcomes are first combined using `weights`. For
#' `estimand = "coprimary"`, one rectangle is built per outcome and combined
#' conservatively using the outcome weights.
#'
#' @param y Pilot outcomes as a numeric matrix, data frame, or vector. Rows are
#'   units and columns are outcomes.
#' @param d Pilot treatment indicator; treatment is `1` and control is `0`.
#' @param weights Optional nonnegative outcome weights. If `NULL`, equal
#'   weights are used.
#' @param estimand Either `"coprimary"` or `"index"`.
#' @param alpha Target joint error level.
#' @param method Confidence-set method. `"auto"` chooses exact Bernoulli bounds
#'   for 0/1 outcomes and bounded Maurer-Pontil bounds otherwise.
#' @param beta Optional scalar endpoint error allocation.
#' @param na.rm If `TRUE`, drop rows with missing `y` or `d`.
#' @param tol Numerical tolerance for exact Bernoulli bound inversion.
#'
#' @return
#' A list of class `cmr_multiple_outcomes_rectangle`. For `estimand = "index"`,
#' this wraps the ordinary two-arm rectangle for the weighted index. For
#' `estimand = "coprimary"`, it contains the effective two-arm `rectangle`,
#' weights, outcome-specific bounds, pilot summaries, endpoint error allocation,
#' and method metadata.
#'
#' @examples
#' set.seed(9)
#' d <- rep(c(1, 0), each = 20)
#' y <- cbind(
#'   y1 = c(rbeta(20, 2, 6), rbeta(20, 4, 4)),
#'   y2 = c(rbeta(20, 5, 3), rbeta(20, 3, 5))
#' )
#' rectangle_multiple_outcomes(y, d, weights = c(0.6, 0.4))
#'
#' @family rectangle helpers
#' @export
rectangle_multiple_outcomes <- function(y,
                                        d,
                                        weights = NULL,
                                        estimand = c("coprimary", "index"),
                                        alpha = 0.05,
                                        method = c("auto", "bounded", "bernoulli",
                                                   "maurer_pontil", "mp",
                                                   "bernoulli_exact",
                                                   "martinez_taboada_ramdas", "mtr"),
                                        beta = NULL,
                                        na.rm = TRUE,
                                        tol = 1e-11) {
  estimand <- match.arg(estimand)
  method <- match.arg(method)
  alpha <- .cmr_check_alpha(alpha)
  pilot <- .cmr_split_multiple_outcome_pilot(y, d, na.rm = na.rm)
  weights <- .cmr_check_outcome_weights(weights, ncol(pilot$y))
  names(weights) <- colnames(pilot$y)

  if (estimand == "index") {
    index_y <- as.numeric(pilot$y %*% weights)
    out <- rectangle_two_arm(
      y = index_y,
      d = pilot$d,
      alpha = alpha,
      method = method,
      beta = beta,
      correction = "bonferroni",
      na.rm = FALSE,
      tol = tol
    )
    out$estimand <- "index"
    out$weights <- weights
    out$index_outcome_name <- "weighted_index"
    class(out) <- c("cmr_multiple_outcomes_rectangle", class(out))
    return(out)
  }

  resolved_method <- .cmr_resolve_extension_method(as.numeric(pilot$y), method = method)
  beta_one <- .cmr_resolve_multiple_beta(alpha, ncol(pilot$y), beta = beta)

  outcome_bounds <- vector("list", ncol(pilot$y))
  names(outcome_bounds) <- colnames(pilot$y)
  lower1 <- upper1 <- lower0 <- upper0 <- numeric(ncol(pilot$y))
  vhat1 <- vhat0 <- numeric(ncol(pilot$y))

  for (j in seq_len(ncol(pilot$y))) {
    name <- colnames(pilot$y)[[j]]
    b1 <- .cmr_variance_bounds_by_method(
      pilot$y1[, j],
      beta_l = beta_one,
      beta_u = beta_one,
      method = resolved_method,
      tol = tol
    )
    b0 <- .cmr_variance_bounds_by_method(
      pilot$y0[, j],
      beta_l = beta_one,
      beta_u = beta_one,
      method = resolved_method,
      tol = tol
    )
    outcome_bounds[[name]] <- list(treatment = b1, control = b0)
    lower1[[j]] <- b1$L
    upper1[[j]] <- b1$U
    lower0[[j]] <- b0$L
    upper0[[j]] <- b0$U
    vhat1[[j]] <- b1$vhat
    vhat0[[j]] <- b0$vhat
  }

  rectangle <- c(
    v_l1 = sum(weights * lower1),
    v_u1 = sum(weights * upper1),
    v_l0 = sum(weights * lower0),
    v_u0 = sum(weights * upper0)
  )
  rectangle <- .cmr_clip(rectangle, 0, 0.25)

  out <- list(
    rectangle = rectangle,
    estimand = "coprimary",
    weights = weights,
    alpha = alpha,
    beta = beta_one,
    joint_error_bound = 4 * length(weights) * beta_one,
    method = resolved_method,
    n = c(n1 = nrow(pilot$y1), n0 = nrow(pilot$y0)),
    vhat = c(vhat1 = sum(weights * vhat1), vhat0 = sum(weights * vhat0)),
    outcome_bounds = outcome_bounds,
    outcome_vhat = list(treatment = vhat1, control = vhat0)
  )
  class(out) <- c("cmr_multiple_outcomes_rectangle", "list")
  out
}
