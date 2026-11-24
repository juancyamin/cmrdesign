# Compact print and summary methods for applied users.

.cmr_format_scalar <- function(x, digits = 6) {
  if (length(x) != 1L || is.null(x)) {
    return("NULL")
  }
  if (is.numeric(x)) {
    if (is.infinite(x)) {
      return(as.character(x))
    }
    return(format(signif(x, digits), scientific = FALSE, trim = TRUE))
  }
  as.character(x)
}

.cmr_format_vector <- function(x, digits = 6, max_items = 6L) {
  if (is.null(x)) {
    return("NULL")
  }
  if (length(x) == 1L) {
    return(.cmr_format_scalar(x, digits = digits))
  }
  shown <- x[seq_len(min(length(x), max_items))]
  values <- vapply(shown, .cmr_format_scalar, character(1), digits = digits)
  if (!is.null(names(shown)) && all(names(shown) != "")) {
    values <- paste0(names(shown), "=", values)
  }
  out <- paste(values, collapse = ", ")
  if (length(x) > max_items) {
    out <- paste0(out, ", ...")
  }
  out
}

.cmr_total_n <- function(x) {
  n <- x$pilot$n %||% x$confidence_set$n %||% NULL
  if (is.null(n)) {
    return(NULL)
  }
  n <- suppressWarnings(as.numeric(unlist(n, use.names = FALSE)))
  n <- n[is.finite(n)]
  if (length(n) == 0L) {
    return(NULL)
  }
  sum(n)
}

.cmr_result_type <- function(x) {
  cls <- class(x)
  if ("cmr_unbounded" %in% cls) {
    return("cmr_unbounded")
  }
  if ("cmr_proxy" %in% cls) {
    return("cmr_proxy")
  }
  if ("cmr_multiple_outcomes" %in% cls) {
    return("cmr_multiple_outcomes")
  }
  if ("cmr_multiarm" %in% cls) {
    return("cmr_multiarm")
  }
  if ("cmr_stratified" %in% cls) {
    return("cmr_stratified")
  }
  if ("cmr_two_arm" %in% cls) {
    return("cmr_two_arm")
  }
  "cmr_result"
}

.cmr_summary_result <- function(object) {
  out <- list(
    type = .cmr_result_type(object),
    pi = object$pi,
    U_CMR = object$U_CMR,
    method = object$method %||% object$pilot$method %||% NULL,
    n = .cmr_total_n(object),
    alpha = object$alpha %||% NULL,
    joint_error_bound = object$joint_error_bound %||% NULL,
    status = object$diagnostics$status %||% object$pilot$status %||% NULL
  )
  class(out) <- c("summary.cmr_result", "list")
  out
}

.cmr_print_result <- function(x, ...) {
  summary <- .cmr_summary_result(x)
  cat("<", summary$type, ">\n", sep = "")
  cat("  pi: ", .cmr_format_vector(summary$pi), "\n", sep = "")
  cat("  U_CMR: ", .cmr_format_scalar(summary$U_CMR), "\n", sep = "")
  if (!is.null(summary$method)) {
    cat("  method: ", summary$method, "\n", sep = "")
  }
  if (!is.null(summary$n)) {
    cat("  n: ", .cmr_format_scalar(summary$n), "\n", sep = "")
  }
  if (!is.null(summary$status)) {
    cat("  status: ", summary$status, "\n", sep = "")
  }
  invisible(x)
}

#' Print and summarize CMR results
#'
#' Compact display methods for CMR result objects. These methods show the
#' allocation, CMR certificate, method, sample size, and status without dumping
#' nested confidence-set internals.
#'
#' @param x,object A CMR result object or summary object.
#' @param ... Reserved for future extensions.
#'
#' @return
#' `print()` methods return the original object invisibly. `summary()` methods
#' return a compact list of class `summary.cmr_result`.
#'
#' @examples
#' set.seed(13)
#' d <- rep(c(1, 0), each = 200)
#' y <- c(rbeta(200, 0.5, 0.5), rbeta(200, 8, 8))
#' fit <- cmr_two_arm(y, d)
#' print(fit)
#' summary(fit)
#'
#' @family CMR rules
#' @method print cmr_two_arm
#' @export
print.cmr_two_arm <- .cmr_print_result

