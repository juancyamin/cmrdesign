"""Shared-control multi-arm CMR public API."""

from __future__ import annotations

import re
from collections.abc import Mapping

import numpy as np

from .rectangles import prepare_outcome_scale
from .results import CMRResult, RectangleResult
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
    check_variance,
    clean_outcome_01,
    cmr_error,
    error_context,
    label_missing,
)
from .variance_bounds import variance_bounds_by_method


def _arm_order(arms) -> list[str]:
    arms = [canonical_label(arm) for arm in arms]
    if all(arm.isdigit() for arm in arms):
        return sorted(arms, key=lambda x: int(x))
    return [arm for arm in arms if arm == "0"] + [arm for arm in arms if arm != "0"]


def _standardize_arm_labels(labels) -> list[str]:
    """Drop the ``v`` prefix only when every label has the form ``v0``, ``v1``, ...

    Pilot arm labels such as ``"variant_a"`` or ``"v1"`` (next to a control
    already standardized to ``"0"``) are never renamed.
    """

    labels = [str(label) for label in labels]
    prefixed = labels and all(re.fullmatch(r"v[0-9]+", label) for label in labels)
    if prefixed and "0" not in labels:
        return [label[1:] for label in labels]
    return labels


def check_multiarm_variances(variances, name: str = "variances") -> dict[str, float]:
    if not isinstance(variances, Mapping):
        arr = check_variance(variances, name).reshape(-1)
        if arr.size < 2:
            cmr_error(f"`{name}` must contain control plus at least one treatment arm.")
        variances = {str(i): float(value) for i, value in enumerate(arr)}
    else:
        labels = _standardize_arm_labels(variances.keys())
        variances = {
            label: float(check_variance(value, f"{name}[{key}]").reshape(-1)[0])
            for label, (key, value) in zip(labels, variances.items(), strict=True)
        }
    if "0" not in variances:
        cmr_error(f"`{name}` must include control arm `0`.")
    if len(variances) < 2:
        cmr_error(f"`{name}` must contain control plus at least one treatment arm.")
    return {arm: variances[arm] for arm in _arm_order(variances)}


def check_multiarm_rectangle(rectangle) -> dict[str, dict[str, float]]:
    if isinstance(rectangle, RectangleResult):
        rectangle = rectangle.rectangle
    elif hasattr(rectangle, "rectangle") and not isinstance(rectangle, Mapping):
        rectangle = rectangle.rectangle
    if hasattr(rectangle, "to_dict") and not isinstance(rectangle, Mapping):
        rectangle = rectangle.to_dict()
    if isinstance(rectangle, Mapping) and "rectangle" in rectangle:
        rectangle = rectangle["rectangle"]

    out = {}
    if isinstance(rectangle, Mapping):
        endpoint_keys = list(rectangle.keys())
        lower_keys = [key for key in endpoint_keys if str(key).startswith("v_l")]
        if lower_keys:
            for lower_key in lower_keys:
                arm = str(lower_key)[3:]
                upper_key = f"v_u{arm}"
                if upper_key not in rectangle:
                    cmr_error(f"Rectangle is missing: {upper_key}.")
                out[arm] = {
                    "lower": float(check_variance(rectangle[lower_key], str(lower_key)).reshape(-1)[0]),
                    "upper": float(check_variance(rectangle[upper_key], upper_key).reshape(-1)[0]),
                }
        else:
            for arm, endpoints in rectangle.items():
                if not isinstance(endpoints, Mapping):
                    cmr_error("Mapping rectangles need `lower` and `upper` by arm.")
                if "lower" not in endpoints or "upper" not in endpoints:
                    cmr_error("Mapping rectangles need `lower` and `upper` by arm.")
                out[str(arm)] = {
                    "lower": float(check_variance(endpoints["lower"], "lower").reshape(-1)[0]),
                    "upper": float(check_variance(endpoints["upper"], "upper").reshape(-1)[0]),
                }
            labels = _standardize_arm_labels(out.keys())
            out = dict(zip(labels, out.values(), strict=True))
    else:
        arr = check_variance(rectangle, "rectangle")
        if arr.ndim != 2 or arr.shape[1] != 2:
            cmr_error("Array rectangles must have shape (n_arms, 2).")
        out = {
            str(i): {"lower": float(row[0]), "upper": float(row[1])}
            for i, row in enumerate(arr)
        }

    if "0" not in out:
        cmr_error("A multi-arm rectangle must include control arm `0`.")
    if len(out) < 2:
        cmr_error("A multi-arm rectangle must include control plus at least one treatment.")
    for arm, endpoints in out.items():
        if endpoints["lower"] > endpoints["upper"] + 1e-12:
            cmr_error(f"Lower endpoint exceeds upper endpoint for arm `{arm}`.")
    return {arm: out[arm] for arm in _arm_order(out)}


