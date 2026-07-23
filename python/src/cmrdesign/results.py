"""Result containers for cmrdesign."""

from __future__ import annotations

from dataclasses import dataclass, field
from typing import Any


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

