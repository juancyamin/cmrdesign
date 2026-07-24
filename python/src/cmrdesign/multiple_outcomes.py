"""Multiple-outcome CMR wrappers."""

from __future__ import annotations

import numpy as np

from .rectangles import canonical_method, rectangle_two_arm
from .results import CMRResult, RectangleResult
from .two_arm import cmr_two_arm_from_rectangle
from .unbounded import is_unbounded_method
from .validation import (
    as_numeric_array,
    check_alpha,
    check_treatment_indicator,
    check_weights,
    clean_outcome_01,
    cmr_error,
)
from .variance_bounds import variance_bounds_by_method


def _outcome_matrix(y) -> tuple[np.ndarray, list[str]]:
    names = None
    if hasattr(y, "columns"):
        names = list(map(str, y.columns))
    arr = as_numeric_array(y, "y")
    if arr.ndim == 1:
        arr = arr.reshape(-1, 1)
    if arr.ndim != 2 or arr.shape[0] < 1 or arr.shape[1] < 1:
        cmr_error("`y` must be a vector or two-dimensional outcome matrix.")
    if names is None or len(names) != arr.shape[1]:
        names = [f"outcome_{j + 1}" for j in range(arr.shape[1])]
    return arr, names


def _split_multiple_outcome_pilot(y, d, na_rm: bool = True) -> dict:
    y_arr, outcome_names = _outcome_matrix(y)
    d_arr = np.asarray(d, dtype=float)
    if d_arr.shape[0] != y_arr.shape[0]:
        cmr_error("`d` must have one entry per row of `y`.")
    missing = np.isnan(d_arr) | np.any(np.isnan(y_arr), axis=1)
    if np.any(missing):
        if not na_rm:
            cmr_error("`y` and `d` cannot contain missing values when `na_rm=False`.")
        y_arr = y_arr[~missing, :]
        d_arr = d_arr[~missing]
    d_arr = check_treatment_indicator(d_arr)
    if y_arr.shape[0] == 0:
        cmr_error("The pilot has no observed rows.")
    if np.any(~np.isfinite(y_arr)):
        cmr_error("`y` must contain only finite values.")
    if not np.any(d_arr == 1) or not np.any(d_arr == 0):
        cmr_error("The pilot must include both treatment (`d=1`) and control (`d=0`).")
    y_arr = clean_outcome_01(y_arr)
    return {
        "y": y_arr,
        "d": d_arr,
        "y1": y_arr[d_arr == 1, :],
        "y0": y_arr[d_arr == 0, :],
        "outcome_names": outcome_names,
    }


def _resolve_multiple_beta(alpha: float, n_outcomes: int, beta=None) -> float:
    alpha = check_alpha(alpha)
    if beta is None:
        return alpha / (4 * n_outcomes)
    value = float(as_numeric_array(beta, "beta").reshape(-1)[0])
    if value < 0 or value >= 1:
        cmr_error("`beta` must lie in [0, 1).")
    if 4 * n_outcomes * value > alpha + 1e-12:
        cmr_error("Scalar `beta` allocates joint error above `alpha`.")
    return value


