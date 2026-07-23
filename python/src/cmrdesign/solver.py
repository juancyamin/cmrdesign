"""Vertex-epigraph solver for vector-allocation CMR problems."""

from __future__ import annotations

import itertools
import math

import numpy as np

from .validation import as_numeric_array, check_variance, cmr_error, scalar_int


def normalize_simplex(pi, name: str = "pi") -> np.ndarray:
    arr = as_numeric_array(pi, name).reshape(-1)
    if np.any(arr < -1e-12):
        cmr_error(f"`{name}` must be nonnegative.")
    arr = np.maximum(arr, 0)
    total = float(np.sum(arr))
    if total <= 0:
        cmr_error(f"`{name}` must contain positive mass.")
    return arr / total


def hyperrectangle_vertices(
    lower,
    upper,
    names=None,
    max_vertices: int = 65536,
) -> dict:
    """Enumerate vertices of a variance hyperrectangle."""

    lower = check_variance(lower, "lower").reshape(-1)
    upper = check_variance(upper, "upper").reshape(-1)
    if lower.size != upper.size:
        cmr_error("`lower` and `upper` must have the same length.")
    if np.any(lower > upper + 1e-12):
        cmr_error("Lower endpoints cannot exceed upper endpoints.")
    n_dim = lower.size
    n_vertices = 2**n_dim
    max_vertices = scalar_int(max_vertices, "max_vertices", lower=1)
    if n_vertices > max_vertices:
        cmr_error(
            f"The hyperrectangle has {n_vertices} vertices, "
            "exceeding `max_vertices`."
        )
    if names is None:
        names = [f"component_{i + 1}" for i in range(n_dim)]
    if len(names) != n_dim:
        cmr_error("`names` must have one label per rectangle dimension.")
    rows = []
    for bits in itertools.product((0, 1), repeat=n_dim):
        rows.append(np.where(np.asarray(bits, dtype=bool), upper, lower))
    return {
        "vertices": np.asarray(rows, dtype=float),
        "names": list(map(str, names)),
        "vertex_names": [f"vertex_{i + 1}" for i in range(n_vertices)],
    }


def _check_vertex_problem(A, oracle) -> tuple[np.ndarray, np.ndarray, list[str]]:
    A = as_numeric_array(A, "A")
    if A.ndim == 1:
        A = A.reshape(1, -1)
    if A.ndim != 2 or A.shape[0] < 1 or A.shape[1] < 1:
        cmr_error("`A` must be a two-dimensional array with at least one row and column.")
    if np.any(A < -1e-12):
        cmr_error("`A` must contain nonnegative entries.")
    A = np.maximum(A, 0)
    oracle = as_numeric_array(oracle, "oracle").reshape(-1)
    if oracle.size != A.shape[0]:
        cmr_error("`oracle` must have one entry per row of `A`.")
    if np.any(oracle < -1e-12):
        cmr_error("`oracle` must be nonnegative.")
    names = [f"component_{i + 1}" for i in range(A.shape[1])]
    return A, np.maximum(oracle, 0), names


def inverse_share_sums(pi, A) -> np.ndarray:
    pi = np.asarray(pi, dtype=float).reshape(-1)
    A = np.asarray(A, dtype=float)
    out = np.zeros(A.shape[0], dtype=float)
    for j, share in enumerate(pi):
        if share > 0:
            out += A[:, j] / share
        elif np.any(A[:, j] > 0):
            out[A[:, j] > 0] = np.inf
    return out


def vertex_regrets(pi, A, oracle) -> np.ndarray:
    return inverse_share_sums(pi, A) - np.asarray(oracle, dtype=float).reshape(-1)


def vertex_certificate(pi, A, oracle, return_details: bool = False):
    values = vertex_regrets(pi, A, oracle)
    certificate = float(np.max(values))
    if not return_details:
        return certificate
    active = np.flatnonzero(values >= certificate - 1e-8).tolist()
    return {
        "value": certificate,
        "vertex_regrets": values,
        "active_vertices": active,
    }


