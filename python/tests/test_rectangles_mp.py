import unittest

import cmrdesign as cmr


class MaurerPontilRectangleTests(unittest.TestCase):
    def test_variance_bounds_are_valid_endpoints(self):
        y = [0, 1] * 40
        bounds = cmr.variance_bounds_maurer_pontil(y, beta_l=0.0125, beta_u=0.0125)
        self.assertGreaterEqual(bounds["L"], 0)
        self.assertLessEqual(bounds["U"], 0.25)
        self.assertLessEqual(bounds["L"], bounds["U"])
        self.assertEqual(bounds["method"], "bounded")
        self.assertEqual(bounds["n"], len(y))

    def test_variance_bounds_drop_missing_by_default(self):
        y = [0, 1, float("nan"), 0, 1]
        bounds = cmr.variance_bounds_maurer_pontil(y, beta_l=0.05, beta_u=0.05)
        self.assertEqual(bounds["n"], 4)
        with self.assertRaisesRegex(ValueError, "na_rm=False"):
            cmr.variance_bounds_maurer_pontil(y, beta_l=0.05, beta_u=0.05, na_rm=False)

    def test_bounded_two_arm_rectangle_splits_arms(self):
        y = [0, 1, 0, 1, 0.2, 0.3, 0.4, 0.5]
        d = [1, 1, 1, 1, 0, 0, 0, 0]
        rect = cmr.rectangle_two_arm(y, d, alpha=0.10, method="bounded")
        self.assertEqual(set(rect.rectangle), {"v_l1", "v_u1", "v_l0", "v_u0"})
        self.assertGreaterEqual(min(rect.rectangle.values()), 0)
        self.assertLessEqual(max(rect.rectangle.values()), 0.25)
        self.assertLessEqual(rect.rectangle["v_l1"], rect.rectangle["v_u1"])
        self.assertLessEqual(rect.rectangle["v_l0"], rect.rectangle["v_u0"])
        self.assertEqual(rect.n, {"n1": 4, "n0": 4})
        self.assertEqual(rect.method, "bounded")

    def test_bounded_two_arm_alias_is_exported(self):
        self.assertIs(cmr.rectangle_bounded_two_arm, cmr.rectangle_bounded_binary)


if __name__ == "__main__":
    unittest.main()
