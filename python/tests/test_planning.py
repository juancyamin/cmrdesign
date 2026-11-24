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
        # The paper's band is 72 <= m <= 100 in this example: the cap is feasible.
        self.assertEqual(plan["band"]["max_feasible"], 100)
        self.assertEqual(plan["desired_status"], "inside_viability_band")
        self.assertEqual(plan["two_thirds_status"], "inside_viability_band")

    def test_strict_upper_excludes_pilot_equal_to_cap(self):
        plan = cmr.cmr_plan(
            n=1000, sigma1=0.5, sigma0=0.25, desired_pilot=100, strict_upper=True
        )
        self.assertEqual(plan["band"]["max_feasible"], 98)
        self.assertEqual(plan["desired_status"], "above_break_even_cap")
        self.assertEqual(plan["two_thirds_status"], "above_break_even_cap")

    def test_band_reproduces_paper_examples(self):
        band = cmr.pilot_viability_band(n=1000, sigma1=0.5, sigma0=0.25)
        self.assertEqual((band["min_feasible"], band["max_feasible"]), (72, 100))
        band = cmr.pilot_viability_band(n=1000, sigma1=0.5, sigma0=0.25, alpha=0.01)
        self.assertEqual((band["min_feasible"], band["max_feasible"]), (96, 100))
        self.assertEqual(cmr.cmr_plan(600, 0.5, 0.25)["default_two_thirds_power"], 72)
        self.assertEqual(
            cmr.cmr_plan(10000, 0.5, 0.25)["default_two_thirds_power"], 466
        )

    def test_two_thirds_status_reports_position_in_band(self):
        above = cmr.cmr_plan(n=3000, sigma1=0.18, sigma0=0.28)
        self.assertEqual(above["default_two_thirds_power"], 210)
        self.assertEqual(above["two_thirds_status"], "above_break_even_cap")
        pooled = cmr.cmr_plan(n=3000, sigma1=0.18, sigma0=0.28, accounting="pooled")
        self.assertEqual(pooled["two_thirds_status"], "inside_viability_band")
        below = cmr.cmr_plan(n=300, sigma1=0.5, sigma0=0.1)
        self.assertEqual(below["default_two_thirds_power"], 46)
        self.assertEqual(below["two_thirds_status"], "below_activation_threshold")

    def test_pilot_is_never_inside_an_empty_band(self):
        plan = cmr.cmr_plan(
            n=50, sigma1=0.5, sigma0=0.1, accounting="pooled", desired_pilot=10
        )
        self.assertFalse(plan["band"]["nonempty"])
        self.assertEqual(plan["desired_status"], "below_activation_threshold")

    def test_break_even_share_handles_zero_variances_quietly(self):
        import warnings

        with warnings.catch_warnings():
            warnings.simplefilter("error")
            self.assertEqual(cmr.break_even_pilot_share(0, 0), 0.0)

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
