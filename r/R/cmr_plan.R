# Pilot-planning tools from Section 5.

.cmr_check_sd_pair <- function(sigma1,
                               sigma0,
                               input = c("sd", "variance")) {
  input <- match.arg(input)
  sigma1 <- .cmr_check_numeric(sigma1, "sigma1")
  sigma0 <- .cmr_check_numeric(sigma0, "sigma0")
  args <- .cmr_recycle_common(sigma1, sigma0, arg_names = c("sigma1", "sigma0"))
  sigma1 <- args$sigma1
  sigma0 <- args$sigma0

  if (input == "variance") {
    if (any(sigma1 < -1e-12) || any(sigma0 < -1e-12)) {
      .cmr_stop("Variance inputs must be nonnegative.")
    }
    sigma1 <- sqrt(pmax(sigma1, 0))
    sigma0 <- sqrt(pmax(sigma0, 0))
  }

  if (any(sigma1 < -1e-12) || any(sigma0 < -1e-12)) {
    .cmr_stop("Standard deviations must be nonnegative.")
  }
  list(sigma1 = pmax(sigma1, 0), sigma0 = pmax(sigma0, 0))
}

.cmr_max_sample_sd_bounded <- function(m_arm) {
  m_arm <- .cmr_check_scalar_integer(m_arm, "m_arm", lower = 2L)
  sqrt(floor(m_arm^2 / 4) / (m_arm * (m_arm - 1)))
}

#' Pilot-size activation thresholds
#'
#' Compute simple method-specific pilot-size activation thresholds for the
#' Pilot-planning screen from Appendix E of the accompanying paper.
#'
#' @param alpha Target error level.
#' @param max_total_pilot Largest total pilot size to search.
#' @param min_arm_size Minimum pilot observations per arm; must be at least 2.
#'
#' @return
#' Total pilot size threshold. `activation_threshold_bounded()` returns `Inf`
#' if no even pilot size up to `max_total_pilot` clears the bounded-outcome
#' activation condition. `activation_threshold_bernoulli()` returns `4`; the
#' exact Bernoulli screen activates at the minimal admissible pilot regardless
#' of `alpha`, which is validated for interface consistency.
#'
#' @examples
#' activation_threshold_bounded(alpha = 0.05, max_total_pilot = 200)
#' activation_threshold_bernoulli(alpha = 0.05)
#'
#' @family pilot planning
#' @export
activation_threshold_bounded <- function(alpha = 0.05,
                                         max_total_pilot = 10000L,
                                         min_arm_size = 2L) {
  alpha <- .cmr_check_alpha(alpha)
  min_arm_size <- .cmr_check_scalar_integer(min_arm_size, "min_arm_size", lower = 2L)
  max_total_pilot <- .cmr_check_scalar_integer(
    max_total_pilot,
    "max_total_pilot",
    lower = 2L * min_arm_size
  )

  m_arm <- min_arm_size:floor(max_total_pilot / 2)
  eta <- sqrt(2 * log(4 / alpha) / (m_arm - 1))
  sd_max <- vapply(m_arm, .cmr_max_sample_sd_bounded, numeric(1))
  first <- which(eta < sd_max)[1L]
  if (is.na(first)) {
    return(Inf)
  }
  2L * m_arm[first]
}

#' @rdname activation_threshold_bounded
#' @export
activation_threshold_bernoulli <- function(alpha = 0.05) {
  .cmr_check_alpha(alpha)
  4L
}

