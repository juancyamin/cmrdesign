# Internal helpers shared by the Phase 2 implementation.

.cmr_stop <- function(...) {
  stop(paste0(...), call. = FALSE)
}

`%||%` <- function(a, b) {
  if (is.null(a)) b else a
}

.cmr_clip <- function(x, lower, upper) {
  pmin(pmax(x, lower), upper)
}

.cmr_check_numeric <- function(x, name) {
  if (!is.numeric(x) && !is.integer(x)) {
    .cmr_stop("`", name, "` must be numeric.")
  }
  names_in <- names(x)
  x <- as.numeric(x)
  if (!is.null(names_in)) {
    names(x) <- names_in
  }
  if (anyNA(x)) {
    .cmr_stop("`", name, "` cannot contain missing values.")
  }
  if (any(!is.finite(x))) {
    .cmr_stop("`", name, "` must contain only finite values.")
  }
  x
}

.cmr_check_variance <- function(v, name) {
  v <- .cmr_check_numeric(v, name)
  if (any(v < -1e-12) || any(v > 0.25 + 1e-12)) {
    .cmr_stop("`", name, "` must lie in [0, 1/4].")
  }
  .cmr_clip(v, 0, 0.25)
}

.cmr_check_probability <- function(p, name, allow_boundary = TRUE) {
  p <- .cmr_check_numeric(p, name)
  if (allow_boundary) {
    bad <- p < -1e-12 | p > 1 + 1e-12
    msg <- "[0, 1]"
  } else {
    bad <- p <= 0 | p >= 1
    msg <- "(0, 1)"
  }
  if (any(bad)) {
    .cmr_stop("`", name, "` must lie in ", msg, ".")
  }
  if (allow_boundary) {
    p <- .cmr_clip(p, 0, 1)
  }
  p
}

.cmr_check_alpha <- function(alpha) {
  alpha <- .cmr_check_probability(alpha, "alpha", allow_boundary = FALSE)
  if (length(alpha) != 1L) {
    .cmr_stop("`alpha` must be a scalar.")
  }
  alpha
}

.cmr_check_tail_error <- function(beta, name) {
  beta <- .cmr_check_probability(beta, name, allow_boundary = TRUE)
  if (length(beta) != 1L) {
    .cmr_stop("`", name, "` must be a scalar.")
  }
  if (beta >= 1) {
    .cmr_stop("`", name, "` must be smaller than 1.")
  }
  beta
}

.cmr_joint_error_bound <- function(beta, correction = c("bonferroni", "sidak_arms")) {
  correction <- match.arg(correction)
  beta <- .cmr_check_beta_vector(beta, alpha = NULL, correction = correction)

  if (correction == "bonferroni") {
    return(sum(beta))
  }

  arm_1_error <- beta[["beta_l1"]] + beta[["beta_u1"]]
  arm_0_error <- beta[["beta_l0"]] + beta[["beta_u0"]]
  if (arm_1_error > 1 || arm_0_error > 1) {
    .cmr_stop("Sidak arm-level errors must be no larger than 1.")
  }
  1 - (1 - arm_1_error) * (1 - arm_0_error)
}

.cmr_equal_beta <- function(alpha, correction = c("bonferroni", "sidak_arms")) {
  alpha <- .cmr_check_alpha(alpha)
  correction <- match.arg(correction)

  beta_one_sided <- if (correction == "bonferroni") {
    alpha / 4
  } else {
    (1 - sqrt(1 - alpha)) / 2
  }

  c(
    beta_l1 = beta_one_sided,
    beta_u1 = beta_one_sided,
    beta_l0 = beta_one_sided,
    beta_u0 = beta_one_sided
  )
}

.cmr_check_beta_vector <- function(beta,
                                   alpha = NULL,
                                   correction = c("bonferroni", "sidak_arms"),
                                   tol = 1e-12) {
  correction <- match.arg(correction)
  required <- c("beta_l1", "beta_u1", "beta_l0", "beta_u0")
  beta <- .cmr_check_named_vector(beta, required, "beta")
  beta <- .cmr_check_probability(beta, "beta", allow_boundary = TRUE)
  if (any(beta >= 1)) {
    .cmr_stop("Each element of `beta` must be smaller than 1.")
  }

  if (!is.null(alpha)) {
    alpha <- .cmr_check_alpha(alpha)
    joint <- .cmr_joint_error_bound(beta, correction = correction)
    if (joint > alpha + tol) {
      .cmr_stop(
        "`beta` implies joint error ", signif(joint, 6),
        ", which exceeds `alpha`."
      )
    }
  }

  beta
}

