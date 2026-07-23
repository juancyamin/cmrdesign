import math
import unittest

import cmrdesign as cmr


class ResultRepresentationTests(unittest.TestCase):
    def test_cmr_result_repr_is_compact(self):
        y = [0, 1, 0, 1, 1, 1, 0, 0, 0, 0]
        d = [1, 1, 1, 1, 1, 0, 0, 0, 0, 0]
        fit = cmr.cmr_two_arm(y, d, alpha=0.10, method="bernoulli")

        text = repr(fit)
        self.assertIn("CMRResult", text)
        self.assertIn("pi=", text)
        self.assertIn("U_CMR=", text)
        self.assertIn("method='bernoulli'", text)
        self.assertIn("n=10", text)
        self.assertNotIn("confidence_set", text)

    def test_unbounded_fallback_repr_includes_status(self):
        y = [0, 2] * 20
        d = [1] * 20 + [0] * 20
        fit = cmr.cmr_unbounded(y, d, psi=1, alpha=0.05)

        text = repr(fit)
        self.assertTrue(math.isinf(fit.U_CMR))
        self.assertIn("U_CMR=inf", text)
        self.assertIn("pilot_too_small", text)

    def test_rectangle_result_repr_is_compact(self):
        y = [0, 1, 0, 1, 1, 1, 0, 0, 0, 0]
        d = [1, 1, 1, 1, 1, 0, 0, 0, 0, 0]
        rect = cmr.rectangle_two_arm(y, d, alpha=0.10, method="bernoulli")

        text = repr(rect)
        self.assertIn("RectangleResult", text)
        self.assertIn("method='bernoulli'", text)
        self.assertIn("n=10", text)
        self.assertNotIn("rectangle=", text)


if __name__ == "__main__":
    unittest.main()
