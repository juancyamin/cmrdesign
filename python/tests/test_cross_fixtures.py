import json
import math
import unittest
from pathlib import Path

import cmrdesign as cmr


def assert_close(testcase, actual, expected, tol):
    if expected == "Inf":
        testcase.assertTrue(math.isinf(actual))
        return
    if isinstance(expected, dict):
        testcase.assertIsInstance(actual, dict)
        for key, value in expected.items():
            testcase.assertIn(key, actual)
            assert_close(testcase, actual[key], value, tol)
        return
    if isinstance(expected, list):
        testcase.assertEqual(len(actual), len(expected))
        for actual_item, expected_item in zip(actual, expected, strict=True):
            assert_close(testcase, actual_item, expected_item, tol)
        return
    if isinstance(expected, bool):
        testcase.assertEqual(bool(actual), expected)
        return
    if isinstance(expected, str) or expected is None:
        testcase.assertEqual(actual, expected)
        return
    testcase.assertAlmostEqual(float(actual), float(expected), delta=tol)


def case_by_name(fixture, name):
    for case in fixture["cases"]:
        if case["name"] == name:
            return case
    raise AssertionError(f"Missing fixture case: {name}")


def two_arm_expected(result):
    out = {
        "pi": result.pi,
        "U_CMR": result.U_CMR,
        "rectangle": result.rectangle,
        "method": result.method,
    }
    out["diagnostics"] = result.diagnostics
    if "corner_regrets" in result.extra:
        out["corner_regrets"] = result.extra["corner_regrets"]
    return out


class CrossFixtureTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.root = Path(__file__).resolve().parents[2] / "spec" / "test_fixtures"
        expected = {
            "bernoulli_exact.json",
            "bounded_mp.json",
            "bounded_mtr.json",
            "multiarm.json",
            "multiple_outcomes.json",
            "pilot_planning.json",
            "proxy.json",
            "rectangles_binary.json",
            "stratified.json",
        }
        found = {path.name for path in cls.root.glob("*.json")}
        if found != expected:
            raise AssertionError(f"Fixture set mismatch: {found ^ expected}")
        cls.fixtures = {
            path.name: json.loads(path.read_text())
            for path in cls.root.glob("*.json")
        }

    def test_all_declared_fixtures_are_valid_json(self):
        for payload in self.fixtures.values():
            self.assertEqual(payload["schema_version"], 1)
            self.assertEqual(payload["source"], "R reference implementation")
            self.assertIn("purpose", payload)
            self.assertTrue(payload["purpose"])

    def test_two_arm_rectangle_fixtures(self):
        fixture = self.fixtures["rectangles_binary.json"]
        tol = fixture["tolerance"]
        for case in fixture["cases"]:
            fit = cmr.cmr_two_arm_from_rectangle(case["input"]["rectangle"])
            assert_close(self, two_arm_expected(fit), case["expected"], tol)

    def test_maurer_pontil_fixtures(self):
        fixture = self.fixtures["bounded_mp.json"]
        tol = fixture["tolerance"]
        bounds_case = case_by_name(fixture, "variance_bounds_rep_01")
        bounds = cmr.variance_bounds_maurer_pontil(
            bounds_case["input"]["y"],
            bounds_case["input"]["beta_l"],
            bounds_case["input"]["beta_u"],
        )
        assert_close(self, bounds, bounds_case["expected"], tol)

        rect_case = case_by_name(fixture, "two_arm_rectangle")
        rect = cmr.rectangle_two_arm(**rect_case["input"])
        fit = cmr.cmr_two_arm(**rect_case["input"])
        actual = {
            "rectangle": rect.rectangle,
            "n": rect.n,
            "vhat": rect.vhat,
            "beta": rect.beta,
            "joint_error_bound": rect.joint_error_bound,
            "pi": fit.pi,
            "U_CMR": fit.U_CMR,
            "method": fit.method,
        }
        assert_close(self, actual, rect_case["expected"], tol)

        auto_case = case_by_name(fixture, "auto_normalize_raw_two_value")
        auto_rect = cmr.rectangle_two_arm(**auto_case["input"])
        auto_fit = cmr.cmr_two_arm(**auto_case["input"])
        actual = {
            "rectangle": auto_rect.rectangle,
            "method": auto_rect.method,
            "pi": auto_fit.pi,
            "U_CMR": auto_fit.U_CMR,
        }
        assert_close(self, actual, auto_case["expected"], tol)

    def test_mtr_fixtures(self):
        fixture = self.fixtures["bounded_mtr.json"]
        tol = fixture["tolerance"]
        bounds_case = case_by_name(fixture, "variance_bounds_regression")
        bounds = cmr.variance_bounds_martinez_taboada_ramdas(
            bounds_case["input"]["y"],
            bounds_case["input"]["beta_l"],
            bounds_case["input"]["beta_u"],
        )
        assert_close(self, bounds, bounds_case["expected"], tol)

        fit_case = case_by_name(fixture, "two_arm_mtr")
        fit = cmr.cmr_two_arm(**fit_case["input"])
        assert_close(self, two_arm_expected(fit), fit_case["expected"], tol)

    def test_bernoulli_fixtures(self):
        fixture = self.fixtures["bernoulli_exact.json"]
        tol = fixture["tolerance"]
        pmf_case = case_by_name(fixture, "folded_pmf_m4_v010")
        pmf = list(map(float, cmr.folded_binomial_pmf(**pmf_case["input"])))
        assert_close(self, {"pmf": pmf}, pmf_case["expected"], tol)

        bounds_case = case_by_name(fixture, "variance_bounds_binary")
        bounds = cmr.variance_bounds_bernoulli_exact(
            bounds_case["input"]["y"],
            bounds_case["input"]["beta_l"],
            bounds_case["input"]["beta_u"],
        )
        assert_close(self, bounds, bounds_case["expected"], tol)

        fit_case = case_by_name(fixture, "auto_dispatch_two_arm")
        fit = cmr.cmr_two_arm(**fit_case["input"])
        assert_close(self, two_arm_expected(fit), fit_case["expected"], tol)

    def test_multiarm_fixtures(self):
        fixture = self.fixtures["multiarm.json"]
        tol = fixture["tolerance"]
        neyman_case = case_by_name(fixture, "known_variance_neyman")
        variances = neyman_case["input"]["variances"]
        pi = cmr.assign_multiarm_neyman(variances)
        actual = {
            "pi": pi,
            "objective": cmr.multiarm_variance_objective(pi, variances),
            "oracle": cmr.multiarm_oracle_variance(variances),
            "regret": cmr.multiarm_regret(pi, variances),
        }
        assert_close(self, actual, neyman_case["expected"], tol)

        for name in ("one_treatment_reduction", "general_asymmetric_3_components", "full_rectangle_k4"):
            case = case_by_name(fixture, name)
            fit = cmr.cmr_multiarm_from_rectangle(case["input"]["rectangle"])
            actual = {"pi": fit.pi, "U_CMR": fit.U_CMR}
            if "full_rectangle" in case["expected"]:
                actual["full_rectangle"] = fit.diagnostics["full_rectangle"]
            assert_close(self, actual, case["expected"], case.get("tolerance", tol))

    def test_stratified_fixtures(self):
        fixture = self.fixtures["stratified.json"]
        tol = fixture["tolerance"]
        neyman_case = case_by_name(fixture, "known_variance_neyman")
        variances = neyman_case["input"]["variances"]
        shares = neyman_case["input"]["strata_share"]
        pi = cmr.assign_stratified_neyman(variances, shares)
        actual = {
            "pi": pi,
            "objective": cmr.stratified_variance_objective(pi, variances, shares),
            "oracle": cmr.stratified_oracle_variance(variances, shares),
            "regret": cmr.stratified_regret(pi, variances, shares),
        }
        assert_close(self, actual, neyman_case["expected"], tol)

        for name in (
            "one_stratum_reduction",
            "general_asymmetric_2_strata",
            "full_rectangle_representative_balance",
        ):
            case = case_by_name(fixture, name)
            fit = cmr.cmr_stratified_from_rectangle(
                case["input"]["rectangle"],
                case["input"]["strata_share"],
            )
            actual = {"pi": fit.pi, "U_CMR": fit.U_CMR}
            if "sampling_margin" in case["expected"]:
                actual["sampling_margin"] = fit.extra["sampling_margin"]
                actual["treatment_margin"] = fit.extra["treatment_margin"]
            if "full_rectangle" in case["expected"]:
                actual["full_rectangle"] = fit.diagnostics["full_rectangle"]
            assert_close(self, actual, case["expected"], case.get("tolerance", tol))

    def test_multiple_outcome_fixtures(self):
        fixture = self.fixtures["multiple_outcomes.json"]
        tol = fixture["tolerance"]
        index_case = case_by_name(fixture, "weighted_index")
        fit = cmr.cmr_multiple_outcomes(**index_case["input"])
        assert_close(self, two_arm_expected(fit), index_case["expected"], tol)

        coprimary_case = case_by_name(fixture, "coprimary_bernoulli")
        rect = cmr.rectangle_multiple_outcomes(**coprimary_case["input"])
        actual = {
            "rectangle": rect.rectangle,
            "joint_error_bound": rect.joint_error_bound,
            "vhat": rect.vhat,
            "beta": rect.beta,
            "method": rect.method,
        }
        assert_close(self, actual, coprimary_case["expected"], tol)

    def test_proxy_fixtures(self):
        fixture = self.fixtures["proxy.json"]
        tol = fixture["tolerance"]
        for name in ("zero_bridge_matches_direct", "large_bridge_full_rectangle", "nonzero_bridge"):
            case = case_by_name(fixture, name)
            fit = cmr.cmr_proxy(**case["input"])
            actual = two_arm_expected(fit)
            if "direct" in case["expected"]:
                direct_input = {
                    "y": case["input"]["proxy_y"],
                    "d": case["input"]["d"],
                    "method": case["input"]["method"],
                }
                actual["direct"] = two_arm_expected(cmr.cmr_two_arm(**direct_input))
            if "proxy_rectangle" in case["expected"]:
                actual["proxy_rectangle"] = fit.confidence_set.extra["bridge"]["proxy_rectangle"]
                actual["bridge"] = fit.confidence_set.extra["bridge"]["assumption"]
            assert_close(self, actual, case["expected"], tol)

    def test_planning_fixtures(self):
        fixture = self.fixtures["pilot_planning.json"]
        tol = fixture["tolerance"]
        activation_case = case_by_name(fixture, "activation_thresholds")
        actual = {
            "bounded_005": cmr.activation_threshold_bounded(0.05),
            "bounded_010": cmr.activation_threshold_bounded(0.10),
            "bounded_001": cmr.activation_threshold_bounded(0.01),
            "bernoulli_005": cmr.activation_threshold_bernoulli(0.05),
        }
        assert_close(self, actual, activation_case["expected"], tol)

        for name in ("design_only_break_even", "pooled_keeps_activation"):
            case = case_by_name(fixture, name)
            plan = cmr.cmr_plan(**case["input"])
            actual = {
                "activation_threshold": plan["band"]["activation_threshold"],
                "break_even_total": plan["band"]["break_even_total"],
                "default_two_thirds_power": plan["default_two_thirds_power"],
                "desired_status": plan["desired_status"],
            }
            for key in ("break_even_share", "suggested_pilot", "min_feasible", "max_feasible"):
                if key in case["expected"]:
                    actual[key] = plan["band"][key] if key in plan["band"] else plan[key]
            assert_close(self, actual, case["expected"], tol)


if __name__ == "__main__":
    unittest.main()
