import unittest

import cmrdesign as cmr


class MTRRectangleTests(unittest.TestCase):
    def test_bounds_match_regression_values(self):
        y = list([x / 100 for x in range(5, 100, 10)]) * 50
        bounds = cmr.variance_bounds_martinez_taboada_ramdas(
            y,
            beta_l=0.0125,
            beta_u=0.0125,
        )
        self.assertEqual(bounds["method"], "martinez_taboada_ramdas")
        self.assertEqual(bounds["n"], len(y))
        self.assertAlmostEqual(bounds["L"], 0.04690604657062841, places=12)
        self.assertAlmostEqual(bounds["U"], 0.10320241415971833, places=12)

    def test_bounds_drop_missing_by_default(self):
        y = list([x / 100 for x in range(5, 100, 10)]) * 5
        y[3] = float("nan")
        bounds = cmr.variance_bounds_martinez_taboada_ramdas(
            y,
            beta_l=0.05,
            beta_u=0.05,
        )
        self.assertEqual(bounds["n"], len(y) - 1)
        with self.assertRaisesRegex(ValueError, "na_rm=False"):
            cmr.variance_bounds_martinez_taboada_ramdas(
                y,
                beta_l=0.05,
                beta_u=0.05,
                na_rm=False,
            )

    def test_mtr_is_available_through_applied_api(self):
        y = list([x / 100 for x in range(5, 100, 10)]) * 10
        y += list([x / 100 for x in range(10, 100, 10)]) * 12
        d = [1] * 100 + [0] * 108
        fit = cmr.cmr_two_arm(y, d, alpha=0.10, method="mtr")
        self.assertEqual(fit.method, "martinez_taboada_ramdas")
        self.assertGreaterEqual(fit.U_CMR, 0)


if __name__ == "__main__":
    unittest.main()
