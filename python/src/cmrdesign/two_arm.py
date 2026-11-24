"""Two-arm CMR public API and CMR-from-rectangle helper."""

from __future__ import annotations

import math

from .core import regret
from .rectangles import check_binary_rectangle, rectangle_two_arm
from .results import CMRResult
from .unbounded import (
    check_unbounded_method_options,
    cmr_unbounded,
    is_unbounded_method,
)


def binary_rectangle_corners(rectangle) -> dict[str, dict[str, float]]:
    """Corners of a two-arm rectangle where regret is largest.

    For any treatment share, the worst regret over the rectangle is attained at one
    of the two off-diagonal corners.

    Parameters
    ----------
    rectangle : mapping or array_like
        Two-arm variance rectangle with entries ``v_l1``, ``v_u1``, ``v_l0``,
        ``v_u0``, or a result object that holds one.

    Returns
    -------
    dict
        The corners ``treatment_high_control_low`` and
        ``treatment_low_control_high``, each with entries ``v1`` and ``v0``.
    """

    rect = check_binary_rectangle(rectangle)
    return {
        "treatment_high_control_low": {"v1": rect["v_u1"], "v0": rect["v_l0"]},
        "treatment_low_control_high": {"v1": rect["v_l1"], "v0": rect["v_u0"]},
    }


def binary_rectangle_regret(pi: float, rectangle, return_details: bool = False):
    """Worst regret of a treatment share over a two-arm rectangle.

    Parameters
    ----------
    pi : float or array_like
        Treatment share of the main wave, in ``[0, 1]``.
    rectangle : mapping or array_like
        Two-arm variance rectangle with entries ``v_l1``, ``v_u1``, ``v_l0``,
        ``v_u0``, or a result object that holds one.
    return_details : bool, default False
        If True, also return the regret at each corner and which corner binds.

    Returns
    -------
    float or dict
        The worst regret, or a dict with ``value``, ``corner_regrets``,
        ``binding``, and ``corners``.
    """

    rect = check_binary_rectangle(rectangle)
    corners = binary_rectangle_corners(rect)
    regret_plus = float(
        regret(
            pi,
            corners["treatment_high_control_low"]["v1"],
            corners["treatment_high_control_low"]["v0"],
        )
    )
    regret_minus = float(
        regret(
            pi,
            corners["treatment_low_control_high"]["v1"],
            corners["treatment_low_control_high"]["v0"],
        )
    )
    value = max(regret_plus, regret_minus)
    if not return_details:
        return value
    if math.isclose(regret_plus, regret_minus, rel_tol=0, abs_tol=1e-10):
        binding = "both"
    elif regret_plus > regret_minus:
        binding = "treatment_high_control_low"
    else:
        binding = "treatment_low_control_high"
    return {
        "value": value,
        "corner_regrets": {
            "treatment_high_control_low": regret_plus,
            "treatment_low_control_high": regret_minus,
        },
        "binding": binding,
        "corners": corners,
    }


def cmr_two_arm_from_rectangle(rectangle) -> CMRResult:
    """Two-arm CMR allocation for a given variance rectangle.

    The allocation is the Neyman rule applied to the midpoints of the two
    standard-deviation intervals. It equalizes regret at the two off-diagonal
    corners of the rectangle.

    Parameters
    ----------
    rectangle : mapping or array_like
        Two-arm variance rectangle with entries ``v_l1``, ``v_u1``, ``v_l0``,
        ``v_u0``, or a result object that holds one.

    Returns
    -------
    CMRResult
        Result with the treatment share ``pi``, the certificate ``U_CMR``, and the
        binding corners in ``extra``.

    Examples
    --------
    >>> import cmrdesign as cmr
    >>> fit = cmr.cmr_two_arm_from_rectangle({"v_l1": 0.04, "v_u1": 0.16, "v_l0": 0.01, "v_u0": 0.09})
    >>> round(fit.pi, 4)
    0.6
    """

    rect = check_binary_rectangle(rectangle)
    s_l1 = math.sqrt(rect["v_l1"])
    s_u1 = math.sqrt(rect["v_u1"])
    s_l0 = math.sqrt(rect["v_l0"])
    s_u0 = math.sqrt(rect["v_u0"])
    score_treatment = s_u1 + s_l1
    score_control = s_u0 + s_l0
    score_total = score_treatment + score_control
    pi = score_treatment / score_total if score_total > 0 else 0.5

    cert = binary_rectangle_regret(pi, rect, return_details=True)
    collapsed = rect["v_l1"] == rect["v_u1"] and rect["v_l0"] == rect["v_u0"]
    full = (
        rect["v_l1"] == 0
        and rect["v_l0"] == 0
        and rect["v_u1"] == 0.25
        and rect["v_u0"] == 0.25
    )
    return CMRResult(
        pi=float(pi),
        u_cmr=float(cert["value"]),
        rectangle=rect,
        diagnostics={
            "score_treatment": score_treatment,
            "score_control": score_control,
            "full_rectangle": full,
            "collapsed_rectangle": collapsed,
        },
        extra={
            "corners": cert["corners"],
            "corner_regrets": cert["corner_regrets"],
            "binding": cert["binding"],
        },
    )