#' @rdname print.cmr_two_arm
#' @method print cmr_unbounded
#' @export
print.cmr_unbounded <- .cmr_print_result

#' @rdname print.cmr_two_arm
#' @method print cmr_proxy
#' @export
print.cmr_proxy <- .cmr_print_result

#' @rdname print.cmr_two_arm
#' @method print cmr_multiple_outcomes
#' @export
print.cmr_multiple_outcomes <- .cmr_print_result

#' @rdname print.cmr_two_arm
#' @method print cmr_multiarm
#' @export
print.cmr_multiarm <- .cmr_print_result

#' @rdname print.cmr_two_arm
#' @method print cmr_stratified
#' @export
print.cmr_stratified <- .cmr_print_result

#' @rdname print.cmr_two_arm
#' @method summary cmr_two_arm
#' @export
summary.cmr_two_arm <- function(object, ...) .cmr_summary_result(object)

#' @rdname print.cmr_two_arm
#' @method summary cmr_unbounded
#' @export
summary.cmr_unbounded <- function(object, ...) .cmr_summary_result(object)

#' @rdname print.cmr_two_arm
#' @method summary cmr_proxy
#' @export
summary.cmr_proxy <- function(object, ...) .cmr_summary_result(object)

#' @rdname print.cmr_two_arm
#' @method summary cmr_multiple_outcomes
#' @export
summary.cmr_multiple_outcomes <- function(object, ...) .cmr_summary_result(object)

#' @rdname print.cmr_two_arm
#' @method summary cmr_multiarm
#' @export
summary.cmr_multiarm <- function(object, ...) .cmr_summary_result(object)

#' @rdname print.cmr_two_arm
#' @method summary cmr_stratified
#' @export
summary.cmr_stratified <- function(object, ...) .cmr_summary_result(object)

#' @rdname print.cmr_two_arm
#' @method print summary.cmr_result
#' @export
print.summary.cmr_result <- function(x, ...) {
  cat("<summary.", x$type, ">\n", sep = "")
  cat("  pi: ", .cmr_format_vector(x$pi), "\n", sep = "")
  cat("  U_CMR: ", .cmr_format_scalar(x$U_CMR), "\n", sep = "")
  if (!is.null(x$method)) {
    cat("  method: ", x$method, "\n", sep = "")
  }
  if (!is.null(x$n)) {
    cat("  n: ", .cmr_format_scalar(x$n), "\n", sep = "")
  }
  if (!is.null(x$status)) {
    cat("  status: ", x$status, "\n", sep = "")
  }
  invisible(x)
}

.cmr_print_pilot_band <- function(x, ...) {
  cat("<cmr_pilot_viability_band>\n")
  cat("  n: ", .cmr_format_scalar(x$n), "\n", sep = "")
  cat("  method: ", x$method, ", accounting: ", x$accounting, "\n", sep = "")
  cat("  activation_threshold: ", .cmr_format_scalar(x$activation_threshold), "\n", sep = "")
  if (identical(x$accounting, "design_only")) {
    cat(
      "  break_even_total: ", .cmr_format_scalar(x$break_even_total),
      " (share ", .cmr_format_scalar(x$break_even_share), ")\n",
      sep = ""
    )
  }
  if (isTRUE(x$nonempty)) {
    cat(
      "  feasible pilot sizes: ", x$min_feasible, " to ", x$max_feasible,
      " (", length(x$feasible_pilot_sizes), " even sizes)\n",
      sep = ""
    )
  } else {
    cat("  feasible pilot sizes: none\n")
  }
  invisible(x)
}

.cmr_print_pilot_plan <- function(x, ...) {
  band <- x$band
  cat("<cmr_pilot_plan>\n")
  cat("  n: ", .cmr_format_scalar(band$n), "\n", sep = "")
  cat("  method: ", band$method, ", accounting: ", band$accounting, "\n", sep = "")
  if (isTRUE(band$nonempty)) {
    cat(
      "  viability band: ", band$min_feasible, " to ", band$max_feasible,
      " (even sizes)\n",
      sep = ""
    )
  } else {
    cat("  viability band: empty\n")
  }
  cat("  suggested_pilot: ", .cmr_format_scalar(x$suggested_pilot), "\n", sep = "")
  cat(
    "  default_two_thirds_power: ", .cmr_format_scalar(x$default_two_thirds_power),
    " (", x$two_thirds_status, ")\n",
    sep = ""
  )
  if (!is.null(x$desired_pilot)) {
    cat(
      "  desired_pilot: ", .cmr_format_scalar(x$desired_pilot),
      " (", x$desired_status, ")\n",
      sep = ""
    )
  }
  invisible(x)
}