def multiarm_weights(arms) -> dict[str, float]:
    arms = _arm_order(arms)
    k_treatments = len(arms) - 1
    weights = {arm: 1.0 for arm in arms}
    weights["0"] = float(k_treatments)
    return weights


def _pi_array(pi, arms) -> np.ndarray:
    if isinstance(pi, Mapping):
        missing = [arm for arm in arms if arm not in pi]
        if missing:
            cmr_error(f"Named `pi` is missing arms: {', '.join(missing)}.")
        arr = [pi[arm] for arm in arms]
    else:
        arr = pi
    arr = normalize_simplex(arr, "pi")
    if arr.size != len(arms):
        cmr_error("`pi` and `variances` must have the same length.")
    return arr


def multiarm_variance_objective(pi, variances) -> float:
    """Variance objective of a shared-control multi-arm design.

    With ``K`` treatment arms the objective is ``K * v0 / pi0 + sum_k vk / pik``,
    the sum of the variances of the ``K`` treatment-control contrasts.

    Parameters
    ----------
    pi : mapping or array_like
        Assignment shares over all arms, summing to one.
    variances : mapping or array_like
        Arm variances. A mapping from arm label to variance must include the
        control arm ``"0"``. A sequence is read as control first, then treatments.
        Labels of the form ``v0``, ``v1``, ... are also accepted.

    Returns
    -------
    float
        The objective.
    """

    variances = check_multiarm_variances(variances)
    arms = list(variances)
    pi = _pi_array(pi, arms)
    weights = multiarm_weights(arms)
    A = np.asarray([[weights[arm] * variances[arm] for arm in arms]], dtype=float)
    return float(inverse_share_sums(pi, A)[0])


def multiarm_oracle_variance(variances) -> float:
    """Smallest multi-arm variance objective at known variances.

    Returns ``(sqrt(K * v0) + sum_k sqrt(vk)) ** 2``.

    Parameters
    ----------
    variances : mapping or array_like
        Arm variances. A mapping from arm label to variance must include the
        control arm ``"0"``. A sequence is read as control first, then treatments.
        Labels of the form ``v0``, ``v1``, ... are also accepted.

    Returns
    -------
    float
        The oracle value.
    """

    variances = check_multiarm_variances(variances)
    weights = multiarm_weights(variances)
    return float(
        sum((weights[arm] * variances[arm]) ** 0.5 for arm in variances) ** 2
    )


def assign_multiarm_neyman(variances) -> dict[str, float]:
    """Neyman allocation of a shared-control multi-arm design.

    Shares are proportional to ``sqrt(K * v0)`` for control and ``sqrt(vk)`` for
    each treatment arm.

    Parameters
    ----------
    variances : mapping or array_like
        Arm variances. A mapping from arm label to variance must include the
        control arm ``"0"``. A sequence is read as control first, then treatments.
        Labels of the form ``v0``, ``v1``, ... are also accepted.

    Returns
    -------
    dict
        Assignment shares by arm label, with control first.
    """

    variances = check_multiarm_variances(variances)
    weights = multiarm_weights(variances)
    scores = np.asarray(
        [(weights[arm] * variances[arm]) ** 0.5 for arm in variances], dtype=float
    )
    if float(np.sum(scores)) > 0:
        pi = scores / np.sum(scores)
    else:
        pi = np.full(len(scores), 1 / len(scores))
    return dict(zip(variances.keys(), map(float, pi), strict=True))


def multiarm_regret(pi, variances) -> float:
    """Regret of a multi-arm allocation at known variances.

    Parameters
    ----------
    pi : mapping or array_like
        Assignment shares over all arms, summing to one.
    variances : mapping or array_like
        Arm variances. A mapping from arm label to variance must include the
        control arm ``"0"``. A sequence is read as control first, then treatments.
        Labels of the form ``v0``, ``v1``, ... are also accepted.

    Returns
    -------
    float
        The variance objective at ``pi`` minus its oracle value.
    """

    return multiarm_variance_objective(pi, variances) - multiarm_oracle_variance(variances)


