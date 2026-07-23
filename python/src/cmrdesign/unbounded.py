"""Unbounded-outcome CMR extension with bounded kurtosis."""

from __future__ import annotations

import math
from collections.abc import Mapping, Sequence

import numpy as np

from .results import CMRResult, RectangleResult
from .validation import check_alpha, check_probability, cmr_error, split_binary_pilot

UNBOUNDED_METHODS = {
    "unbounded",
    "unbounded_mom",
    "median_of_means",
    "mom",
}

_RECTANGLE_KEYS = ("v_l1", "v_u1", "v_l0", "v_u0")


def is_unbounded_method(method: str) -> bool:
    """Return whether a method alias requests the unbounded MoM extension."""

    return str(method).lower() in UNBOUNDED_METHODS


def check_unbounded_method_options(
    beta=None,
    correction: str = "bonferroni",
    normalize: bool = False,
    lower=None,
    upper=None,
) -> None:
    """Reject bounded-outcome options that are not part of the unbounded rule."""

    if beta is not None:
        cmr_error(
            "`beta` is not used with `method='unbounded'`; use `alpha` and `psi`."
        )
    if str(correction).lower() != "bonferroni":
        cmr_error("`correction` is not used with `method='unbounded'`.")
    if normalize or lower is not None or upper is not None:
        cmr_error(
            "Unbounded-outcome bounds use raw numeric outcomes; do not set "
            "`normalize`, `lower`, or `upper`."
        )


def _as_finite_numeric_array(x, name: str) -> np.ndarray:
    try:
        arr = np.asarray(x, dtype=float)
    except (TypeError, ValueError) as exc:
        raise ValueError(f"`{name}` must be numeric.") from exc
    if np.any(np.isnan(arr)):
        cmr_error(f"`{name}` cannot contain missing values.")
    if np.any(~np.isfinite(arr)):
        cmr_error(f"`{name}` must contain only finite values.")
    return arr


def _as_nonnegative_array(x, name: str, allow_infinite: bool = False) -> np.ndarray:
    try:
        arr = np.asarray(x, dtype=float)
    except (TypeError, ValueError) as exc:
        raise ValueError(f"`{name}` must be numeric.") from exc
    if np.any(np.isnan(arr)):
        cmr_error(f"`{name}` cannot contain missing values.")
    finite_ok = np.isfinite(arr) | (np.isinf(arr) if allow_infinite else False)
    if np.any(~finite_ok):
        cmr_error(f"`{name}` has invalid values.")
    if np.any(arr < -1e-12):
        cmr_error(f"`{name}` must be nonnegative.")
    return np.maximum(arr, 0)


def _check_psi_scalar(psi, name: str = "psi") -> float:
    if psi is None:
        cmr_error(f"`{name}` is required for unbounded-outcome bounds.")
    arr = _as_finite_numeric_array(psi, name).reshape(-1)
    if arr.size != 1:
        cmr_error(f"`{name}` must be a scalar.")
    value = float(arr[0])
    if value < 1:
        cmr_error(f"`{name}` must be at least 1.")
    return value


def check_psi_pair(psi) -> dict[str, float]:
    """Validate a scalar or treatment/control pair of kurtosis bounds."""

    if psi is None:
        cmr_error("`psi` is required for unbounded-outcome CMR.")

    if isinstance(psi, Mapping):
        labels = {str(key).lower(): value for key, value in psi.items()}
        treatment_keys = ("1", "treatment", "treated", "d1", "arm1")
        control_keys = ("0", "control", "untreated", "d0", "arm0")
        treatment = [key for key in treatment_keys if key in labels]
        control = [key for key in control_keys if key in labels]
        if len(treatment) != 1 or len(control) != 1:
            cmr_error(
                "Named `psi` must identify treatment and control, for example "
                "`{'treatment': ..., 'control': ...}`."
            )
        out = {
            "1": _check_psi_scalar(labels[treatment[0]], "psi['1']"),
            "0": _check_psi_scalar(labels[control[0]], "psi['0']"),
        }
        return out

    arr = _as_finite_numeric_array(psi, "psi").reshape(-1)
    if arr.size == 1:
        value = _check_psi_scalar(arr[0])
        return {"1": value, "0": value}
    if arr.size != 2:
        cmr_error("`psi` must be a scalar or length-two treatment/control pair.")
    if np.any(arr < 1):
        cmr_error("All `psi` values must be at least 1.")
    return {"1": float(arr[0]), "0": float(arr[1])}


