import math
import unittest

import cmrdesign as cmr


class UnboundedTests(unittest.TestCase):
    def test_mom_variance_bounds_use_paired_blocks(self):
        y = [0, 2] * 180
        bounds = cmr.variance_bounds_unbounded_mom(y, alpha=0.05, psi=1)
        rho = math.sqrt(2 * (1 + 1) / 6)

        self.assertTrue(bounds["active"])
        self.assertEqual(bounds["statistic"]["k"], 30)
        self.assertEqual(bounds["statistic"]["b"], 6)
        self.assertEqual(bounds["statistic"]["n_pairs"], 180)
        self.assertEqual(bounds["statistic"]["used_pairs"], 180)
        self.assertAlmostEqual(bounds["vhat"], 2, places=12)
        self.assertAlmostEqual(bounds["L"], 2 / (1 + rho), places=12)
        self.assertAlmostEqual(bounds["U"], 2 / (1 - rho), places=12)
        self.assertGreater(bounds["U"], 0.25)

    def test_unbounded_cmr_accepts_variances_above_one_quarter(self):
        rect = {"v_l1": 1, "v_u1": 4, "v_l0": 9, "v_u0": 16}
        fit = cmr.cmr_unbounded_from_rectangle(rect)

        self.assertAlmostEqual(fit.pi, 0.3, places=12)
        self.assertGreaterEqual(fit.U_CMR, 0)
        self.assertTrue(fit.diagnostics["unbounded_outcomes"])

    def test_unbounded_applied_api_and_two_arm_dispatch_agree(self):
        y1 = [0, 2] * 180
        y0 = [0, 4] * 180
        y = y1 + y0
        d = [1] * len(y1) + [0] * len(y0)

        rect = cmr.rectangle_unbounded(y, d, psi=1, alpha=0.05)
        direct = cmr.cmr_unbounded(y, d, psi=1, alpha=0.05)
        dispatched = cmr.cmr_two_arm(y, d, method="unbounded", psi=1, alpha=0.05)

        self.assertTrue(rect.extra["active"])
        self.assertGreater(rect.rectangle["v_u1"], 0.25)
        self.assertAlmostEqual(direct.pi, dispatched.pi, places=12)
        self.assertAlmostEqual(direct.U_CMR, dispatched.U_CMR, places=12)
        self.assertEqual(direct.method, "unbounded_mom")
        self.assertEqual(dispatched.confidence_set.extra["status"], "active")

    def test_unbounded_api_falls_back_to_balance_without_certificate(self):
        y = [0, 2] * 20
        d = [1] * 20 + [0] * 20
        fit = cmr.cmr_unbounded(y, d, psi=1, alpha=0.05)

        self.assertAlmostEqual(fit.pi, 0.5, places=12)
        self.assertTrue(math.isinf(fit.U_CMR))
        self.assertFalse(fit.confidence_set.extra["active"])
        self.assertIn("pilot_too_small", fit.confidence_set.extra["status"])
        self.assertTrue(fit.diagnostics["no_finite_certificate"])

    def test_unbounded_api_validates_psi_and_incompatible_options(self):
        y = [0, 2] * 180
        d = [1] * 180 + [0] * 180

        with self.assertRaisesRegex(ValueError, "`psi` is required"):
            cmr.cmr_unbounded(y, d, alpha=0.05)
        with self.assertRaisesRegex(ValueError, "at least 1"):
            cmr.cmr_unbounded(y, d, psi=0.9)
        with self.assertRaisesRegex(ValueError, "raw numeric outcomes"):
            cmr.cmr_two_arm(y, d, method="unbounded", psi=1, normalize=True)
        with self.assertRaisesRegex(ValueError, "`beta` is not used"):
            cmr.cmr_two_arm(y, d, method="unbounded", psi=1, beta=0.01)


if __name__ == "__main__":
    unittest.main()
