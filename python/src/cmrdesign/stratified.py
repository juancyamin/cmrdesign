"""Stratified CMR public API."""

from __future__ import annotations

from collections.abc import Mapping

import numpy as np

from .results import CMRResult, RectangleResult
from .rectangles import canonical_method
from .solver import (
    hyperrectangle_vertices,
    inverse_share_sums,
    normalize_simplex,
    solve_vertex_epigraph,
    vertex_certificate,
)
from .unbounded import is_unbounded_method
from .validation import (
    as_numeric_array,
    canonical_label,
    check_alpha,
    check_treatment_indicator,
    check_variance,
    clean_outcome_01,
    cmr_error,
    label_missing,
    normalize_01,
)
from .variance_bounds import variance_bounds_by_method


def check_strata_share(strata_share, observed=None) -> dict[str, float]:
    if isinstance(strata_share, Mapping):
        out = {canonical_label(k): float(v) for k, v in strata_share.items()}
    else:
        arr = as_numeric_array(strata_share, "strata_share").reshape(-1)
        if observed is None:
            names = [f"stratum_{i + 1}" for i in range(arr.size)]
        else:
            names = [canonical_label(x) for x in observed]
            if len(names) != arr.size:
                cmr_error("Unnamed `strata_share` must have one entry per observed stratum.")
        out = dict(zip(names, map(float, arr), strict=True))
    if not out:
        cmr_error("`strata_share` must contain at least one stratum.")
    if any(value <= 0 for value in out.values()):
        cmr_error("Every stratum share must be positive.")
    total = sum(out.values())
    if abs(total - 1) > 1e-10:
        cmr_error("`strata_share` must sum to one.")
    return {key: value / total for key, value in out.items()}


def stratified_cell_names(strata_names) -> list[str]:
    return [f"{arm}:{stratum}" for stratum in strata_names for arm in ("1", "0")]


def _row_alias(row) -> str | None:
    row = str(row).lower()
    if row in {"1", "treatment", "treated", "treat"}:
        return "1"
    if row in {"0", "control", "ctrl"}:
        return "0"
    return None


def standardize_stratified_matrix(
    x,
    strata_share: Mapping[str, float],
    name: str,
    check_as_variance: bool = True,
) -> np.ndarray:
    strata_names = list(strata_share)
    if isinstance(x, Mapping):
        rows = {}
        for raw_row, values in x.items():
            row = _row_alias(raw_row)
            if row is None:
                continue
            if isinstance(values, Mapping):
                missing = [s for s in strata_names if s not in values]
                if missing:
                    cmr_error(f"`{name}` is missing strata: {', '.join(missing)}.")
                rows[row] = [values[s] for s in strata_names]
            else:
                arr = as_numeric_array(values, name).reshape(-1)
                if arr.size != len(strata_names):
                    cmr_error(f"`{name}` rows must have one entry per stratum.")
                rows[row] = arr
        if "1" not in rows or "0" not in rows:
            cmr_error(f"`{name}` must include treatment and control rows.")
        arr = np.vstack([rows["1"], rows["0"]])
    else:
        arr = as_numeric_array(x, name)
        if arr.ndim != 2 or arr.shape != (2, len(strata_names)):
            cmr_error(f"`{name}` must be a 2 x S array.")
    values = arr.reshape(-1)
    if check_as_variance:
        values = check_variance(values, name)
    else:
        if np.any(values < -1e-12):
            cmr_error(f"`{name}` must be nonnegative.")
        values = np.maximum(values, 0)
    return values.reshape(2, len(strata_names))


def stratified_matrix_to_vector(x) -> np.ndarray:
    return np.asarray(x, dtype=float).reshape(-1, order="F")


def stratified_vector_to_matrix(x, strata_names) -> dict[str, dict[str, float]]:
    arr = np.asarray(x, dtype=float).reshape(2, len(strata_names), order="F")
    return {
        "1": dict(zip(strata_names, map(float, arr[0, :]), strict=True)),
        "0": dict(zip(strata_names, map(float, arr[1, :]), strict=True)),
    }


def _check_stratified_variances(variances, strata_share, name="variances") -> dict:
    strata_share = check_strata_share(strata_share)
    matrix = standardize_stratified_matrix(variances, strata_share, name)
    strata_names = list(strata_share)
    vector = stratified_matrix_to_vector(matrix)
    cell_names = stratified_cell_names(strata_names)
    weights = np.repeat(np.asarray(list(strata_share.values()), dtype=float) ** 2, 2)
    return {
        "matrix": matrix,
        "vector": vector,
        "strata_share": strata_share,
        "cell_names": cell_names,
        "weights": weights,
    }


