import math
import unittest
import warnings

import numpy as np
import cmrdesign as cmr


class MultiarmTests(unittest.TestCase):
    def test_objective_oracle_and_neyman_agree(self):
        variances = {"0": 0.04, "1": 0.09, "2": 0.16}
        pi = cmr.assign_multiarm_neyman(variances)
        self.assertAlmostEqual(sum(pi.values()), 1, places=12)
        self.assertAlmostEqual(
            cmr.multiarm_variance_objective(pi, variances),
            cmr.multiarm_oracle_variance(variances),
            places=12,
        )
        self.assertAlmostEqual(cmr.multiarm_regret(pi, variances), 0, places=12)

    def test_one_treatment_reduces_to_two_arm_cmr(self):
        rect_two = {"v_l1": 0.01, "v_u1": 0.09, "v_l0": 0.04, "v_u0": 0.16}
        rect_multi = {"v_l0": 0.04, "v_u0": 0.16, "v_l1": 0.01, "v_u1": 0.09}
        fit_two = cmr.cmr_two_arm_from_rectangle(rect_two)
        fit_multi = cmr.cmr_multiarm_from_rectangle(rect_multi)
        self.assertAlmostEqual(fit_multi.pi["1"], fit_two.pi, places=6)
        self.assertAlmostEqual(fit_multi.pi["0"], 1 - fit_two.pi, places=6)
        self.assertAlmostEqual(fit_multi.U_CMR, fit_two.U_CMR, places=6)

    def test_full_rectangle_returns_no_information_allocation(self):
        k_treatments = 4
        rect = {"v_l0": 0, "v_u0": 0.25}
        for k in range(1, k_treatments + 1):
            rect[f"v_l{k}"] = 0
            rect[f"v_u{k}"] = 0.25
        fit = cmr.cmr_multiarm_from_rectangle(rect)
        expected_control = 1 / (1 + math.sqrt(k_treatments))
        expected_treat = 1 / (math.sqrt(k_treatments) * (1 + math.sqrt(k_treatments)))
        self.assertAlmostEqual(fit.pi["0"], expected_control, places=12)
        for k in range(1, k_treatments + 1):
            self.assertAlmostEqual(fit.pi[str(k)], expected_treat, places=12)
        self.assertTrue(fit.diagnostics["full_rectangle"])
        self.assertEqual(fit.diagnostics["solver"], "full_rectangle_closed_form")

    def test_collapsed_rectangle_uses_closed_form(self):
        rect = {"v_l0": 0.04, "v_u0": 0.04, "v_l1": 0.09, "v_u1": 0.09}
        fit = cmr.cmr_multiarm_from_rectangle(rect)
        self.assertTrue(fit.diagnostics["collapsed_rectangle"])
        self.assertEqual(fit.diagnostics["solver"], "collapsed_closed_form")
        self.assertAlmostEqual(fit.U_CMR, 0, places=12)

    def test_shrinking_rectangle_weakly_lowers_certificate(self):
        big = {"v_l0": 0, "v_u0": 0.25, "v_l1": 0, "v_u1": 0.25, "v_l2": 0, "v_u2": 0.25}
        small = {
            "v_l0": 0.02,
            "v_u0": 0.08,
            "v_l1": 0.04,
            "v_u1": 0.12,
            "v_l2": 0.01,
            "v_u2": 0.07,
        }
        fit_big = cmr.cmr_multiarm_from_rectangle(big)
        fit_small = cmr.cmr_multiarm_from_rectangle(small)
        self.assertLessEqual(fit_small.U_CMR, fit_big.U_CMR + 1e-8)

    def test_applied_multiarm_example_has_no_runtime_warnings(self):
        rng = np.random.default_rng(104)
        n_per_arm = 300
        arm = np.repeat([0, 1, 2], n_per_arm)
        y = np.r_[
            rng.beta(4, 4, n_per_arm),
            rng.beta(2, 6, n_per_arm),
            rng.beta(5, 3, n_per_arm),
        ]
        with warnings.catch_warnings():
            warnings.simplefilter("error", RuntimeWarning)
            fit = cmr.cmr_multiarm(y, arm, alpha=0.05, method="bounded")
        self.assertAlmostEqual(sum(fit.pi.values()), 1, places=12)

    def test_unbounded_method_is_rejected(self):
        y = np.r_[
            np.linspace(0.1, 0.6, 8),
            np.linspace(0.2, 0.7, 8),
            np.linspace(0.3, 0.8, 8),
        ]
        arm = np.repeat([0, 1, 2], 8)
        with self.assertRaisesRegex(ValueError, "only available for two-arm designs"):
            cmr.cmr_multiarm(y, arm, method="unbounded")

    def test_integral_float_arm_labels_are_canonicalized(self):
        rng = np.random.default_rng(114)
        n_per_arm = 40
        y = np.r_[
            rng.beta(4, 4, n_per_arm),
            rng.beta(2, 6, n_per_arm),
            rng.beta(5, 3, n_per_arm),
        ]
        arm_int = np.repeat([0, 1, 2], n_per_arm)
        arm_float = np.repeat([0.0, 1.0, 2.0], n_per_arm)
        fit_int = cmr.cmr_multiarm(y, arm_int, method="bounded")
        fit_float = cmr.cmr_multiarm(y, arm_float, method="bounded")
        self.assertEqual(set(fit_float.pi), {"0", "1", "2"})
        for arm in fit_int.pi:
            self.assertAlmostEqual(fit_float.pi[arm], fit_int.pi[arm], places=12)

    def test_nan_arm_labels_are_missing_under_na_rm(self):
        rng = np.random.default_rng(115)
        n_per_arm = 20
        y = np.r_[
            rng.beta(4, 4, n_per_arm),
            rng.beta(2, 6, n_per_arm),
            rng.beta(5, 3, n_per_arm),
            0.5,
        ]
        arm = np.asarray(list(np.repeat([0, 1, 2], n_per_arm)) + [np.nan], dtype=object)
        fit = cmr.cmr_multiarm(y, arm, method="bounded")
        self.assertEqual(fit.pilot["n"], {"0": n_per_arm, "1": n_per_arm, "2": n_per_arm})
        with self.assertRaisesRegex(ValueError, "na_rm=False"):
            cmr.cmr_multiarm(y, arm, method="bounded", na_rm=False)


if __name__ == "__main__":
    unittest.main()
