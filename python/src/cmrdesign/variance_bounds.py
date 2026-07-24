"""Maurer-Pontil, MTR, and exact Bernoulli variance bounds."""

from __future__ import annotations

import math

import numpy as np

from .validation import (
    check_tail_error,
    clean_outcome_01,
    cmr_error,
    is_dummy,
    scalar_int,
    scalar_variance,
)


def _clean_bound_outcome_01(y, na_rm: bool = True) -> np.ndarray:
    try:
        arr = np.asarray(y, dtype=float)
    except (TypeError, ValueError) as exc:
        raise ValueError("`y` must be numeric.") from exc
    missing = np.isnan(arr)
    if np.any(missing):
        if not na_rm:
            cmr_error("`y` cannot contain missing values when `na_rm=False`.")
        arr = arr[~missing]
    return clean_outcome_01(arr)


def sample_variance_01(y, na_rm: bool = True) -> float:
    y = _clean_bound_outcome_01(y, na_rm=na_rm)
    if y.size < 2:
        cmr_error("At least two observations are required to estimate a variance.")
    return float(np.clip(np.var(y, ddof=1), 0, 0.25))


def variance_bounds_maurer_pontil(
    y,
    beta_l: float,
    beta_u: float,
    na_rm: bool = True,
) -> dict:
    beta_l = check_tail_error(beta_l, "beta_l")
    beta_u = check_tail_error(beta_u, "beta_u")
    y = _clean_bound_outcome_01(y, na_rm=na_rm)
    m = y.size
    if m < 2:
        cmr_error("At least two observations are required.")
    vhat = sample_variance_01(y, na_rm=False)
    sdhat = math.sqrt(vhat)
    if beta_l <= 0:
        lower = 0.0
    else:
        eta_l = math.sqrt(2 * math.log(1 / beta_l) / (m - 1))
        lower = max(0.0, sdhat - eta_l) ** 2
    if beta_u <= 0:
        upper = 0.25
    else:
        eta_u = math.sqrt(2 * math.log(1 / beta_u) / (m - 1))
        upper = (sdhat + eta_u) ** 2
    return {
        "L": float(np.clip(lower, 0, 0.25)),
        "U": float(np.clip(upper, 0, 0.25)),
        "vhat": vhat,
        "method": "bounded",
        "n": int(m),
        "statistic": {"vhat": vhat, "sdhat": sdhat, "beta_l": beta_l, "beta_u": beta_u},
    }


def _mtr_psi_e(lam: float) -> float:
    return -lam - math.log1p(-lam)


def _mtr_psi_p(lam: float) -> float:
    return math.exp(lam) - lam - 1


def _mtr_upper_variance(y, alpha, c1, c2, c3, c4, cs=False):
    n = len(y)
    sumvarhat = c2
    summuhat = c3
    tilde_summuhat = c4
    aux = math.sqrt(2 * math.log(1 / alpha))
    part1 = 0.0
    part2 = math.log(1 / alpha)
    sum_lambdas = 0.0
    sum_center = 0.0
    lambda_path = []
    center = math.nan
    bound_radius = math.nan
    for idx, val in enumerate(y, start=1):
        x = (val - tilde_summuhat / idx) ** 2
        radius = (x - summuhat / idx) ** 2
        denominator = math.sqrt(sumvarhat * math.log(idx + 1)) if cs else math.sqrt(sumvarhat * n / idx)
        lam = min(aux / denominator, c1)
        lambda_path.append(lam)
        sum_lambdas += lam
        sum_center += lam * x
        center = sum_center / sum_lambdas
        part1 += radius * _mtr_psi_e(lam)
        bound_radius = (part1 + part2) / sum_lambdas
        summuhat += x
        sumvarhat += radius
        tilde_summuhat += val
    return {
        "center": center,
        "radius": bound_radius,
        "upper": center + bound_radius,
        "lambda_path": lambda_path,
    }


