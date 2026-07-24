"""Input validation and normalization helpers."""

from __future__ import annotations

import math
from collections.abc import Iterable

import numpy as np


def cmr_error(message: str) -> None:
    raise ValueError(message)


def label_missing(x) -> bool:
    if x is None:
        return True
    if isinstance(x, (float, np.floating)):
        return math.isnan(float(x))
    return False


def canonical_label(x) -> str:
    if isinstance(x, (bool, np.bool_)):
        return str(bool(x))
    if isinstance(x, (int, np.integer)):
        return str(int(x))
    if isinstance(x, (float, np.floating)):
        value = float(x)
        if math.isfinite(value) and value.is_integer():
            return str(int(value))
    return str(x)


def as_numeric_array(x, name: str) -> np.ndarray:
    try:
        arr = np.asarray(x, dtype=float)
    except (TypeError, ValueError) as exc:
        raise ValueError(f"`{name}` must be numeric.") from exc
    if np.any(np.isnan(arr)):
        cmr_error(f"`{name}` cannot contain missing values.")
    if np.any(~np.isfinite(arr)):
        cmr_error(f"`{name}` must contain only finite values.")
    return arr


def check_probability(p, name: str, allow_boundary: bool = True) -> np.ndarray:
    arr = as_numeric_array(p, name)
    if allow_boundary:
        bad = (arr < -1e-12) | (arr > 1 + 1e-12)
        msg = "[0, 1]"
    else:
        bad = (arr <= 0) | (arr >= 1)
        msg = "(0, 1)"
    if np.any(bad):
        cmr_error(f"`{name}` must lie in {msg}.")
    if allow_boundary:
        arr = np.clip(arr, 0, 1)
    return arr


def scalar_probability(p, name: str, allow_boundary: bool = True) -> float:
    arr = check_probability(p, name, allow_boundary=allow_boundary)
    if arr.size != 1:
        cmr_error(f"`{name}` must be a scalar.")
    return float(arr.reshape(-1)[0])


def check_alpha(alpha: float) -> float:
    return scalar_probability(alpha, "alpha", allow_boundary=False)


def check_tail_error(beta: float, name: str) -> float:
    beta = scalar_probability(beta, name, allow_boundary=True)
    if beta >= 1:
        cmr_error(f"`{name}` must be smaller than 1.")
    return beta


def check_variance(v, name: str) -> np.ndarray:
    arr = as_numeric_array(v, name)
    if np.any((arr < -1e-12) | (arr > 0.25 + 1e-12)):
        cmr_error(f"`{name}` must lie in [0, 1/4].")
    return np.clip(arr, 0, 0.25)


def scalar_variance(v, name: str) -> float:
    arr = check_variance(v, name)
    if arr.size != 1:
        cmr_error(f"`{name}` must be a scalar.")
    return float(arr.reshape(-1)[0])


def check_treatment_indicator(d) -> np.ndarray:
    arr = as_numeric_array(d, "d")
    bad = ~((np.abs(arr) <= 1e-12) | (np.abs(arr - 1) <= 1e-12))
    if np.any(bad):
        cmr_error("`d` must contain only 0 and 1.")
    return np.rint(arr).astype(int)


def clean_outcome_01(y, name: str = "y") -> np.ndarray:
    arr = as_numeric_array(y, name).astype(float)
    if arr.size == 0:
        cmr_error(f"`{name}` has no observed values.")
    if np.any((arr < -1e-12) | (arr > 1 + 1e-12)):
        cmr_error(f"`{name}` must lie in [0, 1].")
    return np.clip(arr, 0, 1)


def is_dummy(y, tol: float = 1e-12) -> bool:
    try:
        arr = np.asarray(y, dtype=float)
    except (TypeError, ValueError):
        return False
    if arr.size == 0 or np.any(~np.isfinite(arr)):
        return False
    return bool(np.all((np.abs(arr) <= tol) | (np.abs(arr - 1) <= tol)))


def split_binary_pilot(
    y,
    d,
    na_rm: bool = True,
    check_outcome: bool = True,
) -> dict[str, np.ndarray]:
    y_arr = np.asarray(y, dtype=float)
    d_arr = np.asarray(d, dtype=float)
    if y_arr.shape[0] != d_arr.shape[0]:
        cmr_error("`y` and `d` must have the same length.")
    missing = np.isnan(y_arr) | np.isnan(d_arr)
    if np.any(missing):
        if not na_rm:
            cmr_error("`y` and `d` cannot contain missing values when `na_rm=False`.")
        y_arr = y_arr[~missing]
        d_arr = d_arr[~missing]
    d_arr = check_treatment_indicator(d_arr)
    if check_outcome:
        y_arr = clean_outcome_01(y_arr)
    else:
        y_arr = as_numeric_array(y_arr, "y")
    if not np.any(d_arr == 1) or not np.any(d_arr == 0):
        cmr_error("The pilot must include both treatment (`d=1`) and control (`d=0`).")
    return {"y": y_arr, "d": d_arr, "y1": y_arr[d_arr == 1], "y0": y_arr[d_arr == 0]}


def normalize_01(x, lower=None, upper=None) -> tuple[np.ndarray, dict[str, float]]:
    arr = as_numeric_array(x, "y")
    if lower is None:
        lower = float(np.min(arr))
    if upper is None:
        upper = float(np.max(arr))
    if lower > upper:
        cmr_error("`lower` cannot exceed `upper`.")
    if upper == lower:
        out = np.full_like(arr, 0.5, dtype=float)
    else:
        out = np.clip((arr - lower) / (upper - lower), 0, 1)
    return out, {"lower": float(lower), "upper": float(upper)}


def scalar_int(x, name: str, lower: int = 1) -> int:
    if isinstance(x, bool):
        cmr_error(f"`{name}` must be an integer.")
    value = float(x)
    if not math.isfinite(value) or abs(value - round(value)) > 1e-12 or value < lower:
        cmr_error(f"`{name}` must be an integer at least {lower}.")
    return int(round(value))


def check_simplex(pi, name: str = "pi", tol: float = 1e-10) -> np.ndarray:
    arr = as_numeric_array(pi, name)
    if np.any(arr < -tol):
        cmr_error(f"`{name}` must be nonnegative.")
    arr = np.maximum(arr, 0)
    total = float(np.sum(arr))
    if not math.isfinite(total) or abs(total - 1) > tol:
        cmr_error(f"`{name}` must sum to one.")
    return arr / total


def check_weights(weights, n: int, name: str = "weights") -> np.ndarray:
    if weights is None:
        return np.full(n, 1 / n)
    arr = as_numeric_array(weights, name)
    if arr.size != n:
        cmr_error(f"`{name}` must have length {n}.")
    if np.any(arr < -1e-12):
        cmr_error(f"`{name}` must be nonnegative.")
    total = float(np.sum(np.maximum(arr, 0)))
    if total <= 0:
        cmr_error(f"`{name}` must contain positive mass.")
    return np.maximum(arr, 0) / total
