import itertools
import unittest
import warnings

import numpy as np

import cmrdesign as cmr


def _problem(rect):
    arms = sorted(rect, key=int)
    lower = np.array([rect[a]["lower"] for a in arms])
    upper = np.array([rect[a]["upper"] for a in arms])
    weights = np.array([len(arms) - 1] + [1] * (len(arms) - 1), dtype=float)
    vertices = np.array(
        [
            np.where(bits, upper, lower)
            for bits in itertools.product((0, 1), repeat=len(arms))
        ]
    )
    A = vertices * weights
    return A, np.sum(np.sqrt(A), axis=1) ** 2


FIVE_ARMS = {
    "0": {"lower": 0.020, "upper": 0.090},
    "1": {"lower": 0.050, "upper": 0.200},
    "2": {"lower": 0.010, "upper": 0.040},
    "3": {"lower": 0.080, "upper": 0.110},
    "4": {"lower": 0.000, "upper": 0.150},
}
THREE_ARMS = {
    "0": {"lower": 0.02, "upper": 0.08},
    "1": {"lower": 0.04, "upper": 0.12},
    "2": {"lower": 0.01, "upper": 0.07},
}


class SolverTests(unittest.TestCase):
    def test_general_solver_certifies_its_optimality_gap(self):
        with warnings.catch_warnings():
            warnings.simplefilter("error")
            fit = cmr.cmr_multiarm_from_rectangle(FIVE_ARMS)
        self.assertEqual(fit.diagnostics["solver"], "barrier_newton")
        self.assertTrue(fit.diagnostics["converged"])
        self.assertGreaterEqual(fit.diagnostics["optimality_gap"], 0.0)
        self.assertLessEqual(fit.diagnostics["optimality_gap"], 1e-7)
        A, oracle = _problem(FIVE_ARMS)
        pi = np.array([fit.pi[a] for a in sorted(fit.pi, key=int)])
        self.assertAlmostEqual(
            fit.U_CMR, float(np.max(A @ (1 / pi) - oracle)), places=13
        )

    def test_barrier_and_search_agree(self):
        barrier = cmr.cmr_multiarm_from_rectangle(THREE_ARMS)
        search = cmr.cmr_multiarm_from_rectangle(THREE_ARMS, control={"barrier": False})
        self.assertEqual(search.diagnostics["solver"], "smooth_max_bfgs_nelder_mead")
        self.assertLessEqual(barrier.U_CMR, search.U_CMR + 1e-9)
        self.assertAlmostEqual(barrier.U_CMR, search.U_CMR, delta=1e-6)

    def test_two_components_recover_two_arm_closed_form(self):
        multiarm = cmr.cmr_multiarm_from_rectangle(
            {"0": {"lower": 0.04, "upper": 0.16}, "1": {"lower": 0.01, "upper": 0.09}}
        )
        two_arm = cmr.cmr_two_arm_from_rectangle(
            {"v_l1": 0.01, "v_u1": 0.09, "v_l0": 0.04, "v_u0": 0.16}
        )
        self.assertAlmostEqual(multiarm.pi["1"], two_arm.pi, delta=1e-7)
        self.assertAlmostEqual(multiarm.U_CMR, two_arm.U_CMR, delta=1e-8)

    def test_solver_beats_a_brute_force_grid(self):
        fit = cmr.cmr_multiarm_from_rectangle(THREE_ARMS)
        A, oracle = _problem(THREE_ARMS)
        grid = np.arange(0.01, 0.98, 0.005)
        best = min(
            float(np.max(A @ (1 / np.array([p0, p1, 1 - p0 - p1])) - oracle))
            for p0 in grid
            for p1 in grid
            if p0 + p1 < 0.995
        )
        self.assertLessEqual(fit.U_CMR, best + 1e-12)
        self.assertGreaterEqual(fit.U_CMR, best - 5e-3)


if __name__ == "__main__":
    unittest.main()