def _mtr_lower_variance(
    y,
    alpha_variance,
    alpha_mean,
    c1,
    c2,
    c3,
    c4,
    c5,
    cs=False,
    tilde_cs=True,
):
    n = len(y)
    sumvarhat = c2
    tilde_sumvarhat = c3
    tilde_summuhat = c4
    aux = math.sqrt(2 * math.log(1 / alpha_variance))
    part1 = 0.0
    part2 = math.log(1 / alpha_variance)
    sum_lambdas = 0.0
    sum_center = 0.0
    tilde_aux = math.sqrt(2 * math.log(2 / alpha_mean))
    tilde_center_sum = 0.0
    tilde_center = 0.0
    sum_psi_tilde_lambdas = 0.0
    sum_tilde_lambdas = 0.0
    sum_at = 0.0
    sum_bt = 0.0
    sum_ct = 0.0
    at = bt = ct = dt = rt = math.nan
    lambda_path = []
    tilde_lambda_path = []
    for idx, val in enumerate(y, start=1):
        x = (val - tilde_center) ** 2
        radius = (x - tilde_sumvarhat / idx) ** 2
        varhat = tilde_sumvarhat / idx
        lam = 0.0
        if sum_tilde_lambdas > 0:
            threshold = (math.log(2 / alpha_mean) + varhat * sum_psi_tilde_lambdas) / sum_tilde_lambdas
            if threshold < 1:
                denominator = math.sqrt(sumvarhat * math.log(idx + 1)) if cs else math.sqrt(sumvarhat * n / idx)
                lam = min(aux / denominator, c1)
        lambda_path.append(lam)
        sum_lambdas += lam
        sum_center += lam * x
        part1 += radius * _mtr_psi_e(lam)
        if sum_lambdas > 0:
            center = sum_center / sum_lambdas
            bound_radius = (part1 + part2) / sum_lambdas
        else:
            center = bound_radius = math.nan
        if lam > 0:
            tilde_at = sum_psi_tilde_lambdas**2 / sum_tilde_lambdas**2
            tilde_bt = 2 * math.log(2 / alpha_mean) * sum_psi_tilde_lambdas / sum_tilde_lambdas**2
            tilde_ct = math.log(2 / alpha_mean) ** 2 / sum_tilde_lambdas**2
            dt = center
            rt = bound_radius
            sum_at += tilde_at * lam
            at = sum_at / sum_lambdas
            sum_bt += tilde_bt * lam
            bt = 1 + sum_bt / sum_lambdas
            sum_ct += tilde_ct * lam
            ct = sum_ct / sum_lambdas
        tilde_radius = (val - tilde_summuhat / idx) ** 2
        tilde_denominator = (
            math.sqrt(tilde_sumvarhat * math.log(idx + 1))
            if tilde_cs
            else math.sqrt(tilde_sumvarhat * n / idx)
        )
        tilde_lam = min(tilde_aux / tilde_denominator, c5)
        tilde_lambda_path.append(tilde_lam)
        sum_tilde_lambdas += tilde_lam
        sum_psi_tilde_lambdas += _mtr_psi_p(tilde_lam)
        tilde_center_sum += tilde_lam * val
        tilde_center = tilde_center_sum / sum_tilde_lambdas
        sumvarhat += radius
        tilde_summuhat += val
        tilde_sumvarhat += tilde_radius
    lower = 0.0
    if all(math.isfinite(x) for x in (dt, rt, at)) and at > 0:
        c_term = dt - ct - rt
        if c_term > 0:
            lower = max((-bt + math.sqrt(bt**2 + 4 * at * c_term)) / (2 * at), 0.0)
    return {
        "center": dt,
        "radius": rt,
        "lower": lower,
        "at": at,
        "bt": bt,
        "ct": ct,
        "lambda_path": lambda_path,
        "tilde_lambda_path": tilde_lambda_path,
    }


