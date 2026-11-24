"""Core variance, oracle, Neyman, and regret helpers."""

from __future__ import annotations

import numpy as np

from .validation import check_probability, check_scale, check_variance


def _maybe_scalar(x):
    arr = np.asarray(x)
    return float(arr.reshape(-1)[0]) if arr.size == 1 else arr


def variance_objective(pi, v1, v0, scale: str = "unit"):
    """Variance objective of a two-arm design.

    Returns ``v1 / pi + v0 / (1 - pi)``, the variance of the difference in means up
    to the factor ``1 / n``.

    Parameters
    ----------
    pi : float or array_like
        Treatment share of the main wave, in ``[0, 1]``.
    v1 : float or array_like
        Treatment-arm outcome variance.
    v0 : float or array_like
        Control-arm outcome variance.
    scale : {"unit", "nonnegative"}, default "unit"
        Variance scale. ``"unit"`` requires variances in ``[0, 1/4]``, the feasible
        range for outcomes in ``[0, 1]``. ``"nonnegative"`` accepts any finite
        nonnegative variance, as needed to audit :func:`cmr_unbounded` results or a
        raw Maurer–Pontil sample variance above ``1/4``.

    Returns
    -------
    float or ndarray
        The objective, after NumPy broadcasting of the inputs. It is infinite when
        an arm with positive variance receives no units.
    """

    scale = check_scale(scale)
    pi = check_probability(pi, "pi", allow_boundary=True)
    v1 = check_variance(v1, "v1", scale=scale)
    v0 = check_variance(v0, "v0", scale=scale)
    pi, v1, v0 = np.broadcast_arrays(pi, v1, v0)
    out = np.empty_like(pi, dtype=float)
    interior = (pi > 0) & (pi < 1)
    out[interior] = v1[interior] / pi[interior] + v0[interior] / (1 - pi[interior])
    left = pi == 0
    out[left] = np.where(v1[left] > 0, np.inf, v0[left])
    right = pi == 1
    out[right] = np.where(v0[right] > 0, np.inf, v1[right])
    return _maybe_scalar(out)


def oracle_variance(v1, v0, scale: str = "unit"):
    """Smallest two-arm variance objective at known variances.

    Returns ``(sqrt(v1) + sqrt(v0)) ** 2``, the value of the objective at the
    Neyman allocation.

    Parameters
    ----------
    v1 : float or array_like
        Treatment-arm outcome variance.
    v0 : float or array_like
        Control-arm outcome variance.
    scale : {"unit", "nonnegative"}, default "unit"
        Variance scale. ``"unit"`` requires variances in ``[0, 1/4]``, the feasible
        range for outcomes in ``[0, 1]``. ``"nonnegative"`` accepts any finite
        nonnegative variance, as needed to audit :func:`cmr_unbounded` results or a
        raw Maurer–Pontil sample variance above ``1/4``.

    Returns
    -------
    float or ndarray
        The oracle value.
    """

    scale = check_scale(scale)
    v1 = check_variance(v1, "v1", scale=scale)
    v0 = check_variance(v0, "v0", scale=scale)
    v1, v0 = np.broadcast_arrays(v1, v0)
    return _maybe_scalar((np.sqrt(v1) + np.sqrt(v0)) ** 2)


def assign_neyman(v1, v0, scale: str = "unit"):
    """Neyman allocation at known variances.

    Returns ``sqrt(v1) / (sqrt(v1) + sqrt(v0))``, and ``0.5`` when both variances
    are zero.

    Parameters
    ----------
    v1 : float or array_like
        Treatment-arm outcome variance.
    v0 : float or array_like
        Control-arm outcome variance.
    scale : {"unit", "nonnegative"}, default "unit"
        Variance scale. ``"unit"`` requires variances in ``[0, 1/4]``, the feasible
        range for outcomes in ``[0, 1]``. ``"nonnegative"`` accepts any finite
        nonnegative variance, as needed to audit :func:`cmr_unbounded` results or a
        raw Maurer–Pontil sample variance above ``1/4``.

    Returns
    -------
    float or ndarray
        The treatment share that minimizes the variance objective.
    """

    scale = check_scale(scale)
    v1 = check_variance(v1, "v1", scale=scale)
    v0 = check_variance(v0, "v0", scale=scale)
    v1, v0 = np.broadcast_arrays(v1, v0)
    s1 = np.sqrt(v1)
    s0 = np.sqrt(v0)
    denom = s1 + s0
    out = np.full_like(denom, 0.5, dtype=float)
    np.divide(s1, denom, out=out, where=denom > 0)
    return _maybe_scalar(out)


def regret(pi, v1, v0, scale: str = "unit"):
    """Regret of a treatment share at known variances.

    Regret is the variance objective at ``pi`` minus its oracle value. For interior
    ``pi`` it equals ``((1 - pi) * sqrt(v1) - pi * sqrt(v0)) ** 2 / (pi * (1 -
    pi))``.

    Parameters
    ----------
    pi : float or array_like
        Treatment share of the main wave, in ``[0, 1]``.
    v1 : float or array_like
        Treatment-arm outcome variance.
    v0 : float or array_like
        Control-arm outcome variance.
    scale : {"unit", "nonnegative"}, default "unit"
        Variance scale. ``"unit"`` requires variances in ``[0, 1/4]``, the feasible
        range for outcomes in ``[0, 1]``. ``"nonnegative"`` accepts any finite
        nonnegative variance, as needed to audit :func:`cmr_unbounded` results or a
        raw Maurer–Pontil sample variance above ``1/4``.

    Returns
    -------
    float or ndarray
        Nonnegative regret. It is zero at the Neyman allocation.

    Examples
    --------
    >>> import cmrdesign as cmr
    >>> round(cmr.regret(0.5, 0.20, 0.05), 6)
    0.05
    >>> cmr.regret(0.5, 4.0, 1.0, scale="nonnegative")
    1.0
    """

    scale = check_scale(scale)
    pi = check_probability(pi, "pi", allow_boundary=True)
    v1 = check_variance(v1, "v1", scale=scale)
    v0 = check_variance(v0, "v0", scale=scale)
    pi, v1, v0 = np.broadcast_arrays(pi, v1, v0)
    out = np.empty_like(pi, dtype=float)
    interior = (pi > 0) & (pi < 1)
    s1 = np.sqrt(v1[interior])
    s0 = np.sqrt(v0[interior])
    imbalance = (1 - pi[interior]) * s1 - pi[interior] * s0
    out[interior] = imbalance**2 / (pi[interior] * (1 - pi[interior]))
    left = pi == 0
    out[left] = np.where(v1[left] > 0, np.inf, 0)
    right = pi == 1
    out[right] = np.where(v0[right] > 0, np.inf, 0)
    return _maybe_scalar(out)
