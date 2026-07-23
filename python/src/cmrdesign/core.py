"""Core variance, oracle, Neyman, and regret helpers."""

from __future__ import annotations

import numpy as np

from .validation import check_probability, check_variance


def _maybe_scalar(x):
    arr = np.asarray(x)
    return float(arr.reshape(-1)[0]) if arr.size == 1 else arr


def variance_objective(pi, v1, v0):
    pi = check_probability(pi, "pi", allow_boundary=True)
    v1 = check_variance(v1, "v1")
    v0 = check_variance(v0, "v0")
    pi, v1, v0 = np.broadcast_arrays(pi, v1, v0)
    out = np.empty_like(pi, dtype=float)
    interior = (pi > 0) & (pi < 1)
    out[interior] = v1[interior] / pi[interior] + v0[interior] / (1 - pi[interior])
    left = pi == 0
    out[left] = np.where(v1[left] > 0, np.inf, v0[left])
    right = pi == 1
    out[right] = np.where(v0[right] > 0, np.inf, v1[right])
    return _maybe_scalar(out)


def oracle_variance(v1, v0):
    v1 = check_variance(v1, "v1")
    v0 = check_variance(v0, "v0")
    v1, v0 = np.broadcast_arrays(v1, v0)
    return _maybe_scalar((np.sqrt(v1) + np.sqrt(v0)) ** 2)


def assign_neyman(v1, v0):
    v1 = check_variance(v1, "v1")
    v0 = check_variance(v0, "v0")
    v1, v0 = np.broadcast_arrays(v1, v0)
    s1 = np.sqrt(v1)
    s0 = np.sqrt(v0)
    denom = s1 + s0
    out = np.full_like(denom, 0.5, dtype=float)
    np.divide(s1, denom, out=out, where=denom > 0)
    return _maybe_scalar(out)


def regret(pi, v1, v0):
    pi = check_probability(pi, "pi", allow_boundary=True)
    v1 = check_variance(v1, "v1")
    v0 = check_variance(v0, "v0")
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