#' Break-even pilot share
#'
#' Compute the design-only break-even pilot share implied by treatment and
#' control standard deviations.
#'
#' @param sigma1 Treatment-arm standard deviation, or variance when
#'   `input = "variance"`.
#' @param sigma0 Control-arm standard deviation, or variance when
#'   `input = "variance"`.
#' @param input Whether `sigma1` and `sigma0` are standard deviations (`"sd"`)
#'   or variances (`"variance"`).
#'
#' @return Numeric break-even share in `[0, 0.5]`.
#'
#' @examples
#' break_even_pilot_share(sigma1 = 0.35, sigma0 = 0.20)
#' break_even_pilot_share(sigma1 = 0.35^2, sigma0 = 0.20^2, input = "variance")
#'
#' @family pilot planning
#' @export
break_even_pilot_share <- function(sigma1,
                                   sigma0,
                                   input = c("sd", "variance")) {
  input <- match.arg(input)
  sigmas <- .cmr_check_sd_pair(sigma1, sigma0, input = input)
  numerator <- (sigmas$sigma1 - sigmas$sigma0)^2
  denominator <- 2 * (sigmas$sigma1^2 + sigmas$sigma0^2)
  out <- ifelse(denominator > 0, numerator / denominator, 0)
  .cmr_clip(out, 0, 0.5)
}

.cmr_admissible_even_pilots <- function(n) {
  n <- .cmr_check_scalar_integer(n, "n", lower = 6L)
  max_even <- n - 2L
  if (max_even %% 2L == 1L) {
    max_even <- max_even - 1L
  }
  if (max_even < 4L) {
    return(integer(0))
  }
  seq.int(4L, max_even, by = 2L)
}

#' Pilot viability band
#'
#' Compute a necessary viability screen for pilot sizes before choosing a
#' pilot/main-wave split.
#'
#' @param n Total experimental sample size across pilot and main wave.
#' @param sigma1 Treatment-arm standard deviation, or variance when
#'   `input = "variance"`.
#' @param sigma0 Control-arm standard deviation, or variance when
#'   `input = "variance"`.
#' @param alpha Target error level.
#' @param method Planning method, either `"bounded"` or `"bernoulli"`.
#' @param input Whether `sigma1` and `sigma0` are standard deviations (`"sd"`)
#'   or variances (`"variance"`).
#' @param accounting `"design_only"` applies the break-even pilot-share cap;
#'   `"pooled"` ignores that cap.
#' @param strict_upper If `TRUE`, feasible pilot sizes must be strictly below
#'   the design-only break-even cap.
#'
#' @return
#' A list of class `cmr_pilot_viability_band` with total sample size, standard
#' deviations, method, break-even share and total, activation threshold,
#' feasible even pilot sizes, and min/max feasible pilot sizes.
#'
#' @examples
#' pilot_viability_band(n = 3000, sigma1 = 0.18, sigma0 = 0.28)
#'
#' @family pilot planning
#' @export
pilot_viability_band <- function(n,
                                 sigma1,
                                 sigma0,
                                 alpha = 0.05,
                                 method = c("bounded", "bernoulli"),
                                 input = c("sd", "variance"),
                                 accounting = c("design_only", "pooled"),
                                 strict_upper = TRUE) {
  method <- match.arg(method)
  input <- match.arg(input)
  accounting <- match.arg(accounting)
  n <- .cmr_check_scalar_integer(n, "n", lower = 6L)
  alpha <- .cmr_check_alpha(alpha)
  share_cap <- break_even_pilot_share(sigma1, sigma0, input = input)
  if (length(share_cap) != 1L) {
    .cmr_stop("`pilot_viability_band()` currently expects scalar planning values.")
  }

  activation <- switch(
    method,
    bounded = activation_threshold_bounded(alpha = alpha, max_total_pilot = n - 2L),
    bernoulli = activation_threshold_bernoulli(alpha = alpha)
  )
  continuous_cap <- if (accounting == "design_only") n * share_cap else Inf
  candidates <- .cmr_admissible_even_pilots(n)
  if (is.finite(activation)) {
    candidates <- candidates[candidates >= activation]
  } else {
    candidates <- integer(0)
  }
  if (accounting == "design_only") {
    if (strict_upper) {
      candidates <- candidates[candidates < continuous_cap - 1e-12]
    } else {
      candidates <- candidates[candidates <= continuous_cap + 1e-12]
    }
  }

  out <- list(
    n = n,
    sigma = .cmr_check_sd_pair(sigma1, sigma0, input = input),
    alpha = alpha,
    method = method,
    accounting = accounting,
    break_even_share = share_cap,
    break_even_total = continuous_cap,
    activation_threshold = activation,
    strict_upper = strict_upper,
    feasible_pilot_sizes = as.integer(candidates),
    min_feasible = if (length(candidates) > 0L) min(candidates) else NA_integer_,
    max_feasible = if (length(candidates) > 0L) max(candidates) else NA_integer_,
    nonempty = length(candidates) > 0L
  )
  class(out) <- c("cmr_pilot_viability_band", "list")
  out
}

