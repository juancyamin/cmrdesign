"""Integer allocation realization helpers."""

from __future__ import annotations

import math
import warnings
from collections.abc import Mapping
from dataclasses import dataclass, field
from typing import Any

import numpy as np

from .results import CMRResult, _format_compact, _format_scalar
from .solver import hyperrectangle_vertices, vertex_certificate
from .validation import as_numeric_array, cmr_error, scalar_int


@dataclass
class AllocationResult:
    """Executable integer allocation derived from target assignment shares."""

    counts: dict[str, int]
    shares: dict[str, float]
    pi: Any
    target_pi: Any
    n_main: int
    rounding: str = "largest_remainder"
    min_per_arm: int = 1
    continuous_U_CMR: float | None = None
    realized_U_CMR: float | None = None
    excess_U_CMR: float | None = None
    diagnostics: dict[str, Any] = field(default_factory=dict)

    def __repr__(self) -> str:
        parts = [
            f"counts={_format_compact(self.counts)}",
            f"n_main={self.n_main}",
        ]
        if self.realized_U_CMR is not None:
            parts.append(f"realized_U_CMR={_format_scalar(self.realized_U_CMR)}")
        return f"AllocationResult({', '.join(parts)})"


def _ordered_mapping_values(x: Mapping) -> tuple[list[str], np.ndarray]:
    labels = [str(key) for key in x]
    values = as_numeric_array(list(x.values()), "pi").reshape(-1)
    return labels, values


def _normalize_shares(values, labels, name: str = "pi") -> np.ndarray:
    shares = as_numeric_array(values, name).reshape(-1).astype(float)
    if len(labels) != shares.size:
        cmr_error("`pi` must have one share per label.")
    if np.any(shares < -1e-12):
        cmr_error("Assignment shares must be nonnegative.")
    shares = np.maximum(shares, 0)
    total = float(np.sum(shares))
    if total <= 0:
        cmr_error("Assignment shares must contain positive mass.")
    return shares / total


def _largest_remainder_counts(
    shares,
    labels,
    n_main: int,
    min_per_arm: int = 1,
) -> dict[str, int]:
    labels = [str(label) for label in labels]
    n_main = scalar_int(n_main, "n_main", lower=0)
    min_per_arm = scalar_int(min_per_arm, "min_per_arm", lower=0)
    shares = _normalize_shares(shares, labels)
    active = shares > 1e-12
    if n_main == 0:
        return dict(zip(labels, [0] * len(labels), strict=True))
    min_counts = np.where(active, min_per_arm, 0).astype(int)
    if int(np.sum(min_counts)) > n_main:
        cmr_error(
            "`n_main` is too small for `min_per_arm` and the positive target shares; "
            "increase `n_main` or set `min_per_arm=0`."
        )

    remaining = int(n_main - np.sum(min_counts))
    desired = np.maximum(n_main * shares - min_counts, 0)
    if remaining == 0:
        counts = min_counts
    else:
        weights = desired if float(np.sum(desired)) > 0 else shares
        exact = remaining * weights / float(np.sum(weights))
        extras = np.floor(exact).astype(int)
        leftover = int(remaining - np.sum(extras))
        if leftover > 0:
            order = sorted(
                range(len(labels)),
                key=lambda idx: (-(exact[idx] - extras[idx]), idx),
            )
            for idx in order[:leftover]:
                extras[idx] += 1
        counts = min_counts + extras
    out = dict(zip(labels, map(int, counts), strict=True))
    dropped = [
        label
        for label, is_active in zip(labels, active, strict=True)
        if is_active and out[label] == 0
    ]
    if dropped:
        warnings.warn(
            "Positive target shares received zero realized units: "
            + ", ".join(dropped)
            + ". Increase `n_main` or `min_per_arm` if every positive target "
            "share must be represented.",
            UserWarning,
            stacklevel=2,
        )
    return out


def _two_arm_regret(pi: float, v1: float, v0: float) -> float:
    v1 = max(float(v1), 0.0)
    v0 = max(float(v0), 0.0)
    if pi <= 0:
        return math.inf if v1 > 0 else 0.0
    if pi >= 1:
        return math.inf if v0 > 0 else 0.0
    s1 = math.sqrt(v1)
    s0 = math.sqrt(v0)
    imbalance = (1 - pi) * s1 - pi * s0
    return float((imbalance**2) / (pi * (1 - pi)))


def _two_arm_realized_certificate(rectangle, pi: float) -> dict[str, Any] | None:
    if rectangle is None:
        return None
    if hasattr(rectangle, "rectangle") and not isinstance(rectangle, Mapping):
        rectangle = rectangle.rectangle
    if isinstance(rectangle, Mapping) and "rectangle" in rectangle:
        rectangle = rectangle["rectangle"]
    if not isinstance(rectangle, Mapping):
        return None
    required = ("v_l1", "v_u1", "v_l0", "v_u0")
    if not all(key in rectangle for key in required):
        return None
    regret_plus = _two_arm_regret(pi, rectangle["v_u1"], rectangle["v_l0"])
    regret_minus = _two_arm_regret(pi, rectangle["v_l1"], rectangle["v_u0"])
    return {
        "value": max(regret_plus, regret_minus),
        "corner_regrets": {
            "treatment_high_control_low": regret_plus,
            "treatment_low_control_high": regret_minus,
        },
    }


