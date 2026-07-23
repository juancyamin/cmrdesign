import unittest

import cmrdesign as cmr


EXPECTED_PUBLIC_API = {
    "CMRResult",
    "RectangleResult",
    "activation_threshold_bernoulli",
    "activation_threshold_bounded",
    "assign_multiarm_neyman",
    "assign_neyman",
    "assign_stratified_neyman",
    "binary_rectangle_corners",
    "binary_rectangle_regret",
    "break_even_pilot_share",
    "cmr_binary",
    "cmr_binary_from_rectangle",
    "cmr_delayed_outcome",
    "cmr_multiarm",
    "cmr_multiarm_from_rectangle",
    "cmr_multiple_outcomes",
    "cmr_plan",
    "cmr_proxy",
    "cmr_stratified",
    "cmr_stratified_from_rectangle",
    "cmr_two_arm",
    "cmr_two_arm_from_rectangle",
    "cmr_unbounded",
    "cmr_unbounded_from_rectangle",
    "folded_binomial_pmf",
    "folded_binomial_tails",
    "multiarm_oracle_variance",
    "multiarm_rectangle_vertices",
    "multiarm_regret",
    "multiarm_variance_objective",
    "oracle_variance",
    "pilot_plan",
    "pilot_viability_band",
    "rectangle_bernoulli_binary",
    "rectangle_bernoulli_two_arm",
    "rectangle_binary",
    "rectangle_bounded_binary",
    "rectangle_bounded_two_arm",
    "rectangle_delayed_outcome",
    "rectangle_multiarm",
    "rectangle_multiple_outcomes",
    "rectangle_proxy",
    "rectangle_stratified",
    "rectangle_two_arm",
    "rectangle_unbounded",
    "regret",
    "stratified_oracle_variance",
    "stratified_rectangle_vertices",
    "stratified_regret",
    "stratified_variance_objective",
    "variance_bounds_bernoulli_exact",
    "variance_bounds_martinez_taboada_ramdas",
    "variance_bounds_maurer_pontil",
    "variance_bounds_unbounded_mom",
    "variance_objective",
}


class PublicAPITests(unittest.TestCase):
    def test_python_all_matches_reviewed_public_surface(self):
        self.assertEqual(set(cmr.__all__), EXPECTED_PUBLIC_API)
        for name in EXPECTED_PUBLIC_API:
            self.assertTrue(hasattr(cmr, name), msg=name)

    def test_aliases_remain_available(self):
        self.assertIs(cmr.cmr_binary, cmr.cmr_two_arm)
        self.assertIs(cmr.cmr_binary_from_rectangle, cmr.cmr_two_arm_from_rectangle)
        self.assertIs(cmr.cmr_delayed_outcome, cmr.cmr_proxy)
        self.assertIs(cmr.rectangle_delayed_outcome, cmr.rectangle_proxy)
        self.assertIs(cmr.rectangle_bounded_two_arm, cmr.rectangle_bounded_binary)
        self.assertIs(cmr.rectangle_bernoulli_two_arm, cmr.rectangle_bernoulli_binary)
        self.assertIs(cmr.pilot_plan, cmr.cmr_plan)


if __name__ == "__main__":
    unittest.main()
