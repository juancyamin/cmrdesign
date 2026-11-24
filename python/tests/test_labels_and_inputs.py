import math
import unittest
import warnings

import numpy as np

import cmrdesign as cmr


class ArmLabelTests(unittest.TestCase):
    def setUp(self):
        rng = np.random.default_rng(101)
        self.y = np.r_[rng.beta(4, 4, 60), rng.beta(2, 6, 60), rng.beta(5, 3, 60)]

    def test_multiarm_accepts_labels_starting_with_v(self):
        for labels in (
            ["control", "variant_a", "variant_b"],
            ["control", "v1", "v2"],
            ["control", "video", "vaccine"],
        ):
            with self.subTest(labels=labels):
                fit = cmr.cmr_multiarm(
                    self.y,
                    np.repeat(labels, 60),
                    control_arm="control",
                    method="bounded",
                )
                self.assertEqual(list(fit.pi), ["0", *labels[1:]])
                self.assertEqual(list(fit.pilot["n"]), ["0", *labels[1:]])
                self.assertAlmostEqual(sum(fit.pi.values()), 1.0, places=12)

    def test_relabeling_does_not_change_the_allocation(self):
        reference = cmr.cmr_multiarm(self.y, np.repeat([0, 1, 2], 60), method="bounded")
        relabeled = cmr.cmr_multiarm(
            self.y,
            np.repeat(["control", "variant_a", "variant_b"], 60),
            control_arm="control",
            method="bounded",
        )
        np.testing.assert_allclose(
            list(relabeled.pi.values()), list(reference.pi.values())
        )
        self.assertAlmostEqual(relabeled.U_CMR, reference.U_CMR, places=14)

    def test_v_prefix_removed_only_for_variance_names(self):
        prefixed = cmr.assign_multiarm_neyman({"v0": 0.05, "v1": 0.10, "v2": 0.04})
        self.assertEqual(list(prefixed), ["0", "1", "2"])
        kept = cmr.assign_multiarm_neyman({"0": 0.05, "vaccine": 0.10, "video": 0.04})
        self.assertEqual(list(kept), ["0", "vaccine", "video"])
        fit = cmr.cmr_multiarm_from_rectangle(
            {
                "0": {"lower": 0.02, "upper": 0.08},
                "vaccine": {"lower": 0.04, "upper": 0.12},
                "v2": {"lower": 0.01, "upper": 0.07},
            }
        )
        self.assertEqual(list(fit.pi), ["0", "vaccine", "v2"])


class StratumLabelTests(unittest.TestCase):
    def test_stratum_labels_may_contain_colons(self):
        rng = np.random.default_rng(102)
        y = rng.uniform(size=160)
        d = np.tile([1, 0], 80)
        plain = cmr.cmr_stratified(
            y, d, np.repeat(["a", "b"], 80), {"a": 0.4, "b": 0.6}
        )
        labels = ["age:18-30", "age:31+"]
        fit = cmr.cmr_stratified(
            y, d, np.repeat(labels, 80), dict(zip(labels, [0.4, 0.6], strict=True))
        )
        self.assertEqual(
            list(fit.pi), ["1:age:18-30", "0:age:18-30", "1:age:31+", "0:age:31+"]
        )
        np.testing.assert_allclose(list(fit.pi.values()), list(plain.pi.values()))
        allocation = cmr.realize_allocation(
            fit, strata_counts=dict(zip(labels, [40, 60], strict=True))
        )
        self.assertEqual(sum(allocation.counts.values()), 100)

    def test_stratum_without_sample_has_nan_treatment_margin(self):
        fit = cmr.cmr_stratified_from_rectangle(
            {"lower": [[0, 0.02], [0, 0.03]], "upper": [[0, 0.10], [0, 0.12]]},
            {"A": 0.4, "B": 0.6},
        )
        self.assertTrue(math.isnan(fit.extra["treatment_margin"]["A"]))
        self.assertTrue(math.isfinite(fit.extra["treatment_margin"]["B"]))


class DispatchTests(unittest.TestCase):
    def setUp(self):
        self.d = np.repeat([1, 0], 20)
        self.arm = np.repeat([0, 1], 20)
        self.strata = np.tile(["a", "b"], 20)
        self.share = {"a": 0.5, "b": 0.5}
        self.coded = np.r_[
            np.repeat([3.0, 7.0], [5, 15]), np.repeat([3.0, 7.0], [10, 10])
        ]
        self.binary = np.tile([0.0, 1.0], 20)

    def test_auto_uses_raw_values_in_every_design(self):
        kwargs = dict(normalize=True, lower=3, upper=7)
        self.assertEqual(
            cmr.cmr_two_arm(self.coded, self.d, **kwargs).method, "bounded"
        )
        self.assertEqual(
            cmr.cmr_multiarm(self.coded, self.arm, **kwargs).method, "bounded"
        )
        self.assertEqual(
            cmr.cmr_stratified(
                self.coded, self.d, self.strata, self.share, **kwargs
            ).method,
            "bounded",
        )

    def test_explicit_method_is_applied_to_normalized_outcome(self):
        kwargs = dict(method="bernoulli", normalize=True, lower=3, upper=7)
        fit = cmr.cmr_two_arm(self.coded, self.d, **kwargs)
        self.assertEqual(fit.method, "bernoulli")
        self.assertEqual(fit.pilot["normalization"], {"lower": 3.0, "upper": 7.0})
        self.assertEqual(
            cmr.cmr_multiarm(self.coded, self.arm, **kwargs).method, "bernoulli"
        )

    def test_raw_binary_outcomes_skip_normalization_with_a_warning(self):
        for fit_fn in (
            lambda: cmr.cmr_two_arm(
                self.binary, self.d, normalize=True, lower=0, upper=10
            ),
            lambda: cmr.cmr_multiarm(
                self.binary, self.arm, normalize=True, lower=0, upper=10
            ),
        ):
            with self.assertWarnsRegex(UserWarning, "`normalize=True` was ignored"):
                fit = fit_fn()
            self.assertEqual(fit.method, "bernoulli")
        with warnings.catch_warnings():
            warnings.simplefilter("error")
            fit = cmr.cmr_two_arm(self.binary, self.d, normalize=True, lower=0, upper=1)
        self.assertIsNone(fit.pilot["normalization"])

    def test_constant_outcomes_with_data_dependent_normalization_stay_bounded(self):
        with warnings.catch_warnings():
            warnings.simplefilter("ignore")
            fit = cmr.cmr_multiarm(np.full(40, 5.0), self.arm, normalize=True)
        self.assertEqual(fit.method, "bounded")
        self.assertEqual(fit.U_CMR, 0.25)