def _vertex_starts(A, default_start=None, max_starts: int = 40) -> list[np.ndarray]:
    n = A.shape[1]
    starts = []
    if default_start is not None:
        starts.append(normalize_simplex(default_start, "default_start"))
    starts.append(np.full(n, 1 / n))
    mean_score = np.sqrt(np.mean(A, axis=0))
    if np.sum(mean_score) > 0:
        starts.append(mean_score / np.sum(mean_score))
    max_score = np.sqrt(np.max(A, axis=0))
    if np.sum(max_score) > 0:
        starts.append(max_score / np.sum(max_score))
    vertex_starts = []
    for row in A:
        score = np.sqrt(row)
        if np.sum(score) > 0:
            vertex_starts.append(score / np.sum(score))
    if vertex_starts:
        vertex_matrix = np.vstack(vertex_starts)
        starts.append(np.mean(vertex_matrix, axis=0))
        for row in vertex_matrix[: max(0, max_starts - len(starts))]:
            starts.append(row)
    out = []
    seen = set()
    for start in starts:
        start = np.maximum(np.asarray(start, dtype=float).reshape(-1), np.finfo(float).eps)
        start = start / np.sum(start)
        key = tuple(np.round(start, 12))
        if key not in seen:
            seen.add(key)
            out.append(start)
    return out


def _mirror_refine(pi, A, oracle, iterations: int = 5000) -> dict:
    iterations = scalar_int(iterations, "iterations", lower=1)
    pi = normalize_simplex(pi)
    eps = np.finfo(float).eps
    best_pi = pi.copy()
    best_value = float(np.max(vertex_regrets(pi, A, oracle)))
    for iteration in range(1, iterations + 1):
        values = vertex_regrets(pi, A, oracle)
        active = values >= np.max(values) - 1e-9
        grad = -np.mean(A[active, :] / (pi.reshape(1, -1) ** 2), axis=0)
        scale = max(1.0, float(np.max(np.abs(grad))))
        step = 0.35 / math.sqrt(iteration) / scale
        log_pi = np.log(np.maximum(pi, eps)) - step * grad
        log_pi -= np.max(log_pi)
        pi = np.exp(log_pi)
        pi /= np.sum(pi)
        value = float(np.max(vertex_regrets(pi, A, oracle)))
        if value < best_value:
            best_value = value
            best_pi = pi.copy()
    return {"pi": best_pi, "value": best_value}


def _golden_section_two_component(A, oracle, tol: float = 1e-13) -> dict:
    """Solve the active two-component problem by scalar convex search."""

    eps = 1e-14

    def objective(p):
        p = min(max(float(p), eps), 1 - eps)
        return float(np.max(vertex_regrets(np.array([p, 1 - p]), A, oracle)))

    lo, hi = eps, 1 - eps
    inv_phi = (math.sqrt(5) - 1) / 2
    inv_phi_sq = (3 - math.sqrt(5)) / 2
    h = hi - lo
    c = lo + inv_phi_sq * h
    d = lo + inv_phi * h
    fc = objective(c)
    fd = objective(d)
    while h > tol:
        if fc < fd:
            hi = d
            d = c
            fd = fc
            h = inv_phi * h
            c = lo + inv_phi_sq * h
            fc = objective(c)
        else:
            lo = c
            c = d
            fc = fd
            h = inv_phi * h
            d = lo + inv_phi * h
            fd = objective(d)
    p = (lo + hi) / 2
    pi = np.array([p, 1 - p], dtype=float)
    return {"pi": pi, "value": objective(p)}


def _from_logits(z) -> np.ndarray:
    z = np.asarray(z, dtype=float).reshape(-1)
    z_full = np.r_[z, 0.0]
    z_full -= np.max(z_full)
    ez = np.exp(z_full)
    return ez / np.sum(ez)


def _to_logits(pi) -> np.ndarray:
    pi = np.maximum(np.asarray(pi, dtype=float).reshape(-1), np.finfo(float).eps)
    pi /= np.sum(pi)
    return np.log(pi[:-1] / pi[-1])


def _smooth_vertex_objective(z, A, oracle, tau: float) -> tuple[float, np.ndarray]:
    pi = _from_logits(z)
    values = vertex_regrets(pi, A, oracle)
    center = float(np.max(values))
    scaled = np.exp((values - center) / tau)
    weights = scaled / np.sum(scaled)
    value = center + tau * math.log(float(np.sum(scaled)))
    grad_pi = -np.sum(
        A * weights.reshape(-1, 1) / (pi.reshape(1, -1) ** 2),
        axis=0,
    )
    mean_grad = float(np.sum(pi * grad_pi))
    grad_z = pi[:-1] * (grad_pi[:-1] - mean_grad)
    return float(value), grad_z


def _true_vertex_objective_from_logits(z, A, oracle) -> float:
    return float(np.max(vertex_regrets(_from_logits(z), A, oracle)))