def _clean_unbounded_outcome(y, na_rm: bool = True) -> np.ndarray:
    try:
        arr = np.asarray(y, dtype=float).reshape(-1)
    except (TypeError, ValueError) as exc:
        raise ValueError("`y` must be numeric.") from exc
    missing = np.isnan(arr)
    if np.any(missing):
        if not na_rm:
            cmr_error("`y` contains missing values.")
        arr = arr[~missing]
    if arr.size == 0:
        cmr_error("`y` has no observed values.")
    if np.any(~np.isfinite(arr)):
        cmr_error("`y` must contain only finite values.")
    return arr


def _inactive_bounds(
    status: str,
    y: np.ndarray,
    alpha: float,
    psi: float,
    k: int,
    b: int,
    n_pairs: int,
    used_pairs: int,
    vhat: float = math.nan,
    rho: float = math.inf,
    block_means: Sequence[float] | None = None,
) -> dict:
    block_means = [] if block_means is None else list(map(float, block_means))
    return {
        "L": math.nan,
        "U": math.inf,
        "vhat": float(vhat),
        "method": "unbounded_mom",
        "n": int(y.size),
        "active": False,
        "status": status,
        "statistic": {
            "alpha": float(alpha),
            "psi": float(psi),
            "k": int(k),
            "b": int(b),
            "n_pairs": int(n_pairs),
            "used_pairs": int(used_pairs),
            "discarded_pairs": int(n_pairs - used_pairs),
            "rho": float(rho),
            "vhat": float(vhat),
            "block_means": block_means,
        },
    }


