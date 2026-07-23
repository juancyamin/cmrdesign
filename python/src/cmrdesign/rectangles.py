"""Confidence rectangle constructors."""

from __future__ import annotations

import math
from collections.abc import Mapping

import numpy as np

from .results import RectangleResult
from .unbounded import (
    check_unbounded_method_options,
    is_unbounded_method,
    rectangle_unbounded,
)
from .validation import (
    check_alpha,
    check_probability,
    check_variance,
    clean_outcome_01,
    cmr_error,
    is_dummy,
    split_binary_pilot,
)
from .variance_bounds import variance_bounds_by_method

_BINARY_RECTANGLE_KEYS = ("v_l1", "v_u1", "v_l0", "v_u0")


def canonical_method(method: str, y=None) -> str:
    """Map public method aliases to the internal variance-bound implementation."""

    method = str(method).lower()
    aliases = {
        "bounded": "bounded",
        "maurer_pontil": "bounded",
        "mp": "bounded",
        "bernoulli": "bernoulli",
        "bernoulli_exact": "bernoulli",
        "martinez_taboada_ramdas": "martinez_taboada_ramdas",
        "mtr": "martinez_taboada_ramdas",
        "unbounded": "unbounded_mom",
        "unbounded_mom": "unbounded_mom",
        "median_of_means": "unbounded_mom",
        "mom": "unbounded_mom",
    }
    if method == "auto":
        if y is None:
            cmr_error("`y` is required when method='auto'.")
        return "bernoulli" if is_dummy(y) else "bounded"
    if method not in aliases:
        cmr_error(
            "`method` must be one of 'auto', 'bounded', 'bernoulli', "
            "'maurer_pontil', 'mp', 'bernoulli_exact', "
            "'martinez_taboada_ramdas', 'mtr', or 'unbounded'."
        )
    return aliases[method]


def _equal_beta(alpha: float, correction: str) -> dict[str, float]:
    alpha = check_alpha(alpha)
    correction = _check_correction(correction)
    if correction == "bonferroni":
        beta_one = alpha / 4
    else:
        beta_one = (1 - math.sqrt(1 - alpha)) / 2
    return {
        "beta_l1": beta_one,
        "beta_u1": beta_one,
        "beta_l0": beta_one,
        "beta_u0": beta_one,
    }


def _check_correction(correction: str) -> str:
    correction = str(correction).lower()
    if correction not in {"bonferroni", "sidak_arms"}:
        cmr_error("`correction` must be 'bonferroni' or 'sidak_arms'.")
    return correction


def _joint_error_bound(beta: Mapping[str, float], correction: str) -> float:
    correction = _check_correction(correction)
    beta = _check_beta_vector(beta)
    if correction == "bonferroni":
        return float(sum(beta.values()))
    arm_1_error = beta["beta_l1"] + beta["beta_u1"]
    arm_0_error = beta["beta_l0"] + beta["beta_u0"]
    if arm_1_error > 1 or arm_0_error > 1:
        cmr_error("Sidak arm-level errors must be no larger than 1.")
    return float(1 - (1 - arm_1_error) * (1 - arm_0_error))


def _check_beta_vector(beta) -> dict[str, float]:
    required = ("beta_l1", "beta_u1", "beta_l0", "beta_u0")
    if not isinstance(beta, Mapping):
        cmr_error("`beta` must be a mapping with beta_l1, beta_u1, beta_l0, beta_u0.")
    missing = [key for key in required if key not in beta]
    if missing:
        cmr_error(f"`beta` is missing: {', '.join(missing)}.")
    out = {}
    for key in required:
        value = check_probability(beta[key], key, allow_boundary=True)
        if value.size != 1:
            cmr_error(f"`{key}` must be a scalar.")
        value = float(value.reshape(-1)[0])
        if value >= 1:
            cmr_error("Each element of `beta` must be smaller than 1.")
        out[key] = value
    return out


