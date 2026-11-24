"""Proxy/delayed-outcome CMR wrappers."""

from __future__ import annotations

import math
from collections.abc import Mapping

from .rectangles import _binary_rectangle_result, rectangle_two_arm
from .results import CMRResult, RectangleResult
from .two_arm import cmr_two_arm_from_rectangle
from .unbounded import is_unbounded_method
from .validation import as_numeric_array, cmr_error


def check_zeta_pair(zeta) -> dict[str, float]:
    if isinstance(zeta, Mapping):
        if "1" in zeta and "0" in zeta:
            out = {"1": zeta["1"], "0": zeta["0"]}
        elif "treatment" in zeta and "control" in zeta:
            out = {"1": zeta["treatment"], "0": zeta["control"]}
        else:
            cmr_error("`zeta` mappings need keys '1'/'0' or 'treatment'/'control'.")
    else:
        arr = as_numeric_array(zeta, "zeta").reshape(-1)
        if arr.size == 1:
            out = {"1": arr[0], "0": arr[0]}
        elif arr.size == 2:
            out = {"1": arr[0], "0": arr[1]}
        else:
            cmr_error("`zeta` must be a scalar or length-two treatment/control vector.")
    out = {key: float(value) for key, value in out.items()}
    if any(value < 0 for value in out.values()):
        cmr_error("`zeta` must be nonnegative.")
    return out


def widen_sd_interval(v_l: float, v_u: float, zeta: float) -> dict[str, float]:
    s_l = math.sqrt(v_l)
    s_u = math.sqrt(v_u)
    return {
        "lower": max(0.0, s_l - zeta) ** 2,
        "upper": min(0.5, s_u + zeta) ** 2,
    }


def rectangle_proxy(
    proxy_y,
    d,
    zeta,
    alpha: float = 0.05,
    method: str = "auto",
    beta=None,
    correction: str = "bonferroni",
    normalize: bool = False,
    lower=None,
    upper=None,
    na_rm: bool = True,
    tol: float = 1e-11,
) -> RectangleResult:
    """Two-arm confidence rectangle for a primary outcome observed through a proxy.

    The proxy standard-deviation interval of each arm is widened by ``zeta`` on
    both sides, clipped to ``[0, 1/2]``, and squared.

    Parameters
    ----------
    proxy_y : array_like
        Pilot proxy or short-run outcomes, one entry per pilot unit.
    d : array_like
        Pilot treatment indicator, with ``1`` for treatment and ``0`` for control.
    zeta : float, pair of floats, or mapping
        Bridge constant: a bound on the absolute difference between the standard
        deviations of the primary and the proxy outcome in each arm. A single value
        applies to both arms.
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
        One-sided endpoint errors. ``None`` splits ``alpha`` according to
        ``correction``. A float is used for all four endpoints. A mapping with keys
        ``beta_l1``, ``beta_u1``, ``beta_l0``, ``beta_u0`` sets each endpoint
        separately.
    correction : {"bonferroni", "sidak_arms"}, default "bonferroni"
        How ``alpha`` is split across endpoints. ``"sidak_arms"`` uses the
        independence of the two arms and gives slightly larger endpoint errors.
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
        Rectangle for the primary outcome. The proxy rectangle is kept in
        ``extra["proxy_confidence_set"]``.
    """

    zeta = check_zeta_pair(zeta)
    if is_unbounded_method(method):
        cmr_error("The proxy bridge supports bounded-outcome methods only.")
    proxy_set = rectangle_two_arm(
        y=proxy_y,
        d=d,
        alpha=alpha,
        method=method,
        beta=beta,
        correction=correction,
        normalize=normalize,
        lower=lower,
        upper=upper,
        na_rm=na_rm,
        tol=tol,
    )
    treatment = widen_sd_interval(
        proxy_set.rectangle["v_l1"],
        proxy_set.rectangle["v_u1"],
        zeta["1"],
    )
    control = widen_sd_interval(
        proxy_set.rectangle["v_l0"],
        proxy_set.rectangle["v_u0"],
        zeta["0"],
    )
    rectangle = {
        "v_l1": treatment["lower"],
        "v_u1": treatment["upper"],
        "v_l0": control["lower"],
        "v_u0": control["upper"],
    }
    treatment_result = dict(proxy_set.extra["treatment"])
    control_result = dict(proxy_set.extra["control"])
    treatment_result.update(
        {
            "L_proxy": proxy_set.rectangle["v_l1"],
            "U_proxy": proxy_set.rectangle["v_u1"],
            "L": rectangle["v_l1"],
            "U": rectangle["v_u1"],
        }
    )
    control_result.update(
        {
            "L_proxy": proxy_set.rectangle["v_l0"],
            "U_proxy": proxy_set.rectangle["v_u0"],
            "L": rectangle["v_l0"],
            "U": rectangle["v_u0"],
        }
    )
    out = _binary_rectangle_result(
        rectangle=rectangle,
        treatment=treatment_result,
        control=control_result,
        alpha=proxy_set.alpha,
        beta=proxy_set.beta,
        correction=proxy_set.extra["correction"],
        method=f"proxy_{proxy_set.method}",
        normalization=proxy_set.extra.get("normalization"),
    )
    out.extra["proxy_confidence_set"] = proxy_set
    out.extra["zeta"] = zeta
    out.extra["bridge"] = {
        "assumption": "abs(primary_sd - proxy_sd) <= zeta by arm",
        "proxy_rectangle": proxy_set.rectangle,
        "primary_rectangle": rectangle,
    }
    out.diagnostics["bridge"] = out.extra["bridge"]["assumption"]
    return out