def multiarm_rectangle_vertices(rectangle, max_vertices: int = 65536) -> dict:
    """Vertices of a multi-arm variance rectangle.

    Parameters
    ----------
    rectangle : mapping or array_like
        Multi-arm variance rectangle. Either a mapping from arm label to
        ``{"lower": ..., "upper": ...}``, a flat mapping with keys such as ``v_l0``
        and ``v_u0``, or an array of shape ``(n_arms, 2)`` with control in the
        first row.
    max_vertices : int, default 65536
        Largest number of rectangle vertices to enumerate. The count doubles with
        every arm or cell.

    Returns
    -------
    dict
        The array ``vertices`` with one row per vertex, the arm ``names``, and
        ``vertex_names`` such as ``"u0_l1_l2"``.
    """

    rect = check_multiarm_rectangle(rectangle)
    arms = list(rect)
    lower = [rect[arm]["lower"] for arm in arms]
    upper = [rect[arm]["upper"] for arm in arms]
    return hyperrectangle_vertices(lower, upper, names=arms, max_vertices=max_vertices)


def _multiarm_vertex_problem(rectangle, max_vertices: int = 65536) -> dict:
    rect = check_multiarm_rectangle(rectangle)
    arms = list(rect)
    weights = multiarm_weights(arms)
    vertices = multiarm_rectangle_vertices(rect, max_vertices=max_vertices)
    A = vertices["vertices"] * np.asarray([weights[arm] for arm in arms]).reshape(1, -1)
    oracle = np.sum(np.sqrt(A), axis=1) ** 2
    return {"rect": rect, "arms": arms, "weights": weights, "vertices": vertices, "A": A, "oracle": oracle}


def cmr_multiarm_from_rectangle(
    rectangle,
    control: Mapping | None = None,
    max_vertices: int = 65536,
) -> CMRResult:
    """Multi-arm CMR allocation for a given variance rectangle.

    Minimizes the worst regret over the vertices of the rectangle. Collapsed and
    uninformative rectangles have closed forms. Other rectangles are solved as a
    convex program.

    Parameters
    ----------
    rectangle : mapping or array_like
        Multi-arm variance rectangle. Either a mapping from arm label to
        ``{"lower": ..., "upper": ...}``, a flat mapping with keys such as ``v_l0``
        and ``v_u0``, or an array of shape ``(n_arms, 2)`` with control in the
        first row.
    control : mapping, optional
        Solver controls for general rectangles. ``gap_tol`` is the target
        optimality gap relative to the problem scale (default ``1e-9``).
        ``barrier=False`` skips the barrier Newton method and uses the search
        methods directly. ``max_starts``, ``smooth_taus``, ``maxit``, and
        ``mirror_iterations`` tune that fallback.
    max_vertices : int, default 65536
        Largest number of rectangle vertices to enumerate. The count doubles with
        every arm or cell.

    Returns
    -------
    CMRResult
        Result with shares ``pi`` by arm, the certificate ``U_CMR``, and solver
        ``diagnostics``. ``diagnostics["optimality_gap"]`` bounds how far ``U_CMR``
        can be from the minimax value.
    """

    problem = _multiarm_vertex_problem(rectangle, max_vertices=max_vertices)
    rect = problem["rect"]
    arms = problem["arms"]
    default_variances = {arm: 0.25 for arm in arms}
    default_start = np.asarray(
        list(assign_multiarm_neyman(default_variances).values()), dtype=float
    )

    if all(
        endpoints["lower"] == endpoints["upper"] for endpoints in rect.values()
    ):
        pi_dict = assign_multiarm_neyman({arm: rect[arm]["lower"] for arm in arms})
        pi_array = np.asarray([pi_dict[arm] for arm in arms], dtype=float)
        details = vertex_certificate(pi_array, problem["A"], problem["oracle"], True)
        solution = {
            "pi": pi_dict,
            "pi_array": pi_array,
            "value": details["value"],
            "vertex_regrets": details["vertex_regrets"],
            "active_vertices": details["active_vertices"],
            "diagnostics": {
                "solver": "collapsed_closed_form",
                "optimality_gap": 0.0,
                "directional_violation": 0.0,
                "converged": True,
            },
        }
    elif all(
        endpoints["lower"] == 0 and endpoints["upper"] == 0.25
        for endpoints in rect.values()
    ):
        pi_dict = assign_multiarm_neyman(default_variances)
        pi_array = np.asarray([pi_dict[arm] for arm in arms], dtype=float)
        details = vertex_certificate(pi_array, problem["A"], problem["oracle"], True)
        solution = {
            "pi": pi_dict,
            "pi_array": pi_array,
            "value": details["value"],
            "vertex_regrets": details["vertex_regrets"],
            "active_vertices": details["active_vertices"],
            "diagnostics": {
                "solver": "full_rectangle_closed_form",
                "optimality_gap": 0.0,
                "directional_violation": 0.0,
                "converged": True,
            },
        }
    else:
        control = {} if control is None else dict(control)
        control["component_names"] = arms
        solution = solve_vertex_epigraph(
            problem["A"],
            problem["oracle"],
            default_start=default_start,
            control=control,
        )

    full = all(
        endpoints["lower"] == 0 and endpoints["upper"] == 0.25
        for endpoints in rect.values()
    )
    collapsed = all(
        endpoints["lower"] == endpoints["upper"] for endpoints in rect.values()
    )
    diagnostics = dict(solution["diagnostics"])
    diagnostics.update({"K": len(arms) - 1, "full_rectangle": full, "collapsed_rectangle": collapsed})
    return CMRResult(
        pi=solution["pi"],
        u_cmr=float(solution["value"]),
        rectangle=rect,
        diagnostics=diagnostics,
        extra={
            "arms": arms,
            "vertices": problem["vertices"],
            "vertex_regrets": solution["vertex_regrets"],
            "binding_vertices": [
                problem["vertices"]["vertex_names"][i] for i in solution["active_vertices"]
            ],
        },
    )