def variance_bounds_martinez_taboada_ramdas(
    y,
    beta_l: float,
    beta_u: float,
    lower_alpha_split: float = 0.5,
    c1: float = 0.5,
    c2: float = 0.25**2,
    c3: float = 0.25,
    c4: float = 0.5,
    c5: float = 2,
    cs: bool = False,
    tilde_cs: bool = True,
    na_rm: bool = True,
) -> dict:
    beta_l = check_tail_error(beta_l, "beta_l")
    beta_u = check_tail_error(beta_u, "beta_u")
    y = _clean_bound_outcome_01(y, na_rm=na_rm)
    m = y.size
    if m < 2:
        cmr_error("At least two observations are required.")
    vhat = sample_variance_01(y, na_rm=False)
    upper_result = (
        {"center": math.nan, "radius": math.nan, "upper": 0.25}
        if beta_u <= 0
        else _mtr_upper_variance(y, beta_u, c1, c2, c3, c4, cs)
    )
    alpha_lower_variance = beta_l * lower_alpha_split
    alpha_lower_mean = beta_l * (1 - lower_alpha_split)
    lower_result = (
        {"center": math.nan, "radius": math.nan, "lower": 0.0, "at": math.nan, "bt": math.nan, "ct": math.nan}
        if beta_l <= 0
        else _mtr_lower_variance(
            y,
            alpha_lower_variance,
            alpha_lower_mean,
            c1,
            c2,
            c3,
            c4,
            c5,
            cs,
            tilde_cs,
        )
    )
    return {
        "L": float(np.clip(lower_result["lower"], 0, 0.25)),
        "U": float(np.clip(upper_result["upper"], 0, 0.25)),
        "vhat": vhat,
        "method": "martinez_taboada_ramdas",
        "n": int(m),
        "statistic": {
            "vhat": vhat,
            "beta_l": beta_l,
            "beta_u": beta_u,
            "alpha_lower_variance": alpha_lower_variance,
            "alpha_lower_mean": alpha_lower_mean,
            "raw_lower": lower_result["lower"],
            "raw_upper": upper_result["upper"],
            "upper_center": upper_result["center"],
            "upper_radius": upper_result["radius"],
            "lower_center": lower_result["center"],
            "lower_radius": lower_result["radius"],
        },
    }


def bernoulli_rho(v: float) -> float:
    v = scalar_variance(v, "v")
    if v >= 0.25:
        return 0.5
    disc = math.sqrt(max(0.0, 1 - 4 * v))
    return 2 * v / (1 + disc)


def folded_sample_variance(j: int, m: int) -> float:
    m = scalar_int(m, "m", lower=2)
    j = scalar_int(j, "j", lower=0)
    if j > math.floor(m / 2):
        cmr_error("`j` cannot exceed floor(m / 2).")
    return j * (m - j) / (m * (m - 1))


def folded_count(y, na_rm: bool = True) -> dict:
    y = _clean_bound_outcome_01(y, na_rm=na_rm)
    if not is_dummy(y):
        cmr_error("Bernoulli exact bounds require a 0/1 outcome.")
    m = y.size
    if m < 2:
        cmr_error("At least two observations are required.")
    x = int(np.sum(np.rint(y)))
    j = min(x, m - x)
    return {"j": int(j), "x": int(x), "m": int(m)}


def _binom_pmf(k: int, m: int, p: float) -> float:
    if p <= 0.0:
        return 1.0 if k == 0 else 0.0
    if p >= 1.0:
        return 1.0 if k == m else 0.0
    log_pmf = (
        math.lgamma(m + 1)
        - math.lgamma(k + 1)
        - math.lgamma(m - k + 1)
        + k * math.log(p)
        + (m - k) * math.log1p(-p)
    )
    return math.exp(log_pmf)


