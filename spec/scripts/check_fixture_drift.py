#!/usr/bin/env python3
"""Tolerance-aware drift check for generated JSON fixtures."""

from __future__ import annotations

import json
import math
import subprocess
import sys
from pathlib import Path
from typing import Any


ROOT = Path(__file__).resolve().parents[2]
FIXTURE_DIR = ROOT / "spec" / "test_fixtures"
R_FIXTURE_DIR = ROOT / "r" / "inst" / "extdata" / "test_fixtures"


def load_head(path: Path) -> Any:
    rel = path.relative_to(ROOT).as_posix()
    proc = subprocess.run(
        ["git", "show", f"HEAD:{rel}"],
        check=True,
        capture_output=True,
        text=True,
    )
    return json.loads(proc.stdout)


def tolerance_for_path(expected: Any, path: tuple[Any, ...]) -> float:
    tol = float(expected.get("tolerance", 0.0)) if isinstance(expected, dict) else 0.0
    if len(path) >= 2 and path[0] == "cases" and isinstance(path[1], int):
        case = expected["cases"][path[1]]
        if isinstance(case, dict) and "tolerance" in case:
            tol = float(case["tolerance"])
    return tol


def compare(expected: Any, actual: Any, path: tuple[Any, ...], root: Any, errors: list[str]) -> None:
    label = "/".join(str(x) for x in path) or "<root>"

    if isinstance(expected, bool) or isinstance(actual, bool):
        if expected is not actual:
            errors.append(f"{label}: expected {expected!r}, got {actual!r}")
        return

    if expected is None or actual is None:
        if expected is not actual:
            errors.append(f"{label}: expected {expected!r}, got {actual!r}")
        return

    if isinstance(expected, (int, float)) and isinstance(actual, (int, float)):
        tol = tolerance_for_path(root, path)
        if not (math.isfinite(float(expected)) and math.isfinite(float(actual))):
            if str(expected) != str(actual):
                errors.append(f"{label}: expected {expected!r}, got {actual!r}")
        elif abs(float(expected) - float(actual)) > tol:
            errors.append(
                f"{label}: expected {expected!r}, got {actual!r}, "
                f"abs diff {abs(float(expected) - float(actual)):.3g} > tolerance {tol:.3g}"
            )
        return

    if isinstance(expected, str) or isinstance(actual, str):
        if expected != actual:
            errors.append(f"{label}: expected {expected!r}, got {actual!r}")
        return

    if isinstance(expected, list) and isinstance(actual, list):
        if len(expected) != len(actual):
            errors.append(f"{label}: expected length {len(expected)}, got {len(actual)}")
            return
        for i, (exp_item, act_item) in enumerate(zip(expected, actual)):
            compare(exp_item, act_item, path + (i,), root, errors)
        return

    if isinstance(expected, dict) and isinstance(actual, dict):
        if set(expected) != set(actual):
            missing = sorted(set(expected) - set(actual))
            extra = sorted(set(actual) - set(expected))
            errors.append(f"{label}: key mismatch, missing={missing}, extra={extra}")
            return
        for key in expected:
            compare(expected[key], actual[key], path + (key,), root, errors)
        return

    if expected != actual:
        errors.append(f"{label}: expected {expected!r}, got {actual!r}")


def main() -> int:
    failures: list[str] = []
    fixture_paths = sorted(FIXTURE_DIR.glob("*.json"))
    for path in fixture_paths:
        expected = load_head(path)
        actual = json.loads(path.read_text(encoding="utf-8"))
        errors: list[str] = []
        compare(expected, actual, (), expected, errors)
        if errors:
            failures.append(f"{path.relative_to(ROOT)}")
            failures.extend(f"  - {error}" for error in errors[:20])
            if len(errors) > 20:
                failures.append(f"  - ... {len(errors) - 20} more differences")

        r_path = R_FIXTURE_DIR / path.name
        if not r_path.exists():
            failures.append(f"{r_path.relative_to(ROOT)} is missing")
            continue
        r_actual = json.loads(r_path.read_text(encoding="utf-8"))
        r_errors: list[str] = []
        compare(actual, r_actual, (), actual, r_errors)
        if r_errors:
            failures.append(f"{r_path.relative_to(ROOT)} does not match {path.relative_to(ROOT)}")
            failures.extend(f"  - {error}" for error in r_errors[:20])
            if len(r_errors) > 20:
                failures.append(f"  - ... {len(r_errors) - 20} more differences")

    expected_names = {path.name for path in fixture_paths}
    if R_FIXTURE_DIR.exists():
        extra_names = {path.name for path in R_FIXTURE_DIR.glob("*.json")} - expected_names
        for name in sorted(extra_names):
            failures.append(f"{(R_FIXTURE_DIR / name).relative_to(ROOT)} has no spec/test_fixtures counterpart")

    if failures:
        print("Fixture drift exceeded declared tolerances:")
        print("\n".join(failures))
        return 1

    print("Generated fixtures match committed fixtures within declared tolerances.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
