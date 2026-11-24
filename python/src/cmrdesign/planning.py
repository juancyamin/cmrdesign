"""Appendix E pilot-planning tools."""

from __future__ import annotations

import math

import numpy as np

from .validation import as_numeric_array, check_alpha, cmr_error, scalar_int


def _check_sd_pair(sigma1, sigma0, input: str = "sd") -> dict[str, np.ndarray]:
    input = str(input).lower()
    if input not in {"sd", "variance"}:
        cmr_error("`input` must be 'sd' or 'variance'.")
    sigma1 = as_numeric_array(sigma1, "sigma1")
    sigma0 = as_numeric_array(sigma0, "sigma0")
    sigma1, sigma0 = np.broadcast_arrays(sigma1, sigma0)
    if input == "variance":
        if np.any(sigma1 < -1e-12) or np.any(sigma0 < -1e-12):
            cmr_error("Variance inputs must be nonnegative.")
        sigma1 = np.sqrt(np.maximum(sigma1, 0))
        sigma0 = np.sqrt(np.maximum(sigma0, 0))
    if np.any(sigma1 < -1e-12) or np.any(sigma0 < -1e-12):
        cmr_error("Standard deviations must be nonnegative.")
    return {"sigma1": np.maximum(sigma1, 0), "sigma0": np.maximum(sigma0, 0)}


def _format_sd_pair(sigmas: dict[str, np.ndarray]) -> dict:
    out = {}
    for key, value in sigmas.items():
        value = np.asarray(value)
        out[key] = float(value.reshape(-1)[0]) if value.size == 1 else value
    return out


def max_sample_sd_bounded(m_arm: int) -> float:
    m_arm = scalar_int(m_arm, "m_arm", lower=2)
    return math.sqrt(math.floor(m_arm**2 / 4) / (m_arm * (m_arm - 1)))


def activation_threshold_bounded(
    alpha: float = 0.05,
    max_total_pilot: int = 10000,
    min_arm_size: int = 2,
):
    alpha = check_alpha(alpha)
    min_arm_size = scalar_int(min_arm_size, "min_arm_size", lower=2)
    max_total_pilot = scalar_int(
        max_total_pilot,
        "max_total_pilot",
        lower=2 * min_arm_size,
    )
    for m_arm in range(min_arm_size, math.floor(max_total_pilot / 2) + 1):
        eta = math.sqrt(2 * math.log(4 / alpha) / (m_arm - 1))
        if eta < max_sample_sd_bounded(m_arm):
            return 2 * m_arm
    return math.inf


def activation_threshold_bernoulli(alpha: float = 0.05) -> int:
    check_alpha(alpha)
    return 4


def break_even_pilot_share(sigma1, sigma0, input: str = "sd"):
    sigmas = _check_sd_pair(sigma1, sigma0, input=input)
    numerator = np.asarray((sigmas["sigma1"] - sigmas["sigma0"]) ** 2, dtype=float)
    denominator = np.asarray(2 * (sigmas["sigma1"] ** 2 + sigmas["sigma0"] ** 2), dtype=float)
    out = np.zeros_like(denominator)
    np.divide(numerator, denominator, out=out, where=denominator > 0)
    out = np.clip(out, 0, 0.5)
    return float(out.reshape(-1)[0]) if out.size == 1 else out


def _admissible_even_pilots(n: int) -> list[int]:
    n = scalar_int(n, "n", lower=6)
    max_even = n - 2
    if max_even % 2 == 1:
        max_even -= 1
    if max_even < 4:
        return []
    return list(range(4, max_even + 1, 2))