def _resolve_beta(alpha: float, beta=None, correction: str = "bonferroni") -> dict[str, float]:
    alpha = check_alpha(alpha)
    correction = _check_correction(correction)
    if beta is None:
        if correction == "bonferroni":
            beta_one = alpha / 4
        else:
            beta_one = (1 - math.sqrt(1 - alpha)) / 2
        return {
            "beta_l1": beta_one,
            "beta_u1": beta_one,
            "beta_l0": beta_one,
            "beta_u0": beta_one,
        }
    if not isinstance(beta, Mapping):
        value = check_probability(beta, "beta", allow_boundary=True)
        if value.size != 1:
            cmr_error(
                "`beta` must be None, a scalar, or a mapping with named endpoint errors."
            )
        beta_one = float(value.reshape(-1)[0])
        beta = {
            "beta_l1": beta_one,
            "beta_u1": beta_one,
            "beta_l0": beta_one,
            "beta_u0": beta_one,
        }
    out = _check_beta_vector(beta)
    joint = _joint_error_bound(out, correction)
    if joint > alpha + 1e-12:
        cmr_error(f"`beta` implies joint error {joint:.6g}, which exceeds `alpha`.")
    return out


def check_binary_rectangle(rectangle) -> dict[str, float]:
    """Validate a two-arm variance rectangle."""

    if isinstance(rectangle, RectangleResult):
        rectangle = rectangle.rectangle
    elif hasattr(rectangle, "rectangle") and not isinstance(rectangle, Mapping):
        rectangle = rectangle.rectangle

    if hasattr(rectangle, "to_dict") and not isinstance(rectangle, Mapping):
        rectangle = rectangle.to_dict()
    if isinstance(rectangle, Mapping) and "rectangle" in rectangle:
        rectangle = rectangle["rectangle"]

    if isinstance(rectangle, Mapping):
        missing = [key for key in _BINARY_RECTANGLE_KEYS if key not in rectangle]
        if missing:
            cmr_error(f"`rectangle` is missing: {', '.join(missing)}.")
        out = {
            key: float(check_variance(rectangle[key], key).reshape(-1)[0])
            for key in _BINARY_RECTANGLE_KEYS
        }
    else:
        arr = check_variance(rectangle, "rectangle").reshape(-1)
        if arr.size != 4:
            cmr_error("`rectangle` must contain four endpoints.")
        out = dict(zip(_BINARY_RECTANGLE_KEYS, map(float, arr), strict=True))

    if out["v_l1"] > out["v_u1"] + 1e-12 or out["v_l0"] > out["v_u0"] + 1e-12:
        cmr_error("Lower endpoints cannot exceed upper endpoints.")
    return out


def _binary_rectangle_result(
    rectangle: Mapping[str, float],
    treatment: Mapping,
    control: Mapping,
    alpha: float,
    beta: Mapping[str, float],
    correction: str,
    method: str,
    normalization=None,
) -> RectangleResult:
    rectangle = check_binary_rectangle(rectangle)
    beta = _check_beta_vector(beta)
    return RectangleResult(
        rectangle=rectangle,
        alpha=alpha,
        beta=beta,
        method=method,
        n={"n1": int(treatment["n"]), "n0": int(control["n"])},
        vhat={"vhat1": float(treatment["vhat"]), "vhat0": float(control["vhat"])},
        joint_error_bound=_joint_error_bound(beta, correction),
        diagnostics={"correction": correction, "normalization": normalization},
        extra={
            "treatment": dict(treatment),
            "control": dict(control),
            "correction": correction,
            "normalization": normalization,
        },
    )


