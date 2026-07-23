# Confidence-set construction for stratified designs.

.cmr_resolve_strata_share_from_pilot <- function(strata, strata_share) {
  strata_chr <- as.character(strata)
  observed <- unique(strata_chr)
  if (is.null(strata_share)) {
    .cmr_stop("`strata_share` must be supplied for stratified designs.")
  }
  if (is.null(names(strata_share)) || any(names(strata_share) == "")) {
    if (length(strata_share) != length(observed)) {
      .cmr_stop("Unnamed `strata_share` must have one entry per observed stratum.")
    }
    names(strata_share) <- observed
  }
  strata_share <- .cmr_check_strata_share(strata_share)
  missing_share <- setdiff(observed, names(strata_share))
  if (length(missing_share) > 0L) {
    .cmr_stop("`strata_share` is missing observed strata: ", paste(missing_share, collapse = ", "), ".")
  }
  missing_pilot <- setdiff(names(strata_share), observed)
  if (length(missing_pilot) > 0L) {
    .cmr_stop("The pilot has no observations for strata: ", paste(missing_pilot, collapse = ", "), ".")
  }
  strata_share
}

.cmr_split_stratified_pilot <- function(y,
                                        d,
                                        strata,
                                        strata_share,
                                        na.rm = TRUE) {
  if (length(y) != length(d) || length(y) != length(strata)) {
    .cmr_stop("`y`, `d`, and `strata` must have the same length.")
  }
  if (is.logical(y)) {
    y <- as.numeric(y)
  }
  if (!is.numeric(y) && !is.integer(y)) {
    .cmr_stop("`y` must be numeric or logical.")
  }
  y <- as.numeric(y)
  d <- .cmr_check_treatment_indicator(d)
  strata_chr <- as.character(strata)

  missing <- is.na(y) | is.na(d) | is.na(strata_chr)
  if (any(missing)) {
    if (!na.rm) {
      .cmr_stop("`y`, `d`, and `strata` cannot contain missing values when `na.rm = FALSE`.")
    }
    y <- y[!missing]
    d <- d[!missing]
    strata_chr <- strata_chr[!missing]
  }
  if (length(y) == 0L) {
    .cmr_stop("The pilot has no observed rows.")
  }
  if (any(!is.finite(y))) {
    .cmr_stop("`y` must contain only finite values.")
  }

  strata_share <- .cmr_resolve_strata_share_from_pilot(strata_chr, strata_share)
  list(y = y, d = d, strata = strata_chr, strata_share = strata_share)
}

.cmr_resolve_stratified_beta <- function(alpha, strata_share, beta = NULL) {
  alpha <- .cmr_check_alpha(alpha)
  strata_share <- .cmr_check_strata_share(strata_share)
  n_strata <- length(strata_share)

  make_array <- function(value) {
    lower <- matrix(
      value,
      nrow = 2L,
      ncol = n_strata,
      dimnames = list(c("1", "0"), names(strata_share))
    )
    upper <- lower
    list(lower = lower, upper = upper)
  }

  if (is.null(beta)) {
    beta_out <- make_array(alpha / (4 * n_strata))
  } else if (length(beta) == 1L) {
    beta_out <- make_array(.cmr_check_tail_error(beta, "beta"))
  } else {
    if (!is.list(beta) || is.null(beta$lower) || is.null(beta$upper)) {
      .cmr_stop("`beta` must be NULL, scalar, or a list with `lower` and `upper` matrices.")
    }
    beta_out <- list(
      lower = .cmr_standardize_stratified_matrix(
        beta$lower,
        strata_share,
        "beta$lower",
        check_variance = FALSE
      ),
      upper = .cmr_standardize_stratified_matrix(
        beta$upper,
        strata_share,
        "beta$upper",
        check_variance = FALSE
      )
    )
  }

  beta_out$lower[] <- .cmr_check_probability(as.numeric(beta_out$lower), "beta$lower", allow_boundary = TRUE)
  beta_out$upper[] <- .cmr_check_probability(as.numeric(beta_out$upper), "beta$upper", allow_boundary = TRUE)
  if (any(beta_out$lower >= 1) || any(beta_out$upper >= 1)) {
    .cmr_stop("Every beta endpoint error must be smaller than 1.")
  }
  if (sum(beta_out$lower) + sum(beta_out$upper) > alpha + 1e-12) {
    .cmr_stop("`beta` allocates joint error above `alpha`.")
  }
  beta_out
}

.cmr_stratified_rectangle_object <- function(rectangle,
                                             cell_results,
                                             alpha,
                                             beta,
                                             method,
                                             strata_share,
                                             normalization = NULL) {
  checked <- .cmr_check_stratified_rectangle(rectangle, strata_share)
  n <- matrix(NA_integer_, nrow = 2L, ncol = length(strata_share),
              dimnames = list(c("1", "0"), names(strata_share)))
  vhat <- matrix(NA_real_, nrow = 2L, ncol = length(strata_share),
                 dimnames = list(c("1", "0"), names(strata_share)))
  for (cell in names(cell_results)) {
    parts <- strsplit(cell, ":", fixed = TRUE)[[1L]]
    n[parts[[1L]], parts[[2L]]] <- cell_results[[cell]]$n
    vhat[parts[[1L]], parts[[2L]]] <- cell_results[[cell]]$vhat
  }

  out <- list(
    rectangle = list(lower = checked$lower_matrix, upper = checked$upper_matrix),
    checked_rectangle = checked,
    strata_share = checked$strata_share,
    cell_results = cell_results,
    alpha = alpha,
    beta = beta,
    joint_error_bound = sum(beta$lower) + sum(beta$upper),
    method = method,
    n = n,
    vhat = vhat,
    normalization = normalization
  )
  class(out) <- c("cmr_stratified_rectangle", "list")
  out
}

rectangle_stratified <- function(y,
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
                                 tol = 1e-11) {
  method <- match.arg(method)
  alpha <- .cmr_check_alpha(alpha)
  pilot <- .cmr_split_stratified_pilot(
    y = y,
    d = d,
    strata = strata,
    strata_share = strata_share,
    na.rm = na.rm
  )
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
  beta_out <- .cmr_resolve_stratified_beta(alpha, pilot$strata_share, beta = beta)

  lower_matrix <- matrix(
    NA_real_,
    nrow = 2L,
    ncol = length(pilot$strata_share),
    dimnames = list(c("1", "0"), names(pilot$strata_share))
  )
  upper_matrix <- lower_matrix
  cell_results <- vector("list", 2L * length(pilot$strata_share))
  names(cell_results) <- .cmr_stratified_cell_names(names(pilot$strata_share))

  for (x in names(pilot$strata_share)) {
    for (arm in c("1", "0")) {
      keep <- pilot$strata == x & pilot$d == as.integer(arm)
      result <- .cmr_variance_bounds_by_method(
        pilot$y[keep],
        beta_l = beta_out$lower[arm, x],
        beta_u = beta_out$upper[arm, x],
        method = resolved_method,
        tol = tol
      )
      cell_name <- paste0(arm, ":", x)
      cell_results[[cell_name]] <- result
      lower_matrix[arm, x] <- result$L
      upper_matrix[arm, x] <- result$U
    }
  }

  .cmr_stratified_rectangle_object(
    rectangle = list(lower = lower_matrix, upper = upper_matrix),
    cell_results = cell_results,
    alpha = alpha,
    beta = beta_out,
    method = resolved_method,
    strata_share = pilot$strata_share,
    normalization = normalization
  )
}