def pilot_viability_band(
    n: int,
    sigma1,
    sigma0,
    alpha: float = 0.05,
    method: str = "bounded",
    input: str = "sd",
    accounting: str = "design_only",
    strict_upper: bool = False,
) -> dict:
    method = str(method).lower()
    input = str(input).lower()
    accounting = str(accounting).lower()
    if method not in {"bounded", "bernoulli"}:
        cmr_error("`method` must be 'bounded' or 'bernoulli'.")
    if accounting not in {"design_only", "pooled"}:
        cmr_error("`accounting` must be 'design_only' or 'pooled'.")
    n = scalar_int(n, "n", lower=6)
    alpha = check_alpha(alpha)
    share_cap = break_even_pilot_share(sigma1, sigma0, input=input)
    if np.asarray(share_cap).size != 1:
        cmr_error("`pilot_viability_band()` currently expects scalar planning values.")
    share_cap = float(share_cap)
    activation = (
        activation_threshold_bounded(alpha=alpha, max_total_pilot=n - 2)
        if method == "bounded"
        else activation_threshold_bernoulli(alpha=alpha)
    )
    continuous_cap = n * share_cap if accounting == "design_only" else math.inf
    candidates = _admissible_even_pilots(n)
    candidates = [x for x in candidates if math.isfinite(activation) and x >= activation]
    if accounting == "design_only":
        if strict_upper:
            candidates = [x for x in candidates if x < continuous_cap - 1e-12]
        else:
            candidates = [x for x in candidates if x <= continuous_cap + 1e-12]
    return {
        "n": n,
        "sigma": _format_sd_pair(_check_sd_pair(sigma1, sigma0, input=input)),
        "alpha": alpha,
        "method": method,
        "accounting": accounting,
        "break_even_share": share_cap,
        "break_even_total": continuous_cap,
        "activation_threshold": activation,
        "strict_upper": bool(strict_upper),
        "feasible_pilot_sizes": candidates,
        "min_feasible": min(candidates) if candidates else None,
        "max_feasible": max(candidates) if candidates else None,
        "nonempty": bool(candidates),
    }


def _pilot_size_status(m: int, band: dict) -> str:
    """Classify one total pilot size against a viability band."""

    cap = band["break_even_total"]
    design_only = band["accounting"] == "design_only"
    if m == 0:
        return "no_pilot"
    if m % 2 == 1:
        return "not_admissible_odd"
    if m < 4 or m > band["n"] - 2:
        return "outside_budget"
    if not math.isfinite(band["activation_threshold"]) or m < band["activation_threshold"]:
        return "below_activation_threshold"
    if design_only and band["strict_upper"] and m >= cap - 1e-12:
        return "above_break_even_cap"
    if design_only and not band["strict_upper"] and m > cap + 1e-12:
        return "above_break_even_cap"
    return "inside_viability_band"


def pilot_plan(
    n: int,
    sigma1,
    sigma0,
    alpha: float = 0.05,
    method: str = "bounded",
    input: str = "sd",
    accounting: str = "design_only",
    desired_pilot=None,
    strict_upper: bool = False,
) -> dict:
    band = pilot_viability_band(
        n=n,
        sigma1=sigma1,
        sigma0=sigma0,
        alpha=alpha,
        method=method,
        input=input,
        accounting=accounting,
        strict_upper=strict_upper,
    )
    default_two_thirds_power = 2 * math.ceil(n ** (2 / 3) / 2)
    two_thirds_status = _pilot_size_status(default_two_thirds_power, band)
    desired_status = None
    if desired_pilot is not None:
        desired_pilot = scalar_int(desired_pilot, "desired_pilot", lower=0)
        desired_status = _pilot_size_status(desired_pilot, band)

    if not band["nonempty"]:
        recommendation = (
            "No positive pilot size is justified for assignment adaptation by this "
            "necessary screen."
        )
    else:
        recommendation = (
            f"Candidate pilot sizes lie between {band['min_feasible']} and "
            f"{band['max_feasible']} observations, inclusive, on the admissible even grid."
        )
    return {
        "band": band,
        "suggested_pilot": band["min_feasible"] if band["nonempty"] else 0,
        "default_two_thirds_power": default_two_thirds_power,
        "two_thirds_status": two_thirds_status,
        "desired_pilot": desired_pilot,
        "desired_status": desired_status,
        "recommendation": recommendation,
        "caveat": (
            "The viability band is necessary, not sufficient: a feasible pilot must "
            "still move the CMR assignment often enough to repay its sampling cost."
        ),
    }


cmr_plan = pilot_plan
