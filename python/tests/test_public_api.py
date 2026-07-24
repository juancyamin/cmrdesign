import inspect
import unittest

import numpy as np

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

    def test_main_result_fields_match_reviewed_contract(self):
        rng = np.random.default_rng(2718)
        n = 24
        d = np.r_[np.ones(n), np.zeros(n)]
        y = np.r_[rng.beta(2, 5, n), rng.beta(4, 4, n)]

        required_attrs = {
            "pi",
            "u_cmr",
            "rectangle",
            "confidence_set",
            "pilot",
            "alpha",
            "beta",
            "method",
            "joint_error_bound",
            "diagnostics",
            "extra",
        }

        def expect_cmr_result(fit):
            self.assertTrue(required_attrs.issubset(fit.__dataclass_fields__))
            self.assertEqual(fit.U_CMR, fit.u_cmr)
            self.assertIsNotNone(fit.confidence_set)
            self.assertIn("confidence_method", fit.diagnostics)
            self.assertIn("joint_error_bound", fit.diagnostics)

        fit_two = cmr.cmr_two_arm(y, d, method="bounded")
        expect_cmr_result(fit_two)
        self.assertEqual(
            set(fit_two.extra),
            {"corners", "corner_regrets", "binding", "correction"},
        )

        y_unbounded = [0, 2] * 180 + [0, 4] * 180
        d_unbounded = [1] * 360 + [0] * 360
        fit_unbounded = cmr.cmr_unbounded(y_unbounded, d_unbounded, psi=1)
        expect_cmr_result(fit_unbounded)
        self.assertIsNone(fit_unbounded.beta)
        self.assertEqual(fit_unbounded.method, "unbounded_mom")
        self.assertTrue(fit_unbounded.diagnostics["unbounded_outcomes"])
        self.assertIn("rho", fit_unbounded.pilot)
        self.assertIn("status", fit_unbounded.pilot)

        arm = np.repeat([0, 1, 2], n)
        y_multiarm = np.r_[
            rng.beta(4, 4, n),
            rng.beta(2, 6, n),
            rng.beta(5, 3, n),
        ]
        fit_multiarm = cmr.cmr_multiarm(y_multiarm, arm, method="bounded")
        expect_cmr_result(fit_multiarm)
        self.assertEqual(fit_multiarm.extra["arms"], ["0", "1", "2"])
        self.assertEqual(fit_multiarm.extra["control_arm"], "0")
        self.assertIn("binding_vertices", fit_multiarm.extra)

        strata = np.repeat(["A", "B"], 2 * n)
        d_strata = np.tile(np.r_[np.ones(n), np.zeros(n)], 2)
        y_strata = np.r_[
            rng.beta(2, 6, n),
            rng.beta(4, 4, n),
            rng.beta(5, 3, n),
            rng.beta(3, 5, n),
        ]
        fit_stratified = cmr.cmr_stratified(
            y_strata,
            d_strata,
            strata,
            {"A": 0.45, "B": 0.55},
            method="bounded",
        )
        expect_cmr_result(fit_stratified)
        self.assertEqual(fit_stratified.extra["cell_names"], ["1:A", "0:A", "1:B", "0:B"])
        self.assertEqual(fit_stratified.extra["strata_share"], {"A": 0.45, "B": 0.55})
        self.assertIn("sampling_margin", fit_stratified.extra)
        self.assertIn("treatment_margin", fit_stratified.extra)

        y_multioutcome = np.column_stack(
            [y, np.r_[rng.beta(5, 3, n), rng.beta(3, 5, n)]]
        )
        fit_multioutcome = cmr.cmr_multiple_outcomes(
            y_multioutcome,
            d,
            weights=[0.6, 0.4],
            method="bounded",
        )
        expect_cmr_result(fit_multioutcome)
        self.assertEqual(fit_multioutcome.extra["estimand"], "coprimary")
        self.assertEqual(fit_multioutcome.extra["weights"], {"outcome_1": 0.6, "outcome_2": 0.4})

        fit_proxy = cmr.cmr_proxy(y, d, zeta=0.05, method="bounded")
        expect_cmr_result(fit_proxy)
        self.assertIn("zeta", fit_proxy.extra)
        self.assertIn("bridge", fit_proxy.extra)
        self.assertIn("abs(primary_sd - proxy_sd)", fit_proxy.diagnostics["bridge"])

        plan = cmr.cmr_plan(1000, 0.5, 0.25)
        self.assertEqual(
            set(plan),
            {
                "band",
                "suggested_pilot",
                "default_two_thirds_power",
                "desired_pilot",
                "desired_status",
                "recommendation",
                "caveat",
            },
        )

    def test_main_error_messages_are_actionable(self):
        with self.assertRaisesRegex(ValueError, "`y` and `d` must have the same length"):
            cmr.cmr_two_arm([0.1, 0.2], [1])

        with self.assertRaisesRegex(ValueError, "`psi` is required"):
            cmr.cmr_unbounded([0, 2] * 180, [1] * 180 + [0] * 180)

        with self.assertRaisesRegex(ValueError, "control arm"):
            cmr.cmr_multiarm([0.1, 0.2, 0.3, 0.4], [1, 1, 2, 2])

        with self.assertRaisesRegex(ValueError, "missing observed strata"):
            cmr.cmr_stratified(
                [0.1, 0.2, 0.3, 0.4],
                [1, 0, 1, 0],
                ["A", "A", "B", "B"],
                {"A": 1.0},
            )

        with self.assertRaisesRegex(ValueError, "`weights` must have length 2"):
            cmr.cmr_multiple_outcomes(
                [[0.1, 0.2], [0.2, 0.3], [0.3, 0.4], [0.4, 0.5]],
                [1, 1, 0, 0],
                weights=[1.0],
            )

        with self.assertRaisesRegex(ValueError, "`zeta` must be nonnegative"):
            cmr.cmr_proxy([0.1, 0.2, 0.3, 0.4], [1, 1, 0, 0], zeta=-0.1)

        with self.assertRaisesRegex(ValueError, "`method` must be 'bounded' or 'bernoulli'"):
            cmr.cmr_plan(1000, 0.5, 0.25, method="unbounded")


if __name__ == "__main__":
    unittest.main()
