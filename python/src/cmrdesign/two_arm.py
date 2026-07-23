"""Two-arm CMR public API and CMR-from-rectangle helper."""

from __future__ import annotations

import math

from .core import assign_neyman, regret
from .rectangles import check_binary_rectangle, rectangle_two_arm
from .results import CMRResult
from .unbounded import (
    check_unbounded_method_options,
    cmr_unbounded,
    is_unbounded_method,
)


def binary_rectangle_corners(rectangle) -> dict[str, dict[str, float]]:
    """Return the two off-diagonal corners that bind the two-arm CMR problem."""

    rect = check_binary_rectangle(rectangle)
    return {
        "treatment_high_control_low": {"v1": rect["v_u1"], "v0": rect["v_l0"]},
        "treatment_low_control_high": {"v1": rect["v_l1"], "v0": rect["v_u0"]},
    }


def binary_rectangle_regret(pi: float, rectangle, return_details: bool = False):
    """Worst two-arm regret over the CMR rectangle."""

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
    """Compute the closed-form two-arm CMR assignment from a variance rectangle."""

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
    """Estimate the two-arm CMR assignment from pilot outcomes and assignments."""

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
    out.extra["correction"] = confidence_set.extra.get("correction")
    return out


cmr_binary_from_rectangle = cmr_two_arm_from_rectangle
cmr_binary = cmr_two_arm