def cmr_proxy(
    proxy_y,
    d,
    zeta,
    alpha: float = 0.05,
    method: str = "auto",
    beta=None,
    correction: str = "bonferroni",
    normalize: bool = False,
    lower=None,
    upper=None,
    na_rm: bool = True,
    tol: float = 1e-11,
) -> CMRResult:
    """Conditional Minimax Regret treatment share from a proxy or short-run outcome.

    Use this when the pilot observes a proxy for the primary outcome and the
    researcher can bound the difference between their standard deviations. The
    bound ``zeta`` is an assumption supplied by the researcher. It is not
    estimated.

    Parameters
    ----------
    proxy_y : array_like
        Pilot proxy or short-run outcomes, one entry per pilot unit.
    d : array_like
        Pilot treatment indicator, with ``1`` for treatment and ``0`` for control.
    zeta : float, pair of floats, or mapping
        Bridge constant: a bound on the absolute difference between the standard
        deviations of the primary and the proxy outcome in each arm. A single value
        applies to both arms.
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
        One-sided endpoint errors. ``None`` splits ``alpha`` according to
        ``correction``. A float is used for all four endpoints. A mapping with keys
        ``beta_l1``, ``beta_u1``, ``beta_l0``, ``beta_u0`` sets each endpoint
        separately.
    correction : {"bonferroni", "sidak_arms"}, default "bonferroni"
        How ``alpha`` is split across endpoints. ``"sidak_arms"`` uses the
        independence of the two arms and gives slightly larger endpoint errors.
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
    CMRResult
        Result with the allocation ``pi``, the certificate ``U_CMR``, the variance
        ``rectangle``, the ``confidence_set`` it came from, pilot summaries in
        ``pilot``, and ``diagnostics``.
    """

    confidence_set = rectangle_proxy(
        proxy_y=proxy_y,
        d=d,
        zeta=zeta,
        alpha=alpha,
        method=method,
        beta=beta,
        correction=correction,
        normalize=normalize,
        lower=lower,
        upper=upper,
        na_rm=na_rm,
        tol=tol,
    )
    out = cmr_two_arm_from_rectangle(confidence_set.rectangle)
    out.confidence_set = confidence_set
    out.pilot = {
        "n": confidence_set.n,
        "vhat": confidence_set.vhat,
        "method": confidence_set.method,
        "normalization": confidence_set.extra.get("normalization"),
        "zeta": confidence_set.extra.get("zeta"),
    }
    out.alpha = confidence_set.alpha
    out.beta = confidence_set.beta
    out.method = confidence_set.method
    out.joint_error_bound = confidence_set.joint_error_bound
    out.correction = confidence_set.extra.get("correction")
    out.extra["zeta"] = confidence_set.extra.get("zeta")
    out.extra["bridge"] = confidence_set.extra.get("bridge")
    out.diagnostics["confidence_method"] = confidence_set.method
    out.diagnostics["joint_error_bound"] = confidence_set.joint_error_bound
    out.diagnostics["bridge"] = confidence_set.extra["bridge"]["assumption"]
    return out


rectangle_delayed_outcome = rectangle_proxy
cmr_delayed_outcome = cmr_proxy