def _pi_array(pi, strata_share) -> np.ndarray:
    strata_names = list(strata_share)
    cell_names = stratified_cell_names(strata_names)
    if isinstance(pi, Mapping):
        missing = [cell for cell in cell_names if cell not in pi]
        if missing:
            cmr_error(f"`pi` is missing cells: {', '.join(missing)}.")
        arr = [pi[cell] for cell in cell_names]
    else:
        arr = pi
    arr = normalize_simplex(arr, "pi")
    if arr.size != 2 * len(strata_names):
        cmr_error("`pi` must contain two cell shares per stratum.")
    return arr


def check_stratified_rectangle(rectangle, strata_share) -> dict:
    strata_share = check_strata_share(strata_share)
    if isinstance(rectangle, RectangleResult):
        rectangle = rectangle.rectangle
    elif hasattr(rectangle, "rectangle") and not isinstance(rectangle, Mapping):
        rectangle = rectangle.rectangle
    if not isinstance(rectangle, Mapping) or "lower" not in rectangle or "upper" not in rectangle:
        cmr_error("`rectangle` must be a mapping with `lower` and `upper` matrices.")
    lower = standardize_stratified_matrix(rectangle["lower"], strata_share, "rectangle['lower']")
    upper = standardize_stratified_matrix(rectangle["upper"], strata_share, "rectangle['upper']")
    if np.any(lower > upper + 1e-12):
        cmr_error("Lower endpoints cannot exceed upper endpoints.")
    lower_vec = stratified_matrix_to_vector(lower)
    upper_vec = stratified_matrix_to_vector(upper)
    strata_names = list(strata_share)
    return {
        "lower": lower_vec,
        "upper": upper_vec,
        "lower_matrix": lower,
        "upper_matrix": upper,
        "strata_share": strata_share,
        "cell_names": stratified_cell_names(strata_names),
        "weights": np.repeat(np.asarray(list(strata_share.values())) ** 2, 2),
    }


def stratified_variance_objective(pi, variances, strata_share) -> float:
    checked = _check_stratified_variances(variances, strata_share)
    pi = _pi_array(pi, checked["strata_share"])
    A = (checked["weights"] * checked["vector"]).reshape(1, -1)
    return float(inverse_share_sums(pi, A)[0])


def stratified_oracle_variance(variances, strata_share) -> float:
    checked = _check_stratified_variances(variances, strata_share)
    return float(np.sum(np.sqrt(checked["weights"] * checked["vector"])) ** 2)


def assign_stratified_neyman(variances, strata_share) -> dict[str, float]:
    checked = _check_stratified_variances(variances, strata_share)
    scores = np.sqrt(checked["weights"] * checked["vector"])
    if float(np.sum(scores)) > 0:
        pi = scores / np.sum(scores)
    else:
        shares = np.asarray(list(checked["strata_share"].values()), dtype=float)
        pi = np.repeat(shares / 2, 2)
    return dict(zip(checked["cell_names"], map(float, pi), strict=True))


def stratified_regret(pi, variances, strata_share) -> float:
    return stratified_variance_objective(pi, variances, strata_share) - stratified_oracle_variance(
        variances, strata_share
    )


def stratified_rectangle_vertices(rectangle, strata_share, max_vertices: int = 65536) -> dict:
    checked = check_stratified_rectangle(rectangle, strata_share)
    return hyperrectangle_vertices(
        checked["lower"],
        checked["upper"],
        names=checked["cell_names"],
        max_vertices=max_vertices,
    )