.cmr_resolve_beta <- function(alpha = 0.05,
                              beta = NULL,
                              correction = c("bonferroni", "sidak_arms")) {
  correction <- match.arg(correction)
  alpha <- .cmr_check_alpha(alpha)
  if (is.null(beta)) {
    return(.cmr_equal_beta(alpha, correction = correction))
  }
  .cmr_check_beta_vector(beta, alpha = alpha, correction = correction)
}

.cmr_check_scalar_integer <- function(x, name, lower = 1L) {
  if (!is.numeric(x) && !is.integer(x)) {
    .cmr_stop("`", name, "` must be an integer.")
  }
  if (length(x) != 1L || is.na(x) || !is.finite(x)) {
    .cmr_stop("`", name, "` must be a finite scalar integer.")
  }
  if (abs(x - round(x)) > 1e-12 || x < lower) {
    .cmr_stop("`", name, "` must be an integer at least ", lower, ".")
  }
  as.integer(round(x))
}

.cmr_check_trim <- function(trim) {
  trim <- .cmr_check_numeric(trim, "trim")
  if (length(trim) != 1L) {
    .cmr_stop("`trim` must be a scalar.")
  }
  if (trim < 0 || trim >= 0.5) {
    .cmr_stop("`trim` must lie in [0, 0.5).")
  }
  trim
}

.cmr_normalize_01 <- function(x,
                              lower = NULL,
                              upper = NULL,
                              na.rm = TRUE,
                              constant = c("zero", "half", "na"),
                              return_params = FALSE) {
  constant <- match.arg(constant)
  if (is.logical(x)) {
    x <- as.numeric(x)
  }
  x <- .cmr_check_numeric(x, "y")
  observed <- if (na.rm) x[!is.na(x)] else x
  if (length(observed) == 0L) {
    .cmr_stop("`y` has no observed values.")
  }

  if (is.null(lower)) {
    lower <- min(observed)
  } else {
    lower <- .cmr_check_numeric(lower, "lower")
  }
  if (is.null(upper)) {
    upper <- max(observed)
  } else {
    upper <- .cmr_check_numeric(upper, "upper")
  }
  if (length(lower) != 1L || length(upper) != 1L) {
    .cmr_stop("`lower` and `upper` must be scalar.")
  }
  if (lower > upper) {
    .cmr_stop("`lower` cannot exceed `upper`.")
  }

  out <- x
  if (upper == lower) {
    out[] <- switch(constant, zero = 0, half = 0.5, na = NA_real_)
  } else {
    out <- (x - lower) / (upper - lower)
    out <- .cmr_clip(out, 0, 1)
  }

  if (return_params) {
    return(list(values = out, lower = lower, upper = upper))
  }
  out
}

.cmr_clean_outcome_01 <- function(y, na.rm = TRUE, name = "y") {
  if (is.logical(y)) {
    y <- as.numeric(y)
  }
  if (!is.numeric(y) && !is.integer(y)) {
    .cmr_stop("`", name, "` must be numeric or logical.")
  }
  y <- as.numeric(y)
  if (na.rm) {
    y <- y[!is.na(y)]
  } else if (anyNA(y)) {
    .cmr_stop("`", name, "` contains missing values.")
  }
  if (length(y) == 0L) {
    .cmr_stop("`", name, "` has no observed values.")
  }
  if (any(!is.finite(y))) {
    .cmr_stop("`", name, "` must contain only finite values.")
  }
  if (any(y < -1e-12) || any(y > 1 + 1e-12)) {
    .cmr_stop("`", name, "` must lie in [0, 1].")
  }
  .cmr_clip(y, 0, 1)
}

.cmr_is_dummy <- function(y, na.rm = TRUE, tol = 1e-12) {
  if (is.logical(y)) {
    y <- as.numeric(y)
  }
  if (!is.numeric(y) && !is.integer(y)) {
    return(FALSE)
  }
  y <- as.numeric(y)
  if (na.rm) {
    y <- y[!is.na(y)]
  }
  if (length(y) == 0L || any(!is.finite(y))) {
    return(FALSE)
  }
  all(abs(y) <= tol | abs(y - 1) <= tol)
}

.cmr_check_treatment_indicator <- function(d, name = "d") {
  if (is.logical(d)) {
    d <- as.numeric(d)
  }
  if (!is.numeric(d) && !is.integer(d)) {
    .cmr_stop("`", name, "` must be a 0/1 or logical treatment indicator.")
  }
  d <- as.numeric(d)
  if (any(!is.na(d) & !is.finite(d))) {
    .cmr_stop("`", name, "` must contain only finite values.")
  }
  bad <- !is.na(d) & !(abs(d) <= 1e-12 | abs(d - 1) <= 1e-12)
  if (any(bad)) {
    .cmr_stop("`", name, "` must contain only 0 and 1.")
  }
  as.integer(round(d))
}