.cmr_print_rectangle <- function(x, ...) {
  cat("<", class(x)[[1L]], ">\n", sep = "")
  rectangle <- x$rectangle
  if (is.null(rectangle)) {
    cat("  rectangle: none\n")
  } else if (is.matrix(rectangle)) {
    lower <- rectangle[, "lower"]
    upper <- rectangle[, "upper"]
    names(lower) <- names(upper) <- rownames(rectangle)
    cat("  lower: ", .cmr_format_vector(lower, digits = 4, max_items = 8L), "\n", sep = "")
    cat("  upper: ", .cmr_format_vector(upper, digits = 4, max_items = 8L), "\n", sep = "")
  } else if (is.list(rectangle)) {
    lower <- .cmr_stratified_matrix_to_vector(rectangle$lower)
    upper <- .cmr_stratified_matrix_to_vector(rectangle$upper)
    cat("  lower: ", .cmr_format_vector(lower, digits = 4, max_items = 8L), "\n", sep = "")
    cat("  upper: ", .cmr_format_vector(upper, digits = 4, max_items = 8L), "\n", sep = "")
  } else {
    cat("  rectangle: ", .cmr_format_vector(rectangle, digits = 4), "\n", sep = "")
  }
  cat("  method: ", x$method, "\n", sep = "")
  n <- suppressWarnings(as.numeric(unlist(x$n, use.names = FALSE)))
  n <- n[is.finite(n)]
  if (length(n) > 0L) {
    cat("  n: ", .cmr_format_scalar(sum(n)), "\n", sep = "")
  }
  if (!is.null(x$joint_error_bound)) {
    cat("  joint_error_bound: ", .cmr_format_scalar(x$joint_error_bound), "\n", sep = "")
  }
  if (!is.null(x$status) && !identical(x$status, "active")) {
    cat("  status: ", x$status, "\n", sep = "")
  }
  invisible(x)
}

#' Print pilot plans and confidence rectangles
#'
#' Compact display methods for pilot-planning objects and for the confidence
#' rectangles returned by the `rectangle_*()` constructors. They show the
#' headline entries. The full object remains an ordinary list.
#'
#' @param x A `cmr_pilot_plan`, `cmr_pilot_viability_band`, or confidence
#'   rectangle object.
#' @param ... Reserved for future extensions.
#'
#' @return The original object, invisibly.
#'
#' @examples
#' cmr_plan(n = 3000, sigma1 = 0.18, sigma0 = 0.28, desired_pilot = 120)
#'
#' d <- rep(c(1, 0), each = 6)
#' y <- c(1, 0, 1, 1, 0, 1, 0, 0, 1, 0, 0, 1)
#' rectangle_two_arm(y, d)
#'
#' @family pilot planning
#' @family rectangle helpers
#' @method print cmr_pilot_plan
#' @export
print.cmr_pilot_plan <- .cmr_print_pilot_plan

#' @rdname print.cmr_pilot_plan
#' @method print cmr_pilot_viability_band
#' @export
print.cmr_pilot_viability_band <- .cmr_print_pilot_band

#' @rdname print.cmr_pilot_plan
#' @method print cmr_binary_rectangle
#' @export
print.cmr_binary_rectangle <- .cmr_print_rectangle

#' @rdname print.cmr_pilot_plan
#' @method print cmr_unbounded_rectangle
#' @export
print.cmr_unbounded_rectangle <- .cmr_print_rectangle

#' @rdname print.cmr_pilot_plan
#' @method print cmr_multiarm_rectangle
#' @export
print.cmr_multiarm_rectangle <- .cmr_print_rectangle

#' @rdname print.cmr_pilot_plan
#' @method print cmr_stratified_rectangle
#' @export
print.cmr_stratified_rectangle <- .cmr_print_rectangle

#' @rdname print.cmr_pilot_plan
#' @method print cmr_multiple_outcomes_rectangle
#' @export
print.cmr_multiple_outcomes_rectangle <- .cmr_print_rectangle