def _multiarm_realized_certificate(fit: CMRResult, shares, max_vertices: int):
    from .multiarm import _multiarm_vertex_problem

    if fit.rectangle is None:
        return None
    problem = _multiarm_vertex_problem(fit.rectangle, max_vertices=max_vertices)
    pi = np.asarray([shares[arm] for arm in problem["arms"]], dtype=float)
    details = vertex_certificate(
        pi,
        problem["A"],
        problem["oracle"],
        return_details=True,
    )
    return {
        "value": float(details["value"]),
        "vertex_regrets": details["vertex_regrets"],
        "binding_vertices": [
            problem["vertices"]["vertex_names"][idx]
            for idx in details["active_vertices"]
        ],
    }


def _stratified_realized_certificate(fit: CMRResult, shares, max_vertices: int):
    from .stratified import check_stratified_rectangle

    rectangle = fit.rectangle
    if isinstance(rectangle, Mapping) and all(
        key in rectangle for key in ("lower", "upper", "cell_names", "weights")
    ):
        checked = rectangle
    else:
        strata_share = fit.extra.get("strata_share")
        if strata_share is None and isinstance(rectangle, Mapping):
            strata_share = rectangle.get("strata_share")
        if strata_share is None:
            return None
        checked = check_stratified_rectangle(rectangle, strata_share)
    vertices = hyperrectangle_vertices(
        checked["lower"],
        checked["upper"],
        names=checked["cell_names"],
        max_vertices=max_vertices,
    )
    A = vertices["vertices"] * np.asarray(checked["weights"], dtype=float).reshape(
        1,
        -1,
    )
    oracle = np.sum(np.sqrt(A), axis=1) ** 2
    pi = np.asarray([shares[cell] for cell in checked["cell_names"]], dtype=float)
    details = vertex_certificate(pi, A, oracle, return_details=True)
    return {
        "value": float(details["value"]),
        "vertex_regrets": details["vertex_regrets"],
        "binding_vertices": [
            vertices["vertex_names"][idx] for idx in details["active_vertices"]
        ],
    }


def _continuous_certificate(fit) -> float | None:
    if isinstance(fit, CMRResult):
        return float(fit.U_CMR)
    return None


def _excess(realized, continuous):
    if realized is None or continuous is None:
        return None
    if math.isinf(realized) and math.isfinite(continuous):
        return math.inf
    if not math.isfinite(realized) or not math.isfinite(continuous):
        return None
    return float(realized - continuous)


def _is_stratified_target(labels) -> bool:
    return all(":" in str(label) for label in labels)


def _realize_vector(
    labels,
    shares,
    n_main,
    min_per_arm,
) -> tuple[dict[str, int], dict[str, float]]:
    counts = _largest_remainder_counts(shares, labels, n_main, min_per_arm=min_per_arm)
    n_total = sum(counts.values())
    if n_total <= 0:
        cmr_error("`n_main` must contain at least one main-wave unit.")
    realized = {label: count / n_total for label, count in counts.items()}
    return counts, realized


def _realize_stratified_counts(target, strata_counts, min_per_arm):
    target = {str(key): float(value) for key, value in target.items()}
    strata = []
    for key in target:
        if ":" not in key:
            cmr_error("Stratified targets must use cell labels like '1:A' and '0:A'.")
        stratum = key.split(":", 1)[1]
        if stratum not in strata:
            strata.append(stratum)
    if not isinstance(strata_counts, Mapping):
        cmr_error("`strata_counts` must be a mapping from stratum label to count.")
    stratum_count_labels = [str(key) for key in strata_counts]
    if len(set(stratum_count_labels)) != len(stratum_count_labels):
        cmr_error("`strata_counts` labels must be unique after string conversion.")
    extra_strata = [label for label in stratum_count_labels if label not in strata]
    if extra_strata:
        cmr_error(
            "`strata_counts` contains unknown strata: "
            + ", ".join(extra_strata)
            + "."
        )
    stratum_counts = {
        str(key): value for key, value in strata_counts.items()
    }
    counts: dict[str, int] = {}
    for stratum in strata:
        if stratum not in stratum_counts:
            cmr_error(f"`strata_counts` is missing stratum `{stratum}`.")
        n_stratum = scalar_int(
            stratum_counts[stratum],
            f"strata_counts[{stratum!r}]",
            lower=0,
        )
        labels_in_stratum = [
            label for label in target if label.split(":", 1)[1] == stratum
        ]
        labels = [f"1:{stratum}", f"0:{stratum}"]
        extra_cells = [label for label in labels_in_stratum if label not in labels]
        if extra_cells:
            cmr_error(
                "`strata_counts` currently supports two-arm stratified targets only; "
                "unexpected cells: " + ", ".join(extra_cells) + "."
            )
        missing = [label for label in labels if label not in target]
        if missing:
            cmr_error(f"Stratified targets are missing cells: {', '.join(missing)}.")
        denom = sum(max(target.get(label, 0.0), 0.0) for label in labels)
        within = (
            [0.5, 0.5]
            if denom <= 0
            else [max(target[label], 0.0) / denom for label in labels]
        )
        counts.update(
            _largest_remainder_counts(
                within,
                labels,
                n_stratum,
                min_per_arm=min_per_arm,
            )
        )
    n_total = sum(counts.values())
    if n_total <= 0:
        cmr_error("`strata_counts` must contain at least one main-wave unit.")
    shares = {label: count / n_total for label, count in counts.items()}
    return counts, shares