.cmr_split_binary_pilot <- function(y, d, na.rm = TRUE) {
  if (length(y) != length(d)) {
    .cmr_stop("`y` and `d` must have the same length.")
  }
  d <- .cmr_check_treatment_indicator(d)
  if (is.logical(y)) {
    y <- as.numeric(y)
  }
  if (!is.numeric(y) && !is.integer(y)) {
    .cmr_stop("`y` must be numeric or logical.")
  }
  y <- as.numeric(y)

  missing <- is.na(y) | is.na(d)
  if (any(missing)) {
    if (!na.rm) {
      .cmr_stop("`y` and `d` cannot contain missing values when `na.rm = FALSE`.")
    }
    y <- y[!missing]
    d <- d[!missing]
  }

  if (length(y) == 0L) {
    .cmr_stop("The pilot has no observed rows.")
  }
  if (any(!is.finite(y))) {
    .cmr_stop("`y` must contain only finite values.")
  }
  if (!any(d == 1L) || !any(d == 0L)) {
    .cmr_stop("The pilot must include both treatment (`d = 1`) and control (`d = 0`).")
  }

  list(y1 = y[d == 1L], y0 = y[d == 0L], y = y, d = d)
}

.cmr_recycle_common <- function(..., arg_names = NULL) {
  args <- list(...)
  if (length(args) == 0L) {
    return(args)
  }
  if (is.null(arg_names)) {
    arg_names <- names(args)
  }
  if (is.null(arg_names) || any(arg_names == "")) {
    arg_names <- paste0("arg", seq_along(args))
  }
  names(args) <- arg_names

  lengths <- vapply(args, length, integer(1))
  target <- max(lengths)
  incompatible <- lengths != 1L & lengths != target
  if (any(incompatible)) {
    .cmr_stop(
      "Input lengths are incompatible: ",
      paste(paste0(names(args), "=", lengths), collapse = ", "),
      ". Only length-one inputs can be recycled."
    )
  }
  lapply(args, function(x) if (length(x) == target) x else rep(x, target))
}

.cmr_check_named_vector <- function(x, required, name) {
  if (is.list(x) && !is.data.frame(x)) {
    x <- unlist(x, use.names = TRUE)
  }
  if (!is.numeric(x) && !is.integer(x)) {
    .cmr_stop("`", name, "` must be a named numeric vector or list.")
  }
  names_in <- names(x)
  x <- as.numeric(x)
  if (is.null(names_in) || any(names_in == "")) {
    .cmr_stop("`", name, "` must have names: ", paste(required, collapse = ", "), ".")
  }
  names(x) <- names_in
  missing <- setdiff(required, names_in)
  if (length(missing) > 0L) {
    .cmr_stop("`", name, "` is missing: ", paste(missing, collapse = ", "), ".")
  }
  x <- x[required]
  names(x) <- required
  x
}

.cmr_check_nonnegative <- function(x, name, allow_infinite = FALSE) {
  if (!is.numeric(x) && !is.integer(x)) {
    .cmr_stop("`", name, "` must be numeric.")
  }
  x <- as.numeric(x)
  if (anyNA(x)) {
    .cmr_stop("`", name, "` cannot contain missing values.")
  }
  finite_ok <- if (allow_infinite) is.finite(x) | is.infinite(x) else is.finite(x)
  if (any(!finite_ok)) {
    .cmr_stop("`", name, "` has invalid values.")
  }
  if (any(x < -1e-12)) {
    .cmr_stop("`", name, "` must be nonnegative.")
  }
  pmax(x, 0)
}

.cmr_check_truth_binary <- function(truth) {
  required <- c("v1", "v0")
  truth <- .cmr_check_named_vector(truth, required, "truth")
  truth <- .cmr_check_variance(truth, "truth")
  names(truth) <- required
  truth
}

.cmr_check_binary_rectangle <- function(rectangle) {
  if (is.list(rectangle) && !is.null(rectangle$rectangle)) {
    rectangle <- rectangle$rectangle
  }
  required <- c("v_l1", "v_u1", "v_l0", "v_u0")
  rectangle <- .cmr_check_named_vector(rectangle, required, "rectangle")
  rectangle <- .cmr_check_variance(rectangle, "rectangle")
  if (rectangle[["v_l1"]] > rectangle[["v_u1"]] + 1e-12) {
    .cmr_stop("Treatment lower endpoint cannot exceed treatment upper endpoint.")
  }
  if (rectangle[["v_l0"]] > rectangle[["v_u0"]] + 1e-12) {
    .cmr_stop("Control lower endpoint cannot exceed control upper endpoint.")
  }
  rectangle
}
