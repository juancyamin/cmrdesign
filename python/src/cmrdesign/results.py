"""Result containers for cmrdesign."""

from __future__ import annotations

from dataclasses import dataclass, field
from typing import Any


def _format_scalar(value: Any, digits: int = 6) -> str:
    if isinstance(value, float):
        if value == float("inf"):
            return "inf"
        if value == float("-inf"):
            return "-inf"
        return f"{value:.{digits}g}"
    if isinstance(value, int):
        return str(value)
    return repr(value)


def _format_compact(value: Any, max_items: int = 6) -> str:
    if isinstance(value, dict):
        items = list(value.items())
        shown = ", ".join(
            f"{key}={_format_scalar(val)}" for key, val in items[:max_items]
        )
        if len(items) > max_items:
            shown += ", ..."
        return "{" + shown + "}"
    if isinstance(value, (list, tuple)):
        shown = ", ".join(_format_scalar(val) for val in value[:max_items])
        if len(value) > max_items:
            shown += ", ..."
        return "[" + shown + "]"
    try:
        import numpy as np

        arr = np.asarray(value)
        if arr.ndim > 0 and arr.size > 1:
            flat = arr.reshape(-1)
            shown = ", ".join(_format_scalar(float(val)) for val in flat[:max_items])
            if flat.size > max_items:
                shown += ", ..."
            return "[" + shown + "]"
    except Exception:  # pragma: no cover - formatting must not affect results
        pass
    return _format_scalar(value)


def _total_n(n: Any) -> int | None:
    if n is None:
        return None
    try:
        if isinstance(n, dict):
            values = []
            for value in n.values():
                if isinstance(value, dict):
                    values.extend(value.values())
                else:
                    values.append(value)
        else:
            values = n
        import numpy as np

        arr = np.asarray(values, dtype=float).reshape(-1)
        arr = arr[np.isfinite(arr)]
        if arr.size == 0:
            return None
        return int(np.sum(arr))
    except Exception:  # pragma: no cover - formatting must not affect results
        return None


@dataclass
class RectangleResult:
    """Confidence rectangle or hyperrectangle returned by rectangle constructors."""

    rectangle: Any
    alpha: float
    beta: Any
    method: str
    n: Any
    vhat: Any
    joint_error_bound: float | None = None
    diagnostics: dict[str, Any] = field(default_factory=dict)
    extra: dict[str, Any] = field(default_factory=dict)

    def __repr__(self) -> str:
        parts = [f"method={self.method!r}"]
        n_total = _total_n(self.n)
        if n_total is not None:
            parts.append(f"n={n_total}")
        status = self.extra.get("status") or self.diagnostics.get("status")
        if status is not None:
            parts.append(f"status={status!r}")
        if self.joint_error_bound is not None:
            parts.append(f"joint_error_bound={_format_scalar(self.joint_error_bound)}")
        return f"RectangleResult({', '.join(parts)})"


@dataclass
class CMRResult:
    """CMR assignment, certificate, and audit information."""

    pi: Any
    u_cmr: float
    rectangle: Any
    confidence_set: RectangleResult | None = None
    pilot: dict[str, Any] = field(default_factory=dict)
    alpha: float | None = None
    beta: Any = None
    method: str | None = None
    joint_error_bound: float | None = None
    diagnostics: dict[str, Any] = field(default_factory=dict)
    extra: dict[str, Any] = field(default_factory=dict)

    @property
    def U_CMR(self) -> float:
        """R-compatible certificate alias."""

        return self.u_cmr

    def __repr__(self) -> str:
        parts = [
            f"pi={_format_compact(self.pi)}",
            f"U_CMR={_format_scalar(self.u_cmr)}",
        ]
        if self.method is not None:
            parts.append(f"method={self.method!r}")
        n_total = _total_n(self.pilot.get("n"))
        if n_total is not None:
            parts.append(f"n={n_total}")
        status = self.diagnostics.get("status") or self.pilot.get("status")
        if status is not None:
            parts.append(f"status={status!r}")
        return f"CMRResult({', '.join(parts)})"
