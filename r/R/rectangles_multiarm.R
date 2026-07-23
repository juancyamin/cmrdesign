# Confidence-set construction for multiple-treatment shared-control designs.

.cmr_resolve_extension_method <- function(y,
                                          method = c("auto", "bounded", "bernoulli",
                                                     "maurer_pontil", "mp", "bernoulli_exact",
                                                     "martinez_taboada_ramdas", "mtr")) {
  method <- match.arg(method)
  switch(
    method,
    auto = if (.cmr_is_dummy(y, na.rm = FALSE)) "bernoulli" else "bounded",
    bounded = "bounded",
    maurer_pontil = "bounded",
    mp = "bounded",
    bernoulli = "bernoulli",
    bernoulli_exact = "bernoulli",
    martinez_taboada_ramdas = "martinez_taboada_ramdas",
    mtr = "martinez_taboada_ramdas"
  )
}

.cmr_variance_bounds_by_method <- function(y,
                                           beta_l,
                                           beta_u,
                                           method,
                                           tol = 1e-11) {
  if (method == "bernoulli") {
    return(variance_bounds_bernoulli_exact(
      y,
      beta_l = beta_l,
      beta_u = beta_u,
      na.rm = FALSE,
      tol = tol
    ))
  }
  if (method == "martinez_taboada_ramdas") {
    return(variance_bounds_martinez_taboada_ramdas(
      y,
      beta_l = beta_l,
      beta_u = beta_u,
      na.rm = FALSE
    ))
  }
  variance_bounds_maurer_pontil(
    y,
    beta_l = beta_l,
    beta_u = beta_u,
    na.rm = FALSE
  )
}

.cmr_split_multiarm_pilot <- function(y,
                                      arm,
                                      control_arm = 0,
                                      na.rm = TRUE) {
  if (length(y) != length(arm)) {
    .cmr_stop("`y` and `arm` must have the same length.")
  }
  if (is.logical(y)) {
    y <- as.numeric(y)
  }
  if (!is.numeric(y) && !is.integer(y)) {
    .cmr_stop("`y` must be numeric or logical.")
  }
  y <- as.numeric(y)

  arm_chr <- as.character(arm)
  control_chr <- as.character(control_arm)
  if (length(control_chr) != 1L || is.na(control_chr)) {
    .cmr_stop("`control_arm` must be a non-missing scalar label.")
  }

  missing <- is.na(y) | is.na(arm_chr)
  if (any(missing)) {
    if (!na.rm) {
      .cmr_stop("`y` and `arm` cannot contain missing values when `na.rm = FALSE`.")
    }
    y <- y[!missing]
    arm_chr <- arm_chr[!missing]
  }
  if (length(y) == 0L) {
    .cmr_stop("The pilot has no observed rows.")
  }
  if (any(!is.finite(y))) {
    .cmr_stop("`y` must contain only finite values.")
  }
  if (!any(arm_chr == control_chr)) {
    .cmr_stop("`arm` must include the control arm.")
  }
  if (!any(arm_chr != control_chr)) {
    .cmr_stop("`arm` must include at least one treatment arm.")
  }
  if (control_chr != "0" && any(arm_chr != control_chr & arm_chr == "0")) {
    .cmr_stop("Treatment arm label `0` is reserved for the standardized control arm.")
  }

  arm_std <- ifelse(arm_chr == control_chr, "0", arm_chr)
  arms <- unique(arm_std)
  arms <- arms[.cmr_arm_order(arms)]
  list(y = y, arm = arm_std, arms = arms, control_arm = control_chr)
}

.cmr_resolve_multiarm_beta <- function(alpha, arms, beta = NULL) {
  alpha <- .cmr_check_alpha(alpha)
  n_arms <- length(arms)
  if (n_arms < 2L) {
    .cmr_stop("At least two arms are required.")
  }

  if (is.null(beta)) {
    beta_mat <- matrix(
      alpha / (2 * n_arms),
      nrow = n_arms,
      ncol = 2L,
      dimnames = list(arms, c("lower", "upper"))
    )
  } else if (length(beta) == 1L) {
    beta_one <- .cmr_check_tail_error(beta, "beta")
    beta_mat <- matrix(
      beta_one,
      nrow = n_arms,
      ncol = 2L,
      dimnames = list(arms, c("lower", "upper"))
    )
  } else {
    if (is.data.frame(beta)) {
      beta <- as.matrix(beta)
    }
    if (is.matrix(beta)) {
      beta_mat <- beta
      storage.mode(beta_mat) <- "double"
      if (nrow(beta_mat) != n_arms || ncol(beta_mat) != 2L) {
        .cmr_stop("Matrix `beta` must have one row per arm and columns `lower`, `upper`.")
      }
      if (is.null(rownames(beta_mat)) || !all(arms %in% rownames(beta_mat))) {
        .cmr_stop("Matrix `beta` row names must match arm labels.")
      }
      beta_mat <- beta_mat[arms, , drop = FALSE]
      colnames(beta_mat) <- tolower(colnames(beta_mat))
      if (!all(c("lower", "upper") %in% colnames(beta_mat))) {
        .cmr_stop("Matrix `beta` must have columns `lower` and `upper`.")
      }
      beta_mat <- beta_mat[, c("lower", "upper"), drop = FALSE]
    } else {
      beta <- .cmr_check_numeric(beta, "beta")
      expected <- as.vector(rbind(paste0("beta_l", arms), paste0("beta_u", arms)))
      if (is.null(names(beta)) || !all(expected %in% names(beta))) {
        .cmr_stop("Vector `beta` must have names `beta_l*` and `beta_u*` for every arm.")
      }
      beta_mat <- matrix(NA_real_, nrow = n_arms, ncol = 2L,
                         dimnames = list(arms, c("lower", "upper")))
      beta_mat[, "lower"] <- beta[paste0("beta_l", arms)]
      beta_mat[, "upper"] <- beta[paste0("beta_u", arms)]
    }
  }

  beta_mat[] <- .cmr_check_probability(as.numeric(beta_mat), "beta", allow_boundary = TRUE)
  if (any(beta_mat >= 1)) {
    .cmr_stop("Every beta endpoint error must be smaller than 1.")
  }
  if (sum(beta_mat) > alpha + 1e-12) {
    .cmr_stop("`beta` allocates joint error above `alpha`.")
  }
  beta_mat
}