def _split_multiarm_pilot(y, arm, control_arm=0, na_rm: bool = True) -> dict:
    y_arr = np.asarray(y, dtype=float)
    arm_arr = np.asarray(arm, dtype=object)
    if y_arr.shape[0] != arm_arr.shape[0]:
        cmr_error("`y` and `arm` must have the same length.")
    control_chr = canonical_label(control_arm)
    missing = np.isnan(y_arr) | np.asarray([label_missing(x) for x in arm_arr], dtype=bool)
    if np.any(missing):
        if not na_rm:
            cmr_error("`y` and `arm` cannot contain missing values when `na_rm=False`.")
        y_arr = y_arr[~missing]
        arm_arr = arm_arr[~missing]
    if y_arr.size == 0:
        cmr_error("The pilot has no observed rows.")
    if np.any(~np.isfinite(y_arr)):
        cmr_error("`y` must contain only finite values.")
    arm_chr = np.asarray([canonical_label(x) for x in arm_arr], dtype=object)
    if not np.any(arm_chr == control_chr):
        cmr_error("`arm` must include the control arm.")
    if not np.any(arm_chr != control_chr):
        cmr_error("`arm` must include at least one treatment arm.")
    if control_chr != "0" and np.any((arm_chr != control_chr) & (arm_chr == "0")):
        cmr_error("Treatment arm label `0` is reserved for the standardized control arm.")
    arm_std = np.where(arm_chr == control_chr, "0", arm_chr)
    arms = _arm_order(dict.fromkeys(arm_std))
    return {"y": y_arr, "arm": arm_std, "arms": arms, "control_arm": control_chr}


def _resolve_multiarm_beta(alpha: float, arms, beta=None) -> dict[str, dict[str, float]]:
    alpha = check_alpha(alpha)
    arms = list(arms)
    if beta is None:
        value = alpha / (2 * len(arms))
        out = {arm: {"lower": value, "upper": value} for arm in arms}
    elif isinstance(beta, Mapping):
        out = {}
        for arm in arms:
            if arm not in beta:
                cmr_error(f"`beta` is missing arm `{arm}`.")
            endpoints = beta[arm]
            if isinstance(endpoints, Mapping):
                out[arm] = {"lower": endpoints["lower"], "upper": endpoints["upper"]}
            else:
                value = float(as_numeric_array(endpoints, "beta").reshape(-1)[0])
                out[arm] = {"lower": value, "upper": value}
    else:
        value = float(as_numeric_array(beta, "beta").reshape(-1)[0])
        out = {arm: {"lower": value, "upper": value} for arm in arms}
    for arm in arms:
        for endpoint in ("lower", "upper"):
            value = float(as_numeric_array(out[arm][endpoint], "beta").reshape(-1)[0])
            if value < 0 or value >= 1:
                cmr_error("Every beta endpoint error must lie in [0, 1).")
            out[arm][endpoint] = value
    if sum(v[e] for v in out.values() for e in ("lower", "upper")) > alpha + 1e-12:
        cmr_error("`beta` allocates joint error above `alpha`.")
    return out


