import math
import unittest

import cmrdesign as cmr


class PlanningTests(unittest.TestCase):
    def test_activation_thresholds_match_reference_values(self):
        self.assertEqual(cmr.activation_threshold_bounded(0.05), 72)
        self.assertEqual(cmr.activation_threshold_bounded(0.10), 60)
        self.assertEqual(cmr.activation_threshold_bounded(0.01), 96)
        self.assertEqual(cmr.activation_threshold_bernoulli(0.05), 4)

    def test_design_only_planning_applies_break_even_cap(self):
        plan = cmr.cmr_plan(
            n=1000,
            sigma1=0.5,
            sigma0=0.25,
            alpha=0.05,
            method="bounded",
            desired_pilot=100,
            accounting="design_only",
        )
        self.assertEqual(plan["band"]["activation_threshold"], 72)
        self.assertAlmostEqual(plan["band"]["break_even_share"], 0.1, places=12)
        self.assertEqual(plan["default_two_thirds_power"], 100)
        self.assertEqual(plan["desired_status"], "above_break_even_cap")

    def test_pooled_planning_keeps_activation_but_drops_cap(self):
        plan = cmr.cmr_plan(
            n=1000,
            sigma1=0.5,
            sigma0=0.25,
            alpha=0.05,
            method="bounded",
            desired_pilot=100,
            accounting="pooled",
        )
        self.assertTrue(math.isinf(plan["band"]["break_even_total"]))
        self.assertEqual(plan["desired_status"], "inside_viability_band")


if __name__ == "__main__":
    unittest.main()
