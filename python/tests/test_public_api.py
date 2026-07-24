import inspect
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

EXPECTED_MAIN_SIGNATURES = {
    "cmr_two_arm": {
        "params": [
            "y",
            "d",
            "alpha",
            "method",
            "beta",
            "correction",
            "normalize",
            "lower",
            "upper",
            "psi",
            "na_rm",
            "tol",
        ],
        "defaults": {
            "alpha": 0.05,
            "method": "auto",
            "beta": None,
            "correction": "bonferroni",
            "normalize": False,
            "lower": None,
            "upper": None,
            "psi": None,
            "na_rm": True,
            "tol": 1e-11,
        },
    },
    "cmr_unbounded": {
        "params": ["y", "d", "psi", "alpha", "na_rm"],
        "defaults": {"psi": None, "alpha": 0.05, "na_rm": True},
    },
    "cmr_multiarm": {
        "params": [
            "y",
            "arm",
            "alpha",
            "method",
            "beta",
            "control_arm",
            "normalize",
            "lower",
            "upper",
            "na_rm",
            "tol",
            "solver_control",
            "max_vertices",
        ],
        "defaults": {
            "alpha": 0.05,
            "method": "auto",
            "beta": None,
            "control_arm": 0,
            "normalize": False,
            "lower": None,
            "upper": None,
            "na_rm": True,
            "tol": 1e-11,
            "solver_control": None,
            "max_vertices": 65536,
        },
    },
    "cmr_stratified": {
        "params": [
            "y",
            "d",
            "strata",
            "strata_share",
            "alpha",
            "method",
            "beta",
            "normalize",
            "lower",
            "upper",
            "na_rm",
            "tol",
            "solver_control",
            "max_vertices",
        ],
        "defaults": {
            "alpha": 0.05,
            "method": "auto",
            "beta": None,
            "normalize": False,
            "lower": None,
            "upper": None,
            "na_rm": True,
            "tol": 1e-11,
            "solver_control": None,
            "max_vertices": 65536,
        },
    },
    "cmr_multiple_outcomes": {
        "params": [
            "y",
            "d",
            "weights",
            "estimand",
            "alpha",
            "method",
            "beta",
            "na_rm",
            "tol",
        ],
        "defaults": {
            "weights": None,
            "estimand": "coprimary",
            "alpha": 0.05,
            "method": "auto",
            "beta": None,
            "na_rm": True,
            "tol": 1e-11,
        },
    },
    "cmr_proxy": {
        "params": [
            "proxy_y",
            "d",
            "zeta",
            "alpha",
            "method",
            "beta",
            "correction",
            "normalize",
            "lower",
            "upper",
            "na_rm",
            "tol",
        ],
        "defaults": {
            "alpha": 0.05,
            "method": "auto",
            "beta": None,
            "correction": "bonferroni",
            "normalize": False,
            "lower": None,
            "upper": None,
            "na_rm": True,
            "tol": 1e-11,
        },
    },
    "cmr_plan": {
        "params": [
            "n",
            "sigma1",
            "sigma0",
            "alpha",
            "method",
            "input",
            "accounting",
            "desired_pilot",
            "strict_upper",
        ],
        "defaults": {
            "alpha": 0.05,
            "method": "bounded",
            "input": "sd",
            "accounting": "design_only",
            "desired_pilot": None,
            "strict_upper": True,
        },
    },
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

    def test_main_applied_signatures_match_reviewed_surface(self):
        for name, expected in EXPECTED_MAIN_SIGNATURES.items():
            with self.subTest(name=name):
                signature = inspect.signature(getattr(cmr, name))
                self.assertEqual(list(signature.parameters), expected["params"])
                for param_name, default in expected["defaults"].items():
                    self.assertEqual(
                        signature.parameters[param_name].default,
                        default,
                        msg=f"{name}.{param_name}",
                    )


if __name__ == "__main__":
    unittest.main()