def rectangle_multiarm(
    y,
    arm,
    alpha: float = 0.05,
    method: str = "auto",
    beta=None,
    control_arm=0,
    normalize: bool = False,
    lower=None,
    upper=None,
    na_rm: bool = True,
    tol: float = 1e-11,
) -> RectangleResult:
    """Variance confidence intervals for every arm of a multi-arm pilot.

    Parameters
    ----------
    y : array_like
        Pilot outcomes, one entry per pilot unit. Bounded and Bernoulli methods
        need values in ``[0, 1]`` unless ``normalize=True``.
    arm : array_like
        Pilot arm labels, one per pilot unit. Any labels are accepted.
    alpha : float, default 0.05
        Joint error level of the variance confidence set.
    method : str, default "auto"
        Confidence-set method. ``"auto"`` uses exact Bernoulli bounds when the raw
        outcomes are all 0/1 and Maurer–Pontil bounds otherwise. ``"bounded"``,
        ``"maurer_pontil"``, and ``"mp"`` select Maurer–Pontil bounds.
        ``"bernoulli"`` and ``"bernoulli_exact"`` select exact folded-binomial
        bounds. ``"mtr"`` and ``"martinez_taboada_ramdas"`` select
        Martinez-Taboada–Ramdas bounds, which depend on the row order of the pilot.
    beta : float or mapping, optional
        One-sided endpoint errors. ``None`` splits ``alpha`` equally across the
        lower and upper endpoints of every arm. A float is used for every endpoint.
        A mapping from arm label to a float or to ``{"lower": ..., "upper": ...}``
        sets each arm.
    control_arm : label, default 0
        Label of the control arm in ``arm``. The control arm is reported as ``"0"``
        in the result.
    normalize : bool, default False
        If True, map outcomes to ``[0, 1]`` using ``lower`` and ``upper`` before
        computing variances. With ``method="auto"`` and raw 0/1 outcomes, exact
        Bernoulli bounds are used on the raw scale and normalization is skipped.
    lower, upper : float, optional
        Known support bounds used when ``normalize=True``. If either is omitted,
        the pilot minimum or maximum is used with a warning. That data-dependent
        normalization is exploratory and does not carry the finite-sample
        guarantee.
    na_rm : bool, default True
        If True, drop rows with missing values. If False, missing values raise an
        error.
    tol : float, default 1e-11
        Numerical tolerance for inverting the exact Bernoulli bounds.

    Returns
    -------
    RectangleResult
        Confidence rectangle with the endpoint error allocation ``beta``, the
        ``method`` used, pilot sample sizes ``n``, variance estimates ``vhat``, and
        the ``joint_error_bound``.
    """

    alpha = check_alpha(alpha)
    if is_unbounded_method(method):
        cmr_error(
            "`method='unbounded'` is only available for two-arm designs; "
            "use `cmr_unbounded()` or `cmr_two_arm(..., method='unbounded')`."
        )
    pilot = _split_multiarm_pilot(y, arm, control_arm=control_arm, na_rm=na_rm)
    pilot["y"], resolved_method, normalization = prepare_outcome_scale(
        pilot["y"],
        method,
        normalize=normalize,
        lower=lower,
        upper=upper,
    )
    pilot["y"] = clean_outcome_01(pilot["y"])
    beta_out = _resolve_multiarm_beta(alpha, pilot["arms"], beta=beta)

    arm_results = {}
    rectangle = {}
    n = {}
    vhat = {}
    for arm_label in pilot["arms"]:
        y_arm = pilot["y"][pilot["arm"] == arm_label]
        shown_label = pilot["control_arm"] if arm_label == "0" else arm_label
        with error_context(f"Arm `{shown_label}`"):
            result = variance_bounds_by_method(
                y_arm,
                beta_l=beta_out[arm_label]["lower"],
                beta_u=beta_out[arm_label]["upper"],
                method=resolved_method,
                tol=tol,
            )
        arm_results[arm_label] = result
        rectangle[arm_label] = {"lower": result["L"], "upper": result["U"]}
        n[arm_label] = int(result["n"])
        vhat[arm_label] = float(result["vhat"])

    return RectangleResult(
        rectangle=check_multiarm_rectangle(rectangle),
        alpha=alpha,
        beta=beta_out,
        method=resolved_method,
        n=n,
        vhat=vhat,
        joint_error_bound=sum(v[e] for v in beta_out.values() for e in ("lower", "upper")),
        diagnostics={"normalization": normalization},
        extra={
            "arms": pilot["arms"],
            "arm_results": arm_results,
            "normalization": normalization,
            "control_arm": pilot["control_arm"],
        },
    )