def _bfgs_smooth(z0, A, oracle, tau: float, maxit: int = 1000) -> dict:
    z = np.asarray(z0, dtype=float).reshape(-1)
    n = z.size
    if n == 0:
        return {"z": z, "value": _smooth_vertex_objective(z, A, oracle, tau)[0], "converged": True}
    H = np.eye(n)
    value, grad = _smooth_vertex_objective(z, A, oracle, tau)
    converged = False
    for _ in range(maxit):
        if float(np.max(np.abs(grad))) <= 1e-9:
            converged = True
            break
        direction = -H @ grad
        if not np.all(np.isfinite(direction)) or float(np.dot(direction, grad)) >= 0:
            direction = -grad
            H = np.eye(n)
        slope = float(np.dot(grad, direction))
        step = 1.0
        accepted = False
        for _line in range(40):
            candidate = z + step * direction
            new_value, new_grad = _smooth_vertex_objective(candidate, A, oracle, tau)
            if np.isfinite(new_value) and new_value <= value + 1e-4 * step * slope:
                accepted = True
                break
            step *= 0.5
        if not accepted:
            break
        s = candidate - z
        y = new_grad - grad
        ys = float(np.dot(y, s))
        if ys > 1e-12:
            rho = 1.0 / ys
            I = np.eye(n)
            V = I - rho * np.outer(s, y)
            H = V @ H @ V.T + rho * np.outer(s, s)
        else:
            H = np.eye(n)
        z = candidate
        if abs(value - new_value) <= 1e-12 * max(1.0, abs(value)):
            value = new_value
            grad = new_grad
            converged = True
            break
        value = new_value
        grad = new_grad
    return {"z": z, "value": value, "converged": converged}


def _nelder_mead_true(z0, A, oracle, maxit: int = 1000, tol: float = 1e-12) -> dict:
    z0 = np.asarray(z0, dtype=float).reshape(-1)
    n = z0.size
    if n == 0:
        return {"z": z0, "value": _true_vertex_objective_from_logits(z0, A, oracle), "converged": True}
    simplex = [z0]
    for j in range(n):
        point = z0.copy()
        point[j] += 0.05 if point[j] != 0 else 0.00025
        simplex.append(point)
    simplex = np.asarray(simplex, dtype=float)
    values = np.asarray([_true_vertex_objective_from_logits(x, A, oracle) for x in simplex])
    alpha = 1.0
    gamma = 2.0
    rho = 0.5
    sigma = 0.5
    converged = False
    for _ in range(maxit):
        order = np.argsort(values)
        simplex = simplex[order]
        values = values[order]
        if np.max(np.abs(values - values[0])) <= tol and np.max(np.linalg.norm(simplex - simplex[0], axis=1)) <= math.sqrt(tol):
            converged = True
            break
        centroid = np.mean(simplex[:-1], axis=0)
        reflected = centroid + alpha * (centroid - simplex[-1])
        reflected_value = _true_vertex_objective_from_logits(reflected, A, oracle)
        if values[0] <= reflected_value < values[-2]:
            simplex[-1] = reflected
            values[-1] = reflected_value
            continue
        if reflected_value < values[0]:
            expanded = centroid + gamma * (reflected - centroid)
            expanded_value = _true_vertex_objective_from_logits(expanded, A, oracle)
            if expanded_value < reflected_value:
                simplex[-1] = expanded
                values[-1] = expanded_value
            else:
                simplex[-1] = reflected
                values[-1] = reflected_value
            continue
        contracted = centroid + rho * (simplex[-1] - centroid)
        contracted_value = _true_vertex_objective_from_logits(contracted, A, oracle)
        if contracted_value < values[-1]:
            simplex[-1] = contracted
            values[-1] = contracted_value
            continue
        for j in range(1, n + 1):
            simplex[j] = simplex[0] + sigma * (simplex[j] - simplex[0])
            values[j] = _true_vertex_objective_from_logits(simplex[j], A, oracle)
    order = np.argsort(values)
    simplex = simplex[order]
    values = values[order]
    return {"z": simplex[0], "value": float(values[0]), "converged": converged}