def cmr_two_arm(
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
) -> CMRResult:
    """Conditional Minimax Regret treatment share for a two-arm design.

    Builds a finite-sample confidence rectangle for the two arm variances from the
    pilot and returns the treatment share that minimizes the worst regret over that
    rectangle, together with that worst regret as a certificate.

    Parameters
    ----------
    y : array_like
        Pilot outcomes, one entry per pilot unit. Bounded and Bernoulli methods
        need values in ``[0, 1]`` unless ``normalize=True``.
    d : array_like
        Pilot treatment indicator, with ``1`` for treatment and ``0`` for control.
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
    psi : float or pair of floats, optional
        Kurtosis bound, required only when ``method`` selects the unbounded-outcome
        extension.
    na_rm : bool, default True
        If True, drop rows with missing values. If False, missing values raise an
        error.
    tol : float, default 1e-11
        Numerical tolerance for inverting the exact Bernoulli bounds.

    Returns
    -------
    CMRResult
        Result with the treatment share ``pi``, the certificate ``U_CMR``, the
        variance ``rectangle``, the ``confidence_set`` it came from, pilot
        summaries in ``pilot``, and ``diagnostics``.

    Notes
    -----
    A small pilot cannot rule out any variance pair. The rectangle is then all of
    ``[0, 1/4] x [0, 1/4]`` and the result is the balanced design, ``pi = 0.5``
    with ``U_CMR = 0.25``.

    Examples
    --------
    >>> import numpy as np
    >>> import cmrdesign as cmr
    >>> rng = np.random.default_rng(1)
    >>> d = np.repeat([1, 0], 200)
    >>> y = np.r_[rng.beta(0.5, 0.5, 200), rng.beta(8, 8, 200)]
    >>> fit = cmr.cmr_two_arm(y, d)
    >>> 0.5 < fit.pi < 1.0
    True
    >>> fit.U_CMR < 0.25
    True
    """

    if is_unbounded_method(method):
        check_unbounded_method_options(
            beta=beta,
            correction=correction,
            normalize=normalize,
            lower=lower,
            upper=upper,
        )
        return cmr_unbounded(
            y=y,
            d=d,
            psi=psi,
            alpha=alpha,
            na_rm=na_rm,
        )

    confidence_set = rectangle_two_arm(
        y=y,
        d=d,
        alpha=alpha,
        method=method,
        beta=beta,
        correction=correction,
        normalize=normalize,
        lower=lower,
        upper=upper,
        psi=psi,
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
    }
    out.alpha = confidence_set.alpha
    out.beta = confidence_set.beta
    out.method = confidence_set.method
    out.joint_error_bound = confidence_set.joint_error_bound
    out.diagnostics["confidence_method"] = confidence_set.method
    out.diagnostics["joint_error_bound"] = confidence_set.joint_error_bound
    out.correction = confidence_set.extra.get("correction")
    out.extra["correction"] = out.correction
    return out


cmr_binary_from_rectangle = cmr_two_arm_from_rectangle
cmr_binary = cmr_two_arm
