import unittest

import cmrdesign as cmr


class ProxyTests(unittest.TestCase):
    def test_zero_bridge_reduces_to_two_arm_cmr(self):
        y = [0, 1, 0, 1, 1, 0, 0, 1]
        d = [1, 1, 1, 1, 0, 0, 0, 0]
        direct = cmr.cmr_two_arm(y, d, method="bernoulli")
        proxy = cmr.cmr_proxy(y, d, zeta=0, method="bernoulli")
        self.assertAlmostEqual(proxy.pi, direct.pi, places=12)
        self.assertAlmostEqual(proxy.U_CMR, direct.U_CMR, places=12)
        self.assertEqual(proxy.rectangle, direct.rectangle)

    def test_large_bridge_returns_full_primary_variance_space(self):
        y = [0, 1, 0, 1, 1, 0, 0, 1]
        d = [1, 1, 1, 1, 0, 0, 0, 0]
        fit = cmr.cmr_proxy(y, d, zeta=0.5, method="bernoulli")
        self.assertEqual(
            fit.rectangle,
            {"v_l1": 0, "v_u1": 0.25, "v_l0": 0, "v_u0": 0.25},
        )
        self.assertAlmostEqual(fit.pi, 0.5, places=12)
        self.assertAlmostEqual(fit.U_CMR, 0.25, places=12)


if __name__ == "__main__":
    unittest.main()