def _smooth_bfgs_nelder_mead(A, oracle, default_start=None, control=None) -> dict:
    control = {} if control is None else dict(control)
    max_starts = int(control.get("max_starts", 40))
    starts = _vertex_starts(A, default_start=default_start, max_starts=max_starts)
    scale_value = max(
        1.0,
        float(np.max(np.abs(oracle))),
        float(np.max(inverse_share_sums(np.full(A.shape[1], 1 / A.shape[1]), A))),
    )
    taus = control.get(
        "smooth_taus",
        scale_value * np.asarray([1e-2, 3e-3, 1e-3, 3e-4, 1e-4, 3e-5, 1e-5]),
    )
    maxit = int(control.get("maxit", 1000))
    candidates = []
    for start in starts:
        z = _to_logits(start)
        convergence = []
        for tau in taus:
            opt = _bfgs_smooth(z, A, oracle, float(tau), maxit=maxit)
            z = opt["z"]
            convergence.append(opt["converged"])
        opt_nm = _nelder_mead_true(z, A, oracle, maxit=maxit, tol=1e-12)
        z = opt_nm["z"]
        pi = _from_logits(z)
        candidates.append(
            {
                "pi": pi,
                "value": float(np.max(vertex_regrets(pi, A, oracle))),
                "convergence": convergence + [opt_nm["converged"]],
            }
        )
    best = min(candidates, key=lambda item: item["value"])
    mirror_iterations = int(control.get("mirror_iterations", 1000))
    if mirror_iterations > 0:
        refined = _mirror_refine(best["pi"], A, oracle, iterations=mirror_iterations)
        if refined["value"] < best["value"]:
            best = {**best, "pi": refined["pi"], "value": refined["value"]}
    best["starts"] = len(starts)
    best["best_start_value"] = min(item["value"] for item in candidates)
    best["converged"] = any(all(item["convergence"]) for item in candidates)
    return best


def directional_violation(pi, A, oracle, eps: float = 1e-5) -> float:
    pi = np.asarray(pi, dtype=float).reshape(-1)
    current = float(np.max(vertex_regrets(pi, A, oracle)))
    best = current
    n = pi.size
    for from_idx in range(n):
        step = min(eps, pi[from_idx] / 2)
        if step <= 0:
            continue
        for to_idx in range(n):
            if to_idx == from_idx:
                continue
            candidate = pi.copy()
            candidate[from_idx] -= step
            candidate[to_idx] += step
            best = min(best, float(np.max(vertex_regrets(candidate, A, oracle))))
    return max(0.0, current - best)


def solve_vertex_epigraph(A, oracle, default_start=None, control=None) -> dict:
    """Pure-NumPy minimax solver for vertex-defined CMR extension problems."""

    control = {} if control is None else dict(control)
    A, oracle, component_names = _check_vertex_problem(A, oracle)
    if "component_names" in control:
        component_names = list(map(str, control["component_names"]))
        if len(component_names) != A.shape[1]:
            cmr_error("`component_names` must have one entry per column of `A`.")

    active_columns = np.max(A, axis=0) > 1e-14
    if not np.any(active_columns):
        pi = (
            np.full(A.shape[1], 1 / A.shape[1])
            if default_start is None
            else normalize_simplex(default_start, "default_start")
        )
        details = vertex_certificate(pi, A, oracle, return_details=True)
        return {
            "pi": dict(zip(component_names, map(float, pi), strict=True)),
            "pi_array": pi,
            "value": details["value"],
            "vertex_regrets": details["vertex_regrets"],
            "active_vertices": details["active_vertices"],
            "diagnostics": {
                "solver": "all_zero_coefficients",
                "active_components": component_names,
                "directional_violation": 0.0,
                "converged": True,
            },
        }

    A_active = A[:, active_columns]
    default_active = None
    if default_start is not None:
        default_start = normalize_simplex(default_start, "default_start")
        default_active = default_start[active_columns]
        if np.sum(default_active) > 0:
            default_active = default_active / np.sum(default_active)
        else:
            default_active = None

    if A_active.shape[1] == 1:
        pi_active = np.ones(1)
        solver_name = "single_active_component"
    elif A_active.shape[1] == 2:
        solved = _golden_section_two_component(A_active, oracle)
        pi_active = solved["pi"]
        solver_name = "golden_section"
        solver_extra = {}
    else:
        best = _smooth_bfgs_nelder_mead(
            A_active,
            oracle,
            default_start=default_active,
            control=control,
        )
        pi_active = best["pi"]
        solver_name = "smooth_max_bfgs_nelder_mead"
        solver_extra = {
            "starts": best["starts"],
            "best_start_value": best["best_start_value"],
            "smooth_converged": best["converged"],
        }

    pi = np.zeros(A.shape[1])
    pi[active_columns] = pi_active
    details = vertex_certificate(pi, A, oracle, return_details=True)
    violation = directional_violation(pi_active, A_active, oracle)
    active_names = [
        name for name, is_active in zip(component_names, active_columns, strict=True) if is_active
    ]
    diagnostics = {
        "solver": solver_name,
        "active_components": active_names,
        "directional_violation": violation,
        "converged": violation <= 1e-6,
        "active_column_mask": active_columns,
    }
    diagnostics.update(solver_extra if "solver_extra" in locals() else {})
    return {
        "pi": dict(zip(component_names, map(float, pi), strict=True)),
        "pi_array": pi,
        "value": details["value"],
        "vertex_regrets": details["vertex_regrets"],
        "active_vertices": details["active_vertices"],
        "diagnostics": diagnostics,
    }
