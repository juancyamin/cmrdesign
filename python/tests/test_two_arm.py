import unittest

import cmrdesign as cmr


class TwoArmTests(unittest.TestCase):
    def test_full_rectangle_returns_balance(self):
        rect = {"v_l1": 0, "v_u1": 0.25, "v_l0": 0, "v_u0": 0.25}
        fit = cmr.cmr_two_arm_from_rectangle(rect)
        self.assertAlmostEqual(fit.pi, 0.5, places=12)
        self.assertAlmostEqual(fit.U_CMR, 0.25, places=12)
        self.assertTrue(fit.diagnostics["full_rectangle"])

    def test_collapsed_rectangle_returns_neyman(self):
        rect = {"v_l1": 0.04, "v_u1": 0.04, "v_l0": 0.09, "v_u0": 0.09}
        fit = cmr.cmr_two_arm_from_rectangle(rect)
        self.assertAlmostEqual(fit.pi, cmr.assign_neyman(0.04, 0.09), places=12)
        self.assertAlmostEqual(fit.U_CMR, 0, places=12)
        self.assertTrue(fit.diagnostics["collapsed_rectangle"])

    def test_asymmetric_rectangle_equalizes_corners(self):
        rect = {"v_l1": 0.01, "v_u1": 0.09, "v_l0": 0.04, "v_u0": 0.16}
        fit = cmr.cmr_two_arm_from_rectangle(rect)
        regrets = fit.extra["corner_regrets"]
        self.assertAlmostEqual(fit.pi, 0.4, places=12)
        self.assertAlmostEqual(
            regrets["treatment_high_control_low"],
            regrets["treatment_low_control_high"],
            places=12,
        )

    def test_applied_binary_api(self):
        y = [0, 1, 0, 1, 1, 1, 0, 0, 0, 0]
        d = [1, 1, 1, 1, 1, 0, 0, 0, 0, 0]
        fit = cmr.cmr_two_arm(y, d, alpha=0.10, method="bernoulli")
        self.assertEqual(fit.method, "bernoulli")
        self.assertGreaterEqual(fit.U_CMR, 0)
        self.assertLessEqual(fit.U_CMR, 0.25)

    def test_legacy_aliases(self):
        rect = {"v_l1": 0, "v_u1": 0.25, "v_l0": 0, "v_u0": 0.25}
        self.assertAlmostEqual(cmr.cmr_binary_from_rectangle(rect).pi, 0.5)
        y = [0, 1, 0, 1, 0, 1, 0, 1]
        d = [1, 1, 1, 1, 0, 0, 0, 0]
        self.assertEqual(cmr.cmr_binary(y, d, method="bernoulli").method, "bernoulli")


if __name__ == "__main__":
    unittest.main()