def cmr_multiarm(
    y,
    arm,
    alpha: float = 0.05,
    method: str = "auto",
    beta=None,
    control_arm=0,
    normalize: bool = False,
    lower=None,
    upper=None,
    na_rm: bool = True,
    tol: float = 1e-11,
    solver_control: Mapping | None = None,
    max_vertices: int = 65536,
) -> CMRResult:
    """Conditional Minimax Regret allocation for several treatments and one control.

    Builds a variance confidence interval for every arm from the pilot and returns
    the allocation that minimizes the worst regret over the resulting rectangle.

    Parameters
    ----------
    y : array_like
        Pilot outcomes, one entry per pilot unit. Bounded and Bernoulli methods
        need values in ``[0, 1]`` unless ``normalize=True``.
    arm : array_like
        Pilot arm labels, one per pilot unit. Any labels are accepted.
    alpha : float, default 0.05
        Joint error level of the variance confidence set.
    method : str, default "auto"
        Confidence-set method. ``"auto"`` uses exact Bernoulli bounds when the raw
        outcomes are all 0/1 and Maurer–Pontil bounds otherwise. ``"bounded"``,
        ``"maurer_pontil"``, and ``"mp"`` select Maurer–Pontil bounds.
        ``"bernoulli"`` and ``"bernoulli_exact"`` select exact folded-binomial
        bounds. ``"mtr"`` and ``"martinez_taboada_ramdas"`` select
        Martinez-Taboada–Ramdas bounds, which depend on the row order of the pilot.
    beta : float or mapping, optional
        One-sided endpoint errors. ``None`` splits ``alpha`` equally across the
        lower and upper endpoints of every arm. A float is used for every endpoint.
        A mapping from arm label to a float or to ``{"lower": ..., "upper": ...}``
        sets each arm.
    control_arm : label, default 0
        Label of the control arm in ``arm``. The control arm is reported as ``"0"``
        in the result.
    normalize : bool, default False
        If True, map outcomes to ``[0, 1]`` using ``lower`` and ``upper`` before
        computing variances. With ``method="auto"`` and raw 0/1 outcomes, exact
        Bernoulli bounds are used on the raw scale and normalization is skipped.
    lower, upper : float, optional
        Known support bounds used when ``normalize=True``. If either is omitted,
        the pilot minimum or maximum is used with a warning. That data-dependent
        normalization is exploratory and does not carry the finite-sample
        guarantee.
    na_rm : bool, default True
        If True, drop rows with missing values. If False, missing values raise an
        error.
    tol : float, default 1e-11
        Numerical tolerance for inverting the exact Bernoulli bounds.
    solver_control : mapping, optional
        Solver controls for general rectangles. ``gap_tol`` is the target
        optimality gap relative to the problem scale (default ``1e-9``).
        ``barrier=False`` skips the barrier Newton method and uses the search
        methods directly. ``max_starts``, ``smooth_taus``, ``maxit``, and
        ``mirror_iterations`` tune that fallback.
    max_vertices : int, default 65536
        Largest number of rectangle vertices to enumerate. The count doubles with
        every arm or cell.

    Returns
    -------
    CMRResult
        Result with shares ``pi`` by arm (control is ``"0"``), the certificate
        ``U_CMR``, the ``confidence_set``, pilot summaries, and ``diagnostics``.

    Examples
    --------
    >>> import numpy as np
    >>> import cmrdesign as cmr
    >>> rng = np.random.default_rng(5)
    >>> arm = np.repeat(["control", "variant_a", "variant_b"], 200)
    >>> y = np.r_[rng.beta(8, 8, 200), rng.beta(0.5, 0.5, 200), rng.beta(2, 2, 200)]
    >>> fit = cmr.cmr_multiarm(y, arm, control_arm="control")
    >>> list(fit.pi)
    ['0', 'variant_a', 'variant_b']
    """

    confidence_set = rectangle_multiarm(
        y=y,
        arm=arm,
        alpha=alpha,
        method=method,
        beta=beta,
        control_arm=control_arm,
        normalize=normalize,
        lower=lower,
        upper=upper,
        na_rm=na_rm,
        tol=tol,
    )
    out = cmr_multiarm_from_rectangle(
        confidence_set.rectangle,
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
    out.extra["arms"] = confidence_set.extra["arms"]
    out.extra["control_arm"] = confidence_set.extra["control_arm"]
    return out