.cmr_multiarm_rectangle_object <- function(rectangle,
                                           arm_results,
                                           alpha,
                                           beta,
                                           method,
                                           normalization = NULL,
                                           control_arm = 0) {
  rectangle <- .cmr_check_multiarm_rectangle(rectangle)
  n <- vapply(arm_results, `[[`, integer(1), "n")
  vhat <- vapply(arm_results, `[[`, numeric(1), "vhat")
  n <- n[rownames(rectangle)]
  vhat <- vhat[rownames(rectangle)]

  out <- list(
    rectangle = rectangle,
    arms = rownames(rectangle),
    arm_results = arm_results[rownames(rectangle)],
    alpha = alpha,
    beta = beta[rownames(rectangle), , drop = FALSE],
    joint_error_bound = sum(beta),
    method = method,
    n = n,
    vhat = vhat,
    normalization = normalization,
    control_arm = control_arm
  )
  class(out) <- c("cmr_multiarm_rectangle", "list")
  out
}

#' Multi-arm confidence rectangle
#'
#' Construct arm-specific variance confidence intervals for a shared-control
#' multi-arm design.
#'
#' @param y Pilot outcomes.
#' @param arm Pilot arm labels. The control arm is identified by `control_arm`
#'   and internally standardized to `"0"`.
#' @param alpha Target joint error level.
#' @param method Confidence-set method. `"auto"` chooses exact Bernoulli bounds
#'   for 0/1 outcomes and bounded Maurer-Pontil bounds otherwise.
#' @param beta Optional endpoint error allocation. If `NULL`, Bonferroni error
#'   is split across all lower and upper arm endpoints. A scalar, matrix, or
#'   named vector allocation may also be supplied.
#' @param control_arm Label identifying the control arm in `arm`.
#' @param normalize If `TRUE`, normalize bounded outcomes to `[0, 1]` before
#'   computing variances.
#' @param lower,upper Optional lower and upper outcome bounds used when
#'   `normalize = TRUE`.
#' @param na.rm If `TRUE`, drop rows with missing `y` or `arm`.
#' @param tol Numerical tolerance for exact Bernoulli bound inversion.
#'
#' @return
#' A list of class `cmr_multiarm_rectangle` with checked rectangle, arm labels,
#' one-arm bound results, endpoint error allocation, sample sizes, pilot
#' variance estimates, normalization details, and method metadata.
#'
#' @examples
#' set.seed(6)
#' arm <- rep(c(0, 1, 2), each = 12)
#' y <- c(rbeta(12, 4, 4), rbeta(12, 2, 6), rbeta(12, 5, 3))
#' rectangle_multiarm(y, arm, method = "bounded")
#'
#' @family rectangle helpers
#' @export
rectangle_multiarm <- function(y,
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
                               tol = 1e-11) {
  method <- match.arg(method)
  alpha <- .cmr_check_alpha(alpha)
  pilot <- .cmr_split_multiarm_pilot(y, arm, control_arm = control_arm, na.rm = na.rm)
  normalization <- NULL

  if (normalize) {
    normalized <- .cmr_normalize_01(
      pilot$y,
      lower = lower,
      upper = upper,
      na.rm = FALSE,
      return_params = TRUE
    )
    pilot$y <- normalized$values
    normalization <- list(lower = normalized$lower, upper = normalized$upper)
  }

  resolved_method <- .cmr_resolve_extension_method(pilot$y, method = method)
  beta_mat <- .cmr_resolve_multiarm_beta(alpha, pilot$arms, beta = beta)

  arm_results <- vector("list", length(pilot$arms))
  names(arm_results) <- pilot$arms
  rectangle <- matrix(
    NA_real_,
    nrow = length(pilot$arms),
    ncol = 2L,
    dimnames = list(pilot$arms, c("lower", "upper"))
  )

  for (a in pilot$arms) {
    y_arm <- pilot$y[pilot$arm == a]
    result <- .cmr_variance_bounds_by_method(
      y_arm,
      beta_l = beta_mat[a, "lower"],
      beta_u = beta_mat[a, "upper"],
      method = resolved_method,
      tol = tol
    )
    arm_results[[a]] <- result
    rectangle[a, "lower"] <- result$L
    rectangle[a, "upper"] <- result$U
  }

  .cmr_multiarm_rectangle_object(
    rectangle = rectangle,
    arm_results = arm_results,
    alpha = alpha,
    beta = beta_mat,
    method = resolved_method,
    normalization = normalization,
    control_arm = control_arm
  )
}