def cmr_stratified_from_rectangle(
    rectangle,
    strata_share,
    control: Mapping | None = None,
    max_vertices: int = 65536,
) -> CMRResult:
    checked = check_stratified_rectangle(rectangle, strata_share)
    vertices = stratified_rectangle_vertices(
        rectangle,
        checked["strata_share"],
        max_vertices=max_vertices,
    )
    A = vertices["vertices"] * checked["weights"].reshape(1, -1)
    oracle = np.sum(np.sqrt(A), axis=1) ** 2
    strata_names = list(checked["strata_share"])
    default_start = np.repeat(np.asarray(list(checked["strata_share"].values())) / 2, 2)

    collapsed = bool(np.all(checked["lower"] == checked["upper"]))
    full = bool(np.all(checked["lower"] == 0) and np.all(checked["upper"] == 0.25))
    if collapsed:
        variances = stratified_vector_to_matrix(checked["lower"], strata_names)
        pi_dict = assign_stratified_neyman(variances, checked["strata_share"])
        pi_array = np.asarray([pi_dict[cell] for cell in checked["cell_names"]])
        details = vertex_certificate(pi_array, A, oracle, True)
        solution = {
            "pi": pi_dict,
            "pi_array": pi_array,
            "value": details["value"],
            "vertex_regrets": details["vertex_regrets"],
            "active_vertices": details["active_vertices"],
            "diagnostics": {"solver": "collapsed_closed_form", "converged": True},
        }
    elif full:
        pi_array = default_start
        pi_dict = dict(zip(checked["cell_names"], map(float, pi_array), strict=True))
        details = vertex_certificate(pi_array, A, oracle, True)
        solution = {
            "pi": pi_dict,
            "pi_array": pi_array,
            "value": details["value"],
            "vertex_regrets": details["vertex_regrets"],
            "active_vertices": details["active_vertices"],
            "diagnostics": {"solver": "full_rectangle_closed_form", "converged": True},
        }
    else:
        control = {} if control is None else dict(control)
        control["component_names"] = checked["cell_names"]
        solution = solve_vertex_epigraph(A, oracle, default_start=default_start, control=control)

    pi_array = solution["pi_array"]
    sampling_margin = {}
    treatment_margin = {}
    for idx, stratum in enumerate(strata_names):
        pair = pi_array[(2 * idx) : (2 * idx + 2)]
        total = float(np.sum(pair))
        sampling_margin[stratum] = total
        treatment_margin[stratum] = float(pair[0] / total) if total > 0 else float("nan")

    diagnostics = dict(solution["diagnostics"])
    diagnostics.update({"S": len(strata_names), "full_rectangle": full, "collapsed_rectangle": collapsed})
    return CMRResult(
        pi=solution["pi"],
        u_cmr=float(solution["value"]),
        rectangle=checked,
        diagnostics=diagnostics,
        extra={
            "strata_share": checked["strata_share"],
            "cell_names": checked["cell_names"],
            "pi_matrix": stratified_vector_to_matrix(pi_array, strata_names),
            "sampling_margin": sampling_margin,
            "treatment_margin": treatment_margin,
            "vertices": vertices,
            "vertex_regrets": solution["vertex_regrets"],
            "binding_vertices": [vertices["vertex_names"][i] for i in solution["active_vertices"]],
        },
    )


def _split_stratified_pilot(y, d, strata, strata_share, na_rm: bool = True) -> dict:
    y_arr = np.asarray(y, dtype=float)
    d_arr = np.asarray(d, dtype=float)
    strata_arr = np.asarray(strata, dtype=object)
    if y_arr.shape[0] != d_arr.shape[0] or y_arr.shape[0] != strata_arr.shape[0]:
        cmr_error("`y`, `d`, and `strata` must have the same length.")
    strata_missing = np.asarray([label_missing(x) for x in strata_arr], dtype=bool)
    missing = np.isnan(y_arr) | np.isnan(d_arr) | strata_missing
    if np.any(missing):
        if not na_rm:
            cmr_error("`y`, `d`, and `strata` cannot contain missing values when `na_rm=False`.")
        y_arr = y_arr[~missing]
        d_arr = d_arr[~missing]
        strata_arr = strata_arr[~missing]
    if y_arr.size == 0:
        cmr_error("The pilot has no observed rows.")
    d_arr = check_treatment_indicator(d_arr)
    if np.any(~np.isfinite(y_arr)):
        cmr_error("`y` must contain only finite values.")
    strata_chr = np.asarray([canonical_label(x) for x in strata_arr], dtype=object)
    observed = list(dict.fromkeys(strata_chr))
    shares = check_strata_share(strata_share, observed=observed)
    missing_share = [s for s in observed if s not in shares]
    if missing_share:
        cmr_error(f"`strata_share` is missing observed strata: {', '.join(missing_share)}.")
    missing_pilot = [s for s in shares if s not in observed]
    if missing_pilot:
        cmr_error(f"The pilot has no observations for strata: {', '.join(missing_pilot)}.")
    return {"y": y_arr, "d": d_arr, "strata": strata_chr, "strata_share": shares}


def _resolve_stratified_beta(alpha: float, strata_share, beta=None) -> dict:
    alpha = check_alpha(alpha)
    strata_share = check_strata_share(strata_share)
    strata_names = list(strata_share)
    if beta is None:
        value = alpha / (4 * len(strata_names))
        lower = np.full((2, len(strata_names)), value)
        upper = lower.copy()
    elif isinstance(beta, Mapping) and "lower" in beta and "upper" in beta:
        lower = standardize_stratified_matrix(
            beta["lower"], strata_share, "beta['lower']", check_as_variance=False
        )
        upper = standardize_stratified_matrix(
            beta["upper"], strata_share, "beta['upper']", check_as_variance=False
        )
    else:
        value = float(as_numeric_array(beta, "beta").reshape(-1)[0])
        lower = np.full((2, len(strata_names)), value)
        upper = lower.copy()
    if np.any(lower < 0) or np.any(upper < 0) or np.any(lower >= 1) or np.any(upper >= 1):
        cmr_error("Every beta endpoint error must lie in [0, 1).")
    if float(np.sum(lower) + np.sum(upper)) > alpha + 1e-12:
        cmr_error("`beta` allocates joint error above `alpha`.")
    return {"lower": lower, "upper": upper}