#' Pilot/main-wave planning summary
#'
#' Summarize the pilot-size viability band and a default pilot-size suggestion.
#'
#' @inheritParams pilot_viability_band
#' @param desired_pilot Optional user-proposed pilot size to classify.
#'
#' @return
#' A list of class `cmr_pilot_plan` with `band`, `suggested_pilot`,
#' `default_two_thirds_power`, `desired_pilot`, `desired_status`, a text
#' recommendation, and a caveat that the screen is necessary rather than
#' sufficient.
#'
#' @examples
#' cmr_plan(
#'   n = 3000,
#'   sigma1 = 0.18,
#'   sigma0 = 0.28,
#'   desired_pilot = 120
#' )
#'
#' @family pilot planning
#' @export
pilot_plan <- function(n,
                       sigma1,
                       sigma0,
                       alpha = 0.05,
                       method = c("bounded", "bernoulli"),
                       input = c("sd", "variance"),
                       accounting = c("design_only", "pooled"),
                       desired_pilot = NULL,
                       strict_upper = TRUE) {
  method <- match.arg(method)
  input <- match.arg(input)
  accounting <- match.arg(accounting)
  band <- pilot_viability_band(
    n = n,
    sigma1 = sigma1,
    sigma0 = sigma0,
    alpha = alpha,
    method = method,
    input = input,
    accounting = accounting,
    strict_upper = strict_upper
  )
  default_two_thirds_power <- 2L * ceiling(n^(2 / 3) / 2)

  desired_status <- NULL
  if (!is.null(desired_pilot)) {
    desired_pilot <- .cmr_check_scalar_integer(desired_pilot, "desired_pilot", lower = 0L)
    desired_status <- if (desired_pilot == 0L) {
      "no_pilot"
    } else if (desired_pilot %% 2L == 1L) {
      "not_admissible_odd"
    } else if (desired_pilot < 4L || desired_pilot > band$n - 2L) {
      "outside_budget"
    } else if (is.finite(band$activation_threshold) &&
               desired_pilot < band$activation_threshold) {
      "below_activation_threshold"
    } else if (accounting == "design_only" &&
               strict_upper && desired_pilot >= band$break_even_total - 1e-12) {
      "above_break_even_cap"
    } else if (accounting == "design_only" &&
               !strict_upper && desired_pilot > band$break_even_total + 1e-12) {
      "above_break_even_cap"
    } else {
      "inside_viability_band"
    }
  }

  recommendation <- if (!band$nonempty) {
    "No positive pilot size is justified for assignment adaptation by this necessary screen."
  } else {
    paste0(
      "Candidate pilot sizes lie between ",
      band$min_feasible,
      " and ",
      band$max_feasible,
      " observations, inclusive, on the admissible even grid."
    )
  }

  out <- list(
    band = band,
    suggested_pilot = if (band$nonempty) band$min_feasible else 0L,
    default_two_thirds_power = default_two_thirds_power,
    desired_pilot = desired_pilot,
    desired_status = desired_status,
    recommendation = recommendation,
    caveat = paste(
      "The viability band is necessary, not sufficient:",
      "a feasible pilot must still move the CMR assignment often enough to repay its sampling cost."
    )
  )
  class(out) <- c("cmr_pilot_plan", "list")
  out
}

#' @rdname pilot_plan
#' @export
cmr_plan <- pilot_plan