def variance_bounds_unbounded_mom(
    y,
    alpha: float = 0.05,
    psi=None,
    na_rm: bool = True,
) -> dict:
    """Median-of-means variance interval for unbounded outcomes."""

    alpha = check_alpha(alpha)
    psi = _check_psi_scalar(psi)
    y_arr = _clean_unbounded_outcome(y, na_rm=na_rm)

    k = int(math.ceil(8 * math.log(2 / alpha)))
    n_pairs = int(y_arr.size // 2)
    b = int(n_pairs // k)

    if b < 1:
        return _inactive_bounds(
            "pilot_too_small",
            y_arr,
            alpha,
            psi,
            k,
            b,
            n_pairs,
            0,
        )

    paired = (
        0.5
        * (y_arr[1 : 2 * n_pairs : 2] - y_arr[0 : 2 * n_pairs : 2]) ** 2
    )
    used_pairs = int(k * b)
    block_means = paired[:used_pairs].reshape(k, b).mean(axis=1)
    vhat = float(np.median(block_means))
    rho = float(math.sqrt(2 * (psi + 1) / b))

    if rho >= 1:
        return _inactive_bounds(
            "relative_error_at_least_one",
            y_arr,
            alpha,
            psi,
            k,
            b,
            n_pairs,
            used_pairs,
            vhat=vhat,
            rho=rho,
            block_means=block_means,
        )
    if vhat <= 0:
        return _inactive_bounds(
            "zero_mom_variance",
            y_arr,
            alpha,
            psi,
            k,
            b,
            n_pairs,
            used_pairs,
            vhat=vhat,
            rho=rho,
            block_means=block_means,
        )

    return {
        "L": float(vhat / (1 + rho)),
        "U": float(vhat / (1 - rho)),
        "vhat": vhat,
        "method": "unbounded_mom",
        "n": int(y_arr.size),
        "active": True,
        "status": "active",
        "statistic": {
            "alpha": float(alpha),
            "psi": float(psi),
            "k": int(k),
            "b": int(b),
            "n_pairs": int(n_pairs),
            "used_pairs": int(used_pairs),
            "discarded_pairs": int(n_pairs - used_pairs),
            "rho": rho,
            "vhat": vhat,
            "block_means": list(map(float, block_means)),
        },
    }


def check_unbounded_rectangle(rectangle) -> dict[str, float]:
    """Validate a finite nonnegative two-arm variance rectangle."""

    if isinstance(rectangle, RectangleResult):
        rectangle = rectangle.rectangle
    elif hasattr(rectangle, "rectangle") and not isinstance(rectangle, Mapping):
        rectangle = rectangle.rectangle
    if hasattr(rectangle, "to_dict") and not isinstance(rectangle, Mapping):
        rectangle = rectangle.to_dict()
    if isinstance(rectangle, Mapping) and "rectangle" in rectangle:
        rectangle = rectangle["rectangle"]

    if isinstance(rectangle, Mapping):
        missing = [key for key in _RECTANGLE_KEYS if key not in rectangle]
        if missing:
            cmr_error(f"`rectangle` is missing: {', '.join(missing)}.")
        out = {
            key: float(_as_nonnegative_array(rectangle[key], key).reshape(-1)[0])
            for key in _RECTANGLE_KEYS
        }
    else:
        arr = _as_nonnegative_array(rectangle, "rectangle").reshape(-1)
        if arr.size != 4:
            cmr_error("`rectangle` must contain four endpoints.")
        out = dict(zip(_RECTANGLE_KEYS, map(float, arr), strict=True))

    if out["v_l1"] > out["v_u1"] + 1e-12 or out["v_l0"] > out["v_u0"] + 1e-12:
        cmr_error("Lower endpoints cannot exceed upper endpoints.")
    return out


def _unbounded_rectangle_corners(rectangle) -> dict[str, dict[str, float]]:
    rect = check_unbounded_rectangle(rectangle)
    return {
        "treatment_high_control_low": {"v1": rect["v_u1"], "v0": rect["v_l0"]},
        "treatment_low_control_high": {"v1": rect["v_l1"], "v0": rect["v_u0"]},
    }


def _unbounded_regret(pi: float, v1: float, v0: float) -> float:
    pi_arr = check_probability(pi, "pi", allow_boundary=True)
    v1_arr = _as_nonnegative_array(v1, "v1")
    v0_arr = _as_nonnegative_array(v0, "v0")
    pi_arr, v1_arr, v0_arr = np.broadcast_arrays(pi_arr, v1_arr, v0_arr)
    out = np.empty_like(pi_arr, dtype=float)
    interior = (pi_arr > 0) & (pi_arr < 1)
    s1 = np.sqrt(v1_arr[interior])
    s0 = np.sqrt(v0_arr[interior])
    imbalance = (1 - pi_arr[interior]) * s1 - pi_arr[interior] * s0
    out[interior] = imbalance**2 / (pi_arr[interior] * (1 - pi_arr[interior]))
    left = pi_arr == 0
    out[left] = np.where(v1_arr[left] > 0, np.inf, 0)
    right = pi_arr == 1
    out[right] = np.where(v0_arr[right] > 0, np.inf, 0)
    return float(out.reshape(-1)[0]) if out.size == 1 else out


def cmr_unbounded_from_rectangle(rectangle) -> CMRResult:
    """Compute two-arm CMR from a finite nonnegative variance rectangle."""

    rect = check_unbounded_rectangle(rectangle)
    s_l1 = math.sqrt(rect["v_l1"])
    s_u1 = math.sqrt(rect["v_u1"])
    s_l0 = math.sqrt(rect["v_l0"])
    s_u0 = math.sqrt(rect["v_u0"])
    score_treatment = s_u1 + s_l1
    score_control = s_u0 + s_l0
    score_total = score_treatment + score_control
    pi = score_treatment / score_total if score_total > 0 else 0.5

    corners = _unbounded_rectangle_corners(rect)
    regret_plus = float(
        _unbounded_regret(
            pi,
            corners["treatment_high_control_low"]["v1"],
            corners["treatment_high_control_low"]["v0"],
        )
    )
    regret_minus = float(
        _unbounded_regret(
            pi,
            corners["treatment_low_control_high"]["v1"],
            corners["treatment_low_control_high"]["v0"],
        )
    )
    if math.isclose(regret_plus, regret_minus, rel_tol=0, abs_tol=1e-10):
        binding = "both"
    elif regret_plus > regret_minus:
        binding = "treatment_high_control_low"
    else:
        binding = "treatment_low_control_high"

    collapsed = rect["v_l1"] == rect["v_u1"] and rect["v_l0"] == rect["v_u0"]
    return CMRResult(
        pi=float(pi),
        u_cmr=float(max(regret_plus, regret_minus)),
        rectangle=rect,
        method="unbounded_mom",
        diagnostics={
            "score_treatment": score_treatment,
            "score_control": score_control,
            "collapsed_rectangle": collapsed,
            "unbounded_outcomes": True,
        },
        extra={
            "corners": corners,
            "corner_regrets": {
                "treatment_high_control_low": regret_plus,
                "treatment_low_control_high": regret_minus,
            },
            "binding": binding,
        },
    )


def rectangle_unbounded(
    y,
    d,
    psi=None,
    alpha: float = 0.05,
    na_rm: bool = True,
) -> RectangleResult:
    """Build the two-arm unbounded-outcome confidence rectangle."""

    alpha = check_alpha(alpha)
    psi_pair = check_psi_pair(psi)
    pilot = split_binary_pilot(y, d, na_rm=na_rm, check_outcome=False)

    treatment = variance_bounds_unbounded_mom(
        pilot["y1"],
        alpha=alpha,
        psi=psi_pair["1"],
        na_rm=False,
    )
    control = variance_bounds_unbounded_mom(
        pilot["y0"],
        alpha=alpha,
        psi=psi_pair["0"],
        na_rm=False,
    )

    active = bool(treatment["active"] and control["active"])
    if active:
        rectangle = check_unbounded_rectangle(
            {
                "v_l1": treatment["L"],
                "v_u1": treatment["U"],
                "v_l0": control["L"],
                "v_u0": control["U"],
            }
        )
        status = "active"
    else:
        rectangle = None
        status_parts = []
        if not treatment["active"]:
            status_parts.append(f"treatment:{treatment['status']}")
        if not control["active"]:
            status_parts.append(f"control:{control['status']}")
        status = ";".join(status_parts)

    rho = {
        "rho1": treatment["statistic"]["rho"],
        "rho0": control["statistic"]["rho"],
    }
    k = {"k1": treatment["statistic"]["k"], "k0": control["statistic"]["k"]}
    b = {"b1": treatment["statistic"]["b"], "b0": control["statistic"]["b"]}
    psi_named = {"psi1": psi_pair["1"], "psi0": psi_pair["0"]}

    return RectangleResult(
        rectangle=rectangle,
        alpha=float(alpha),
        beta=None,
        method="unbounded_mom",
        n={"n1": int(treatment["n"]), "n0": int(control["n"])},
        vhat={"vhat1": treatment["vhat"], "vhat0": control["vhat"]},
        joint_error_bound=float(alpha),
        diagnostics={
            "active": active,
            "status": status,
            "rho": rho,
            "k": k,
            "b": b,
            "psi": psi_named,
        },
        extra={
            "treatment": treatment,
            "control": control,
            "rho": rho,
            "k": k,
            "b": b,
            "psi": psi_named,
            "active": active,
            "status": status,
            "normalization": None,
        },
    )


def cmr_unbounded(
    y,
    d,
    psi=None,
    alpha: float = 0.05,
    na_rm: bool = True,
) -> CMRResult:
    """Estimate the two-arm CMR assignment for unbounded outcomes."""

    confidence_set = rectangle_unbounded(
        y=y,
        d=d,
        psi=psi,
        alpha=alpha,
        na_rm=na_rm,
    )
    if confidence_set.extra["active"]:
        out = cmr_unbounded_from_rectangle(confidence_set.rectangle)
    else:
        out = CMRResult(
            pi=0.5,
            u_cmr=math.inf,
            rectangle=None,
            method="unbounded_mom",
            diagnostics={
                "active": False,
                "status": confidence_set.extra["status"],
                "no_finite_certificate": True,
                "unbounded_outcomes": True,
            },
            extra={"corners": None, "corner_regrets": None, "binding": None},
        )

    out.confidence_set = confidence_set
    out.pilot = {
        "n": confidence_set.n,
        "vhat": confidence_set.vhat,
        "rho": confidence_set.extra["rho"],
        "k": confidence_set.extra["k"],
        "b": confidence_set.extra["b"],
        "psi": confidence_set.extra["psi"],
        "method": confidence_set.method,
        "active": confidence_set.extra["active"],
        "status": confidence_set.extra["status"],
        "normalization": None,
    }
    out.alpha = confidence_set.alpha
    out.beta = None
    out.method = confidence_set.method
    out.joint_error_bound = confidence_set.joint_error_bound
    out.diagnostics["confidence_method"] = confidence_set.method
    out.diagnostics["joint_error_bound"] = confidence_set.joint_error_bound
    out.diagnostics["active"] = confidence_set.extra["active"]
    out.diagnostics["status"] = confidence_set.extra["status"]
    return out
