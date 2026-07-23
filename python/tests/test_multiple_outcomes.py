import unittest

import numpy as np

import cmrdesign as cmr


class MultipleOutcomeTests(unittest.TestCase):
    def test_index_reduces_to_two_arm_cmr_on_weighted_index(self):
        y = np.asarray(
            [
                [0.1, 0.2],
                [0.9, 0.7],
                [0.2, 0.3],
                [0.8, 0.9],
                [0.3, 0.4],
                [0.4, 0.3],
                [0.5, 0.7],
                [0.6, 0.5],
            ]
        )
        d = [1, 1, 1, 1, 0, 0, 0, 0]
        weights = np.asarray([0.25, 0.75])
        fit_index = cmr.cmr_multiple_outcomes(
            y,
            d,
            weights=weights,
            estimand="index",
            method="bounded",
        )
        fit_manual = cmr.cmr_two_arm(y @ weights, d, method="bounded")
        self.assertAlmostEqual(fit_index.pi, fit_manual.pi, places=12)
        self.assertAlmostEqual(fit_index.U_CMR, fit_manual.U_CMR, places=12)

    def test_coprimary_rectangle_is_weighted_endpoint_sum(self):
        y = np.asarray(
            [
                [0, 1],
                [1, 0],
                [0, 1],
                [1, 0],
                [1, 0],
                [0, 1],
                [0, 1],
                [1, 0],
            ],
            dtype=float,
        )
        d = [1, 1, 1, 1, 0, 0, 0, 0]
        weights = np.asarray([0.4, 0.6])
        rect = cmr.rectangle_multiple_outcomes(
            y,
            d,
            weights=weights,
            method="bernoulli",
        )
        bounds = rect.extra["outcome_bounds"]
        l1 = sum(
            weights[j] * bounds[f"outcome_{j + 1}"]["treatment"]["L"]
            for j in range(len(weights))
        )
        u0 = sum(
            weights[j] * bounds[f"outcome_{j + 1}"]["control"]["U"]
            for j in range(len(weights))
        )
        self.assertAlmostEqual(rect.rectangle["v_l1"], l1, places=12)
        self.assertAlmostEqual(rect.rectangle["v_u0"], u0, places=12)
        self.assertAlmostEqual(rect.joint_error_bound, 0.05, places=12)


if __name__ == "__main__":
    unittest.main()
