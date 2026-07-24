import unittest

import numpy as np

import cmrdesign as cmr
from cmrdesign.variance_bounds import (
    bernoulli_lower_bound,
    bernoulli_upper_bound,
    variance_bounds_by_method,
)


class BernoulliRectangleTests(unittest.TestCase):
    def test_folded_binomial_pmf_is_valid(self):
        for m in (2, 3, 4, 7, 12):
            for v in (0, 0.01, 0.10, 0.25):
                pmf = cmr.folded_binomial_pmf(v, m)
                self.assertEqual(len(pmf), m // 2 + 1)
                self.assertAlmostEqual(float(sum(pmf)), 1.0, places=12)
                self.assertGreaterEqual(float(min(pmf)), -1e-14)

    def test_folded_binomial_pmf_handles_large_arms(self):
        pmf = cmr.folded_binomial_pmf(0.10, 2000)
        self.assertEqual(len(pmf), 1001)
        self.assertTrue(np.all(np.isfinite(pmf)))
        self.assertAlmostEqual(float(np.sum(pmf)), 1.0, places=12)

    def test_large_binary_two_arm_auto_dispatch_is_finite(self):
        n_per_arm = 1200
        y = np.r_[np.tile([0, 1], n_per_arm // 2), np.tile([0, 0, 1, 0], n_per_arm // 4)]
        d = np.r_[np.ones(n_per_arm), np.zeros(n_per_arm)]
        fit = cmr.cmr_two_arm(y, d, alpha=0.05, method="auto")
        self.assertEqual(fit.method, "bernoulli")
        self.assertTrue(np.isfinite(fit.pi))
        self.assertTrue(np.isfinite(fit.U_CMR))

    def test_variance_bounds_dispatcher_is_closed(self):
        with self.assertRaisesRegex(ValueError, "unknown variance-bound method"):
            variance_bounds_by_method([0, 1, 0, 1], 0.01, 0.01, method="not_a_method")

    def test_exact_bounds_drop_missing_by_default(self):
        y = [0, 1, float("nan"), 1, 0]
        bounds = cmr.variance_bounds_bernoulli_exact(y, beta_l=0.05, beta_u=0.05)
        self.assertEqual(bounds["n"], 4)
        with self.assertRaisesRegex(ValueError, "na_rm=False"):
            cmr.variance_bounds_bernoulli_exact(
                y,
                beta_l=0.05,
                beta_u=0.05,
                na_rm=False,
            )

    def test_one_sided_coverage_holds_on_grid(self):
        beta_l = 0.05
        beta_u = 0.05
        for m in (2, 3, 5, 8):
            j_values = range(m // 2 + 1)
            lower = [bernoulli_lower_bound(j, m, beta_l) for j in j_values]
            upper = [bernoulli_upper_bound(j, m, beta_u) for j in j_values]
            for k in range(21):
                v = k * 0.25 / 20
                pmf = cmr.folded_binomial_pmf(v, m)
                lower_miss = sum(p for p, l in zip(pmf, lower, strict=True) if l > v + 1e-9)
                upper_miss = sum(p for p, u in zip(pmf, upper, strict=True) if u < v - 1e-9)
                self.assertLessEqual(lower_miss, beta_l + 1e-8)
                self.assertLessEqual(upper_miss, beta_u + 1e-8)

    def test_auto_dispatch(self):
        y_binary = [0, 1, 0, 1, 0, 0, 0, 1]
        d = [1, 1, 1, 1, 0, 0, 0, 0]
        rect_binary = cmr.rectangle_two_arm(y_binary, d, alpha=0.05, method="auto")
        self.assertEqual(rect_binary.method, "bernoulli")

        y_bounded = [0.1, 0.9, 0.2, 0.7, 0.3, 0.4, 0.5, 0.6]
        rect_bounded = cmr.rectangle_two_arm(y_bounded, d, alpha=0.05, method="auto")
        self.assertEqual(rect_bounded.method, "bounded")

    def test_auto_dispatch_uses_raw_scale_before_normalization(self):
        y_two_valued = [2, 5, 2, 5, 5, 2, 5, 2]
        d = [1, 1, 1, 1, 0, 0, 0, 0]
        rect = cmr.rectangle_two_arm(y_two_valued, d, alpha=0.05, method="auto", normalize=True)
        self.assertEqual(rect.method, "bounded")

    def test_bernoulli_two_arm_alias_is_exported(self):
        self.assertIs(cmr.rectangle_bernoulli_two_arm, cmr.rectangle_bernoulli_binary)


if __name__ == "__main__":
    unittest.main()