class InputTests(unittest.TestCase):
    def test_scalar_beta_matches_named_allocation(self):
        rng = np.random.default_rng(103)
        d = np.repeat([1, 0], 60)
        y = np.r_[rng.beta(0.5, 0.5, 60), rng.beta(8, 8, 60)]
        named = {key: 0.01 for key in ("beta_l1", "beta_u1", "beta_l0", "beta_u0")}
        self.assertEqual(
            cmr.cmr_two_arm(y, d, beta=0.01).rectangle,
            cmr.cmr_two_arm(y, d, beta=named).rectangle,
        )
        with self.assertRaisesRegex(ValueError, "exceeds `alpha`"):
            cmr.cmr_two_arm(y, d, beta=0.02)

    def test_errors_name_the_arm_or_cell_that_failed(self):
        y = [0.1, 0.2, 0.3, 0.4, 0.5]
        with self.assertRaisesRegex(ValueError, "Arm `b`: At least two observations"):
            cmr.cmr_multiarm(y, ["ctl", "ctl", "a", "a", "b"], control_arm="ctl")
        with self.assertRaisesRegex(
            ValueError, "Control cell of stratum `B`: At least two observations"
        ):
            cmr.cmr_stratified(
                [*y, 0.6, 0.7],
                [1, 1, 0, 0, 1, 1, 0],
                ["A", "A", "A", "A", "B", "B", "B"],
                {"A": 0.5, "B": 0.5},
            )

    def test_mtr_constants_are_validated(self):
        y = np.linspace(0.1, 0.9, 30)
        with self.assertRaisesRegex(ValueError, r"`c1` must be a scalar in \(0, 1\)"):
            cmr.variance_bounds_martinez_taboada_ramdas(y, 0.05, 0.05, c1=1.5)
        out = cmr.variance_bounds_martinez_taboada_ramdas(y, 0.05, 0.05)
        self.assertEqual(out["statistic"]["constants"]["c1"], 0.5)
        self.assertEqual(out["statistic"]["lower_alpha_split"], 0.5)

    def test_sidak_correction_widens_endpoint_error(self):
        rng = np.random.default_rng(104)
        d = np.repeat([1, 0], 80)
        y = np.r_[rng.beta(0.5, 0.5, 80), rng.beta(8, 8, 80)]
        bonferroni = cmr.cmr_two_arm(y, d, method="bounded")
        sidak = cmr.cmr_two_arm(y, d, method="bounded", correction="sidak_arms")
        self.assertAlmostEqual(
            sidak.beta["beta_l1"], (1 - math.sqrt(0.95)) / 2, places=15
        )
        self.assertAlmostEqual(sidak.joint_error_bound, 0.05, places=12)
        self.assertLessEqual(sidak.rectangle["v_u1"], bonferroni.rectangle["v_u1"])
        self.assertGreaterEqual(sidak.rectangle["v_l1"], bonferroni.rectangle["v_l1"])


class ScaleTests(unittest.TestCase):
    def test_regret_identities(self):
        pi_star = cmr.assign_neyman(0.20, 0.05)
        self.assertAlmostEqual(pi_star, 2 / 3, places=14)
        self.assertAlmostEqual(cmr.regret(pi_star, 0.20, 0.05), 0.0, places=14)
        self.assertAlmostEqual(
            cmr.regret(0.5, 0.20, 0.05),
            (math.sqrt(0.20) - math.sqrt(0.05)) ** 2,
            places=14,
        )
        self.assertEqual(cmr.assign_neyman(0, 0), 0.5)

    def test_nonnegative_scale_allows_unbounded_variances(self):
        with self.assertRaisesRegex(ValueError, r"must lie in \[0, 1/4\]"):
            cmr.regret(0.5, 2, 1)
        self.assertAlmostEqual(
            cmr.regret(0.5, 4, 1, scale="nonnegative"), 1.0, places=14
        )
        self.assertAlmostEqual(
            cmr.oracle_variance(4, 1, scale="nonnegative"), 9.0, places=14
        )
        self.assertAlmostEqual(
            cmr.assign_neyman(4, 1, scale="nonnegative"), 2 / 3, places=14
        )
        self.assertAlmostEqual(
            cmr.variance_objective(0.5, 4, 1, scale="nonnegative"), 10.0, places=14
        )
        with self.assertRaisesRegex(ValueError, "scale"):
            cmr.regret(0.5, 0.1, 0.1, scale="other")


if __name__ == "__main__":
    unittest.main()