def rectangle_stratified(
    y,
    d,
    strata,
    strata_share,
    alpha: float = 0.05,
    method: str = "auto",
    beta=None,
    normalize: bool = False,
    lower=None,
    upper=None,
    na_rm: bool = True,
    tol: float = 1e-11,
) -> RectangleResult:
    alpha = check_alpha(alpha)
    if is_unbounded_method(method):
        cmr_error(
            "`method='unbounded'` is only available for two-arm designs; "
            "use `cmr_unbounded()` or `cmr_two_arm(..., method='unbounded')`."
        )
    pilot = _split_stratified_pilot(
        y=y,
        d=d,
        strata=strata,
        strata_share=strata_share,
        na_rm=na_rm,
    )
    normalization = None
    if normalize:
        pilot["y"], normalization = normalize_01(pilot["y"], lower=lower, upper=upper)
    else:
        pilot["y"] = clean_outcome_01(pilot["y"])
    resolved_method = canonical_method(method, y=pilot["y"])
    beta_out = _resolve_stratified_beta(alpha, pilot["strata_share"], beta=beta)

    strata_names = list(pilot["strata_share"])
    lower_matrix = np.zeros((2, len(strata_names)))
    upper_matrix = np.zeros((2, len(strata_names)))
    n = np.zeros((2, len(strata_names)), dtype=int)
    vhat = np.zeros((2, len(strata_names)))
    cell_results = {}
    for col, stratum in enumerate(strata_names):
        for row, arm_label in enumerate((1, 0)):
            keep = (pilot["strata"] == stratum) & (pilot["d"] == arm_label)
            result = variance_bounds_by_method(
                pilot["y"][keep],
                beta_l=beta_out["lower"][row, col],
                beta_u=beta_out["upper"][row, col],
                method=resolved_method,
                tol=tol,
            )
            lower_matrix[row, col] = result["L"]
            upper_matrix[row, col] = result["U"]
            n[row, col] = int(result["n"])
            vhat[row, col] = float(result["vhat"])
            cell_results[f"{arm_label}:{stratum}"] = result

    rectangle = {"lower": lower_matrix, "upper": upper_matrix}
    return RectangleResult(
        rectangle=rectangle,
        alpha=alpha,
        beta=beta_out,
        method=resolved_method,
        n=stratified_vector_to_matrix(stratified_matrix_to_vector(n), strata_names),
        vhat=stratified_vector_to_matrix(stratified_matrix_to_vector(vhat), strata_names),
        joint_error_bound=float(np.sum(beta_out["lower"]) + np.sum(beta_out["upper"])),
        diagnostics={"normalization": normalization},
        extra={
            "strata_share": pilot["strata_share"],
            "cell_results": cell_results,
            "normalization": normalization,
        },
    )


def cmr_stratified(
    y,
    d,
    strata,
    strata_share,
    alpha: float = 0.05,
    method: str = "auto",
    beta=None,
    normalize: bool = False,
    lower=None,
    upper=None,
    na_rm: bool = True,
    tol: float = 1e-11,
    solver_control: Mapping | None = None,
    max_vertices: int = 65536,
) -> CMRResult:
    confidence_set = rectangle_stratified(
        y=y,
        d=d,
        strata=strata,
        strata_share=strata_share,
        alpha=alpha,
        method=method,
        beta=beta,
        normalize=normalize,
        lower=lower,
        upper=upper,
        na_rm=na_rm,
        tol=tol,
    )
    out = cmr_stratified_from_rectangle(
        confidence_set.rectangle,
        strata_share=confidence_set.extra["strata_share"],
        control=solver_control,
        max_vertices=max_vertices,
    )
    out.confidence_set = confidence_set
    out.pilot = {
        "n": confidence_set.n,
        "vhat": confidence_set.vhat,
        "method": confidence_set.method,
        "normalization": confidence_set.extra.get("normalization"),
    }
    out.alpha = confidence_set.alpha
    out.beta = confidence_set.beta
    out.method = confidence_set.method
    out.joint_error_bound = confidence_set.joint_error_bound
    out.diagnostics["confidence_method"] = confidence_set.method
    out.diagnostics["joint_error_bound"] = confidence_set.joint_error_bound
    out.extra["strata_share"] = confidence_set.extra["strata_share"]
    out.extra["cell_names"] = list(confidence_set.extra["cell_results"])
    return out