def rectangle_multiple_outcomes(
    y,
    d,
    weights=None,
    estimand: str = "coprimary",
    alpha: float = 0.05,
    method: str = "auto",
    beta=None,
    na_rm: bool = True,
    tol: float = 1e-11,
) -> RectangleResult:
    estimand = str(estimand).lower()
    if estimand not in {"coprimary", "index"}:
        cmr_error("`estimand` must be 'coprimary' or 'index'.")
    alpha = check_alpha(alpha)
    if is_unbounded_method(method):
        cmr_error(
            "`method='unbounded'` is only available for two-arm designs; "
            "use `cmr_unbounded()` or `cmr_two_arm(..., method='unbounded')`."
        )
    pilot = _split_multiple_outcome_pilot(y, d, na_rm=na_rm)
    weights_arr = check_weights(weights, pilot["y"].shape[1])
    weights_dict = dict(zip(pilot["outcome_names"], map(float, weights_arr), strict=True))

    if estimand == "index":
        index_y = pilot["y"] @ weights_arr
        out = rectangle_two_arm(
            y=index_y,
            d=pilot["d"],
            alpha=alpha,
            method=method,
            beta=beta,
            correction="bonferroni",
            na_rm=False,
            tol=tol,
        )
        out.extra["estimand"] = "index"
        out.extra["weights"] = weights_dict
        out.extra["index_outcome_name"] = "weighted_index"
        return out

    resolved_method = canonical_method(method, y=pilot["y"].reshape(-1))
    beta_one = _resolve_multiple_beta(alpha, pilot["y"].shape[1], beta=beta)
    outcome_bounds = {}
    lower1 = []
    upper1 = []
    lower0 = []
    upper0 = []
    vhat1 = []
    vhat0 = []
    for col, name in enumerate(pilot["outcome_names"]):
        b1 = variance_bounds_by_method(
            pilot["y1"][:, col],
            beta_l=beta_one,
            beta_u=beta_one,
            method=resolved_method,
            tol=tol,
        )
        b0 = variance_bounds_by_method(
            pilot["y0"][:, col],
            beta_l=beta_one,
            beta_u=beta_one,
            method=resolved_method,
            tol=tol,
        )
        outcome_bounds[name] = {"treatment": b1, "control": b0}
        lower1.append(b1["L"])
        upper1.append(b1["U"])
        lower0.append(b0["L"])
        upper0.append(b0["U"])
        vhat1.append(b1["vhat"])
        vhat0.append(b0["vhat"])

    lower1 = np.asarray(lower1)
    upper1 = np.asarray(upper1)
    lower0 = np.asarray(lower0)
    upper0 = np.asarray(upper0)
    vhat1 = np.asarray(vhat1)
    vhat0 = np.asarray(vhat0)
    rectangle = {
        "v_l1": float(np.clip(np.sum(weights_arr * lower1), 0, 0.25)),
        "v_u1": float(np.clip(np.sum(weights_arr * upper1), 0, 0.25)),
        "v_l0": float(np.clip(np.sum(weights_arr * lower0), 0, 0.25)),
        "v_u0": float(np.clip(np.sum(weights_arr * upper0), 0, 0.25)),
    }
    return RectangleResult(
        rectangle=rectangle,
        alpha=alpha,
        beta=beta_one,
        method=resolved_method,
        n={"n1": int(pilot["y1"].shape[0]), "n0": int(pilot["y0"].shape[0])},
        vhat={
            "vhat1": float(np.sum(weights_arr * vhat1)),
            "vhat0": float(np.sum(weights_arr * vhat0)),
        },
        joint_error_bound=4 * len(weights_arr) * beta_one,
        diagnostics={"estimand": "coprimary"},
        extra={
            "estimand": "coprimary",
            "weights": weights_dict,
            "outcome_bounds": outcome_bounds,
            "outcome_vhat": {
                "treatment": dict(zip(pilot["outcome_names"], map(float, vhat1), strict=True)),
                "control": dict(zip(pilot["outcome_names"], map(float, vhat0), strict=True)),
            },
        },
    )


def cmr_multiple_outcomes(
    y,
    d,
    weights=None,
    estimand: str = "coprimary",
    alpha: float = 0.05,
    method: str = "auto",
    beta=None,
    na_rm: bool = True,
    tol: float = 1e-11,
) -> CMRResult:
    confidence_set = rectangle_multiple_outcomes(
        y=y,
        d=d,
        weights=weights,
        estimand=estimand,
        alpha=alpha,
        method=method,
        beta=beta,
        na_rm=na_rm,
        tol=tol,
    )
    out = cmr_two_arm_from_rectangle(confidence_set.rectangle)
    out.confidence_set = confidence_set
    out.pilot = {
        "n": confidence_set.n,
        "vhat": confidence_set.vhat,
        "method": confidence_set.method,
        "estimand": confidence_set.extra.get("estimand"),
        "weights": confidence_set.extra.get("weights"),
    }
    out.alpha = confidence_set.alpha
    out.beta = confidence_set.beta
    out.method = confidence_set.method
    out.joint_error_bound = confidence_set.joint_error_bound
    out.extra["estimand"] = confidence_set.extra.get("estimand")
    out.extra["weights"] = confidence_set.extra.get("weights")
    out.diagnostics["confidence_method"] = confidence_set.method
    out.diagnostics["joint_error_bound"] = confidence_set.joint_error_bound
    out.diagnostics["estimand"] = confidence_set.extra.get("estimand")
    return out