def realize_allocation(
    x,
    n_main: int | None = None,
    *,
    strata_counts=None,
    min_per_arm: int = 1,
    max_vertices: int = 65536,
) -> AllocationResult:
    """Convert target CMR shares into executable integer allocation counts."""

    fit = x if isinstance(x, CMRResult) else None
    target = x.pi if fit is not None else x
    max_vertices = scalar_int(max_vertices, "max_vertices", lower=1)
    min_per_arm = scalar_int(min_per_arm, "min_per_arm", lower=0)
    if n_main is not None:
        n_main = scalar_int(n_main, "n_main", lower=1)

    if np.isscalar(target):
        if n_main is None:
            cmr_error("`n_main` is required unless `strata_counts` is supplied.")
        pi = float(target)
        if not math.isfinite(pi) or pi < -1e-12 or pi > 1 + 1e-12:
            cmr_error("Two-arm `pi` must lie in [0, 1].")
        labels = ["treatment", "control"]
        shares = np.asarray([min(max(pi, 0.0), 1.0), 1 - min(max(pi, 0.0), 1.0)])
        target_pi = float(shares[0])
        counts, realized = _realize_vector(labels, shares, n_main, min_per_arm)
        realized_pi = realized["treatment"]
        diagnostics: dict[str, Any] = {"design": "two_arm"}
        cert = (
            _two_arm_realized_certificate(fit.rectangle, realized_pi)
            if fit is not None
            else None
        )
    else:
        if not isinstance(target, Mapping):
            arr = as_numeric_array(target, "pi").reshape(-1)
            labels = [str(i) for i in range(arr.size)]
            values = arr
        else:
            labels, values = _ordered_mapping_values(target)
        if len(labels) < 2:
            cmr_error(
                "Named or vector target shares must contain at least two arms "
                "or cells; "
                "use a scalar for a two-arm treatment share."
            )
        if len(set(labels)) != len(labels):
            cmr_error("Target share labels must be unique.")
        normalized_values = _normalize_shares(values, labels)
        target_map = dict(zip(labels, map(float, normalized_values), strict=True))
        target_pi = target_map

        if strata_counts is not None:
            counts, realized = _realize_stratified_counts(
                target_map,
                strata_counts,
                min_per_arm,
            )
            if n_main is not None and sum(counts.values()) != n_main:
                cmr_error(
                    "`n_main` must equal the sum of `strata_counts` when both "
                    "are supplied."
                )
            realized_pi = realized
            n_main = sum(counts.values())
            diagnostics = {"design": "stratified", "strata_counts": dict(strata_counts)}
        else:
            if n_main is None:
                cmr_error("`n_main` is required unless `strata_counts` is supplied.")
            values = [target_map[label] for label in labels]
            counts, realized = _realize_vector(labels, values, n_main, min_per_arm)
            realized_pi = realized
            diagnostics = {
                "design": "stratified" if _is_stratified_target(labels) else "multiarm"
            }

        cert = None
        if fit is not None:
            if diagnostics["design"] == "stratified":
                cert = _stratified_realized_certificate(
                    fit,
                    realized,
                    max_vertices=max_vertices,
                )
            else:
                cert = _multiarm_realized_certificate(
                    fit,
                    realized,
                    max_vertices=max_vertices,
                )

    continuous = _continuous_certificate(fit)
    realized_u = None if cert is None else float(cert["value"])
    certificate_recomputed = cert is not None
    if fit is not None and fit.rectangle is None and math.isinf(float(fit.U_CMR)):
        realized_u = math.inf
    if cert is not None:
        for key, value in cert.items():
            if key != "value":
                diagnostics[key] = value
    diagnostics["certificate_recomputed"] = certificate_recomputed

    return AllocationResult(
        counts=counts,
        shares=realized,
        pi=realized_pi,
        target_pi=target_pi,
        n_main=int(n_main if n_main is not None else sum(counts.values())),
        min_per_arm=min_per_arm,
        continuous_U_CMR=continuous,
        realized_U_CMR=realized_u,
        excess_U_CMR=_excess(realized_u, continuous),
        diagnostics=diagnostics,
    )