def folded_binomial_pmf(v: float, m: int) -> np.ndarray:
    v = scalar_variance(v, "v")
    m = scalar_int(m, "m", lower=2)
    rho = bernoulli_rho(v)
    j_values = np.arange(math.floor(m / 2) + 1)
    pmf = []
    for j in j_values:
        p_left = _binom_pmf(int(j), m, rho)
        p_right = 0.0 if 2 * j == m else _binom_pmf(m - int(j), m, rho)
        pmf.append(p_left + p_right)
    out = np.asarray(pmf, dtype=float)
    return out / np.sum(out)


def folded_binomial_tails(v: float, m: int) -> dict[str, np.ndarray]:
    pmf = folded_binomial_pmf(v, m)
    return {"lower": np.cumsum(pmf), "upper": np.cumsum(pmf[::-1])[::-1]}


def bernoulli_upper_bound(j: int, m: int, beta_u: float, tol: float = 1e-11) -> float:
    m = scalar_int(m, "m", lower=2)
    j = scalar_int(j, "j", lower=0)
    beta_u = check_tail_error(beta_u, "beta_u")
    if j > math.floor(m / 2):
        cmr_error("`j` cannot exceed floor(m / 2).")
    if beta_u <= 0:
        return 0.25

    def tail_at(v):
        return folded_binomial_tails(v, m)["lower"][j]

    if tail_at(0.25) > beta_u:
        return 0.25
    if tail_at(0) <= beta_u:
        return 0.0
    lo, hi = 0.0, 0.25
    while hi - lo > tol:
        mid = (lo + hi) / 2
        if tail_at(mid) > beta_u:
            lo = mid
        else:
            hi = mid
    return float(np.clip(hi, 0, 0.25))


def bernoulli_lower_bound(j: int, m: int, beta_l: float, tol: float = 1e-11) -> float:
    m = scalar_int(m, "m", lower=2)
    j = scalar_int(j, "j", lower=0)
    beta_l = check_tail_error(beta_l, "beta_l")
    if j > math.floor(m / 2):
        cmr_error("`j` cannot exceed floor(m / 2).")
    if beta_l <= 0:
        return 0.0

    def tail_at(v):
        return folded_binomial_tails(v, m)["upper"][j]

    if tail_at(0) > beta_l:
        return 0.0
    if tail_at(0.25) <= beta_l:
        return 0.25
    lo, hi = 0.0, 0.25
    while hi - lo > tol:
        mid = (lo + hi) / 2
        if tail_at(mid) > beta_l:
            hi = mid
        else:
            lo = mid
    return float(np.clip(lo, 0, 0.25))


def variance_bounds_bernoulli_exact(
    y,
    beta_l: float,
    beta_u: float,
    tol: float = 1e-11,
    na_rm: bool = True,
) -> dict:
    beta_l = check_tail_error(beta_l, "beta_l")
    beta_u = check_tail_error(beta_u, "beta_u")
    fc = folded_count(y, na_rm=na_rm)
    raw_vhat = folded_sample_variance(fc["j"], fc["m"])
    return {
        "L": bernoulli_lower_bound(fc["j"], fc["m"], beta_l, tol=tol),
        "U": bernoulli_upper_bound(fc["j"], fc["m"], beta_u, tol=tol),
        "vhat": float(np.clip(raw_vhat, 0, 0.25)),
        "method": "bernoulli",
        "n": fc["m"],
        "statistic": {**fc, "raw_sample_variance": raw_vhat, "beta_l": beta_l, "beta_u": beta_u},
    }


def variance_bounds_by_method(
    y,
    beta_l: float,
    beta_u: float,
    method: str,
    tol: float = 1e-11,
    na_rm: bool = True,
) -> dict:
    if method == "bernoulli":
        return variance_bounds_bernoulli_exact(y, beta_l, beta_u, tol=tol, na_rm=na_rm)
    if method == "martinez_taboada_ramdas":
        return variance_bounds_martinez_taboada_ramdas(y, beta_l, beta_u, na_rm=na_rm)
    if method == "bounded":
        return variance_bounds_maurer_pontil(y, beta_l, beta_u, na_rm=na_rm)
    cmr_error(f"Internal error: unknown variance-bound method '{method}'.")