def rectangle_bounded_binary(
    y,
    d,
    alpha: float = 0.05,
    method: str = "bounded",
    beta=None,
    correction: str = "bonferroni",
    normalize: bool = False,
    lower=None,
    upper=None,
    na_rm: bool = True,
) -> RectangleResult:
    """Build a distribution-free bounded-outcome two-arm confidence rectangle."""

    alpha = check_alpha(alpha)
    correction = _check_correction(correction)
    resolved_method = canonical_method(method, y=np.asarray(y, dtype=float))
    if resolved_method == "bernoulli":
        cmr_error("Use `rectangle_bernoulli_binary()` for exact Bernoulli bounds.")
    if resolved_method == "unbounded_mom":
        cmr_error("Use `rectangle_unbounded()` for unbounded-outcome bounds.")
    beta = _resolve_beta(alpha, beta=beta, correction=correction)
    pilot = split_binary_pilot(y, d, na_rm=na_rm, check_outcome=not normalize)
    normalization = None

    if normalize:
        from .validation import normalize_01

        y_norm, normalization = normalize_01(pilot["y"], lower=lower, upper=upper)
        pilot["y"] = y_norm
        pilot["y1"] = y_norm[pilot["d"] == 1]
        pilot["y0"] = y_norm[pilot["d"] == 0]
    else:
        clean_outcome_01(pilot["y"])

    treatment = variance_bounds_by_method(
        pilot["y1"],
        beta_l=beta["beta_l1"],
        beta_u=beta["beta_u1"],
        method=resolved_method,
    )
    control = variance_bounds_by_method(
        pilot["y0"],
        beta_l=beta["beta_l0"],
        beta_u=beta["beta_u0"],
        method=resolved_method,
    )
    rectangle = {
        "v_l1": treatment["L"],
        "v_u1": treatment["U"],
        "v_l0": control["L"],
        "v_u0": control["U"],
    }
    return _binary_rectangle_result(
        rectangle=rectangle,
        treatment=treatment,
        control=control,
        alpha=alpha,
        beta=beta,
        correction=correction,
        method=resolved_method,
        normalization=normalization,
    )


def rectangle_bernoulli_binary(
    y,
    d,
    alpha: float = 0.05,
    beta=None,
    correction: str = "bonferroni",
    na_rm: bool = True,
    tol: float = 1e-11,
) -> RectangleResult:
    """Build an exact folded-binomial Bernoulli two-arm confidence rectangle."""

    alpha = check_alpha(alpha)
    correction = _check_correction(correction)
    beta = _resolve_beta(alpha, beta=beta, correction=correction)
    pilot = split_binary_pilot(y, d, na_rm=na_rm)
    treatment = variance_bounds_by_method(
        pilot["y1"],
        beta_l=beta["beta_l1"],
        beta_u=beta["beta_u1"],
        method="bernoulli",
        tol=tol,
    )
    control = variance_bounds_by_method(
        pilot["y0"],
        beta_l=beta["beta_l0"],
        beta_u=beta["beta_u0"],
        method="bernoulli",
        tol=tol,
    )
    rectangle = {
        "v_l1": treatment["L"],
        "v_u1": treatment["U"],
        "v_l0": control["L"],
        "v_u0": control["U"],
    }
    return _binary_rectangle_result(
        rectangle=rectangle,
        treatment=treatment,
        control=control,
        alpha=alpha,
        beta=beta,
        correction=correction,
        method="bernoulli",
        normalization=None,
    )


def rectangle_two_arm(
    y,
    d,
    alpha: float = 0.05,
    method: str = "auto",
    beta=None,
    correction: str = "bonferroni",
    normalize: bool = False,
    lower=None,
    upper=None,
    psi=None,
    na_rm: bool = True,
    tol: float = 1e-11,
) -> RectangleResult:
    """Build a two-arm confidence rectangle, choosing Bernoulli bounds when possible."""

    if is_unbounded_method(method):
        check_unbounded_method_options(
            beta=beta,
            correction=correction,
            normalize=normalize,
            lower=lower,
            upper=upper,
        )
        return rectangle_unbounded(
            y=y,
            d=d,
            psi=psi,
            alpha=alpha,
            na_rm=na_rm,
        )

    pilot = split_binary_pilot(y, d, na_rm=na_rm, check_outcome=not normalize)
    resolved_method = canonical_method(method, y=pilot["y"])
    if resolved_method == "bernoulli":
        return rectangle_bernoulli_binary(
            pilot["y"],
            pilot["d"],
            alpha=alpha,
            beta=beta,
            correction=correction,
            na_rm=False,
            tol=tol,
        )
    return rectangle_bounded_binary(
        pilot["y"],
        pilot["d"],
        alpha=alpha,
        method=resolved_method,
        beta=beta,
        correction=correction,
        normalize=normalize,
        lower=lower,
        upper=upper,
        na_rm=False,
    )


rectangle_binary = rectangle_two_arm
