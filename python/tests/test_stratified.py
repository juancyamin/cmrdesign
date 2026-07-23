import unittest

import cmrdesign as cmr


class StratifiedTests(unittest.TestCase):
    def test_objective_oracle_and_neyman_agree(self):
        shares = {"A": 0.4, "B": 0.6}
        variances = {
            "treatment": {"A": 0.04, "B": 0.16},
            "control": {"A": 0.09, "B": 0.01},
        }
        pi = cmr.assign_stratified_neyman(variances, shares)
        self.assertAlmostEqual(sum(pi.values()), 1, places=12)
        self.assertAlmostEqual(
            cmr.stratified_variance_objective(pi, variances, shares),
            cmr.stratified_oracle_variance(variances, shares),
            places=12,
        )
        self.assertAlmostEqual(cmr.stratified_regret(pi, variances, shares), 0, places=12)

    def test_one_stratum_reduces_to_two_arm_cmr(self):
        shares = {"A": 1.0}
        rectangle = {
            "lower": {"treatment": {"A": 0.01}, "control": {"A": 0.04}},
            "upper": {"treatment": {"A": 0.09}, "control": {"A": 0.16}},
        }
        rect_two = {"v_l1": 0.01, "v_u1": 0.09, "v_l0": 0.04, "v_u0": 0.16}
        fit_two = cmr.cmr_two_arm_from_rectangle(rect_two)
        fit_stratified = cmr.cmr_stratified_from_rectangle(rectangle, shares)
        self.assertAlmostEqual(fit_stratified.pi["1:A"], fit_two.pi, places=6)
        self.assertAlmostEqual(fit_stratified.pi["0:A"], 1 - fit_two.pi, places=6)
        self.assertAlmostEqual(fit_stratified.U_CMR, fit_two.U_CMR, places=6)

    def test_full_rectangle_returns_representative_balance(self):
        shares = {"A": 0.2, "B": 0.3, "C": 0.5}
        lower = {
            "treatment": {"A": 0, "B": 0, "C": 0},
            "control": {"A": 0, "B": 0, "C": 0},
        }
        upper = {
            "treatment": {"A": 0.25, "B": 0.25, "C": 0.25},
            "control": {"A": 0.25, "B": 0.25, "C": 0.25},
        }
        fit = cmr.cmr_stratified_from_rectangle({"lower": lower, "upper": upper}, shares)
        for stratum, share in shares.items():
            self.assertAlmostEqual(fit.pi[f"1:{stratum}"], share / 2, places=12)
            self.assertAlmostEqual(fit.pi[f"0:{stratum}"], share / 2, places=12)
            self.assertAlmostEqual(fit.extra["sampling_margin"][stratum], share, places=12)
            self.assertAlmostEqual(fit.extra["treatment_margin"][stratum], 0.5, places=12)
        self.assertTrue(fit.diagnostics["full_rectangle"])
        self.assertEqual(fit.diagnostics["solver"], "full_rectangle_closed_form")

    def test_collapsed_rectangle_uses_closed_form(self):
        shares = {"A": 1.0}
        rectangle = {
            "lower": {"treatment": {"A": 0.04}, "control": {"A": 0.09}},
            "upper": {"treatment": {"A": 0.04}, "control": {"A": 0.09}},
        }
        fit = cmr.cmr_stratified_from_rectangle(rectangle, shares)
        self.assertTrue(fit.diagnostics["collapsed_rectangle"])
        self.assertEqual(fit.diagnostics["solver"], "collapsed_closed_form")
        self.assertAlmostEqual(fit.U_CMR, 0, places=12)

    def test_shrinking_rectangle_weakly_lowers_certificate(self):
        shares = {"A": 0.4, "B": 0.6}
        big = {
            "lower": {
                "treatment": {"A": 0, "B": 0},
                "control": {"A": 0, "B": 0},
            },
            "upper": {
                "treatment": {"A": 0.25, "B": 0.25},
                "control": {"A": 0.25, "B": 0.25},
            },
        }
        small = {
            "lower": {
                "treatment": {"A": 0.01, "B": 0.04},
                "control": {"A": 0.02, "B": 0.03},
            },
            "upper": {
                "treatment": {"A": 0.08, "B": 0.12},
                "control": {"A": 0.09, "B": 0.10},
            },
        }
        fit_big = cmr.cmr_stratified_from_rectangle(big, shares)
        fit_small = cmr.cmr_stratified_from_rectangle(small, shares)
        self.assertLessEqual(fit_small.U_CMR, fit_big.U_CMR + 1e-8)


if __name__ == "__main__":
    unittest.main()
