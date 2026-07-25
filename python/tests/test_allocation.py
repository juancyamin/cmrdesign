import math
import unittest

import cmrdesign as cmr


class AllocationTests(unittest.TestCase):
    def test_two_arm_fit_rounds_counts_and_recomputes_certificate(self):
        rect = {"v_l1": 0.01, "v_u1": 0.09, "v_l0": 0.04, "v_u0": 0.16}
        fit = cmr.cmr_two_arm_from_rectangle(rect)

        alloc = cmr.realize_allocation(fit, n_main=101)

        self.assertEqual(sum(alloc.counts.values()), 101)
        self.assertEqual(set(alloc.counts), {"treatment", "control"})
        self.assertAlmostEqual(sum(alloc.shares.values()), 1.0)
        self.assertIsNotNone(alloc.realized_U_CMR)
        self.assertGreaterEqual(alloc.realized_U_CMR, fit.U_CMR - 1e-12)
        self.assertTrue(alloc.diagnostics["certificate_recomputed"])

    def test_unbounded_two_arm_fit_recomputes_raw_scale_certificate(self):
        rect = {"v_l1": 0.5, "v_u1": 1.4, "v_l0": 0.2, "v_u0": 1.0}
        fit = cmr.cmr_unbounded_from_rectangle(rect)

        alloc = cmr.realize_allocation(fit, n_main=99)

        self.assertEqual(sum(alloc.counts.values()), 99)
        self.assertTrue(math.isfinite(alloc.realized_U_CMR))
        self.assertGreaterEqual(alloc.realized_U_CMR, fit.U_CMR - 1e-12)

    def test_raw_multiarm_shares_use_largest_remainder_rounding(self):
        alloc = cmr.realize_allocation(
            {"0": 0.34, "1": 0.33, "2": 0.33},
            n_main=10,
            min_per_arm=0,
        )

        self.assertEqual(alloc.counts, {"0": 4, "1": 3, "2": 3})
        self.assertEqual(alloc.shares, {"0": 0.4, "1": 0.3, "2": 0.3})
        self.assertIsNone(alloc.realized_U_CMR)
        self.assertFalse(alloc.diagnostics["certificate_recomputed"])

    def test_named_length_one_targets_are_rejected_as_ambiguous(self):
        with self.assertRaisesRegex(ValueError, "at least two arms or cells"):
            cmr.realize_allocation({"a": 0.4}, n_main=10)
        with self.assertRaisesRegex(ValueError, "at least two arms or cells"):
            cmr.realize_allocation([0.4], n_main=10)

    def test_min_per_arm_is_enforced_for_positive_target_shares(self):
        alloc = cmr.realize_allocation(
            {"a": 0.98, "b": 0.01, "c": 0.01},
            n_main=5,
        )

        self.assertEqual(alloc.counts, {"a": 3, "b": 1, "c": 1})

    def test_multiarm_fit_recomputes_certificate_at_realized_shares(self):
        rect = {
            "v_l0": 0.02,
            "v_u0": 0.08,
            "v_l1": 0.04,
            "v_u1": 0.12,
            "v_l2": 0.01,
            "v_u2": 0.07,
        }
        fit = cmr.cmr_multiarm_from_rectangle(rect)

        alloc = cmr.realize_allocation(fit, n_main=100)

        self.assertEqual(sum(alloc.counts.values()), 100)
        self.assertEqual(set(alloc.counts), {"0", "1", "2"})
        self.assertTrue(math.isfinite(alloc.realized_U_CMR))
        self.assertIn("binding_vertices", alloc.diagnostics)

    def test_stratified_counts_respect_fixed_stratum_sizes(self):
        shares = {"1:A": 0.24, "0:A": 0.16, "1:B": 0.30, "0:B": 0.30}

        alloc = cmr.realize_allocation(shares, strata_counts={"A": 40, "B": 60})

        self.assertEqual(alloc.counts["1:A"] + alloc.counts["0:A"], 40)
        self.assertEqual(alloc.counts["1:B"] + alloc.counts["0:B"], 60)
        self.assertEqual(sum(alloc.counts.values()), 100)
        self.assertEqual(alloc.diagnostics["design"], "stratified")

    def test_stratified_fixed_counts_reject_misspecified_cells_and_strata(self):
        with self.assertRaisesRegex(ValueError, "two-arm stratified targets only"):
            cmr.realize_allocation(
                {"1:A": 0.3, "0:A": 0.3, "2:A": 0.4},
                strata_counts={"A": 10},
                min_per_arm=0,
            )
        with self.assertRaisesRegex(ValueError, "unknown strata"):
            cmr.realize_allocation(
                {"1:A": 0.5, "0:A": 0.5},
                strata_counts={"A": 10, "Z": 10},
            )
        with self.assertRaisesRegex(ValueError, "sum of `strata_counts`"):
            cmr.realize_allocation(
                {"1:A": 0.5, "0:A": 0.5},
                n_main=999,
                strata_counts={"A": 10},
            )

    def test_zero_size_strata_are_allowed_when_other_strata_have_units(self):
        alloc = cmr.realize_allocation(
            {"1:A": 0.25, "0:A": 0.25, "1:B": 0.25, "0:B": 0.25},
            strata_counts={"A": 0, "B": 10},
        )

        self.assertEqual(
            {k: alloc.counts[k] for k in ("1:A", "0:A")},
            {"1:A": 0, "0:A": 0},
        )
        self.assertEqual(sum(alloc.counts.values()), 10)

    def test_stratified_fit_recomputes_certificate_with_fixed_stratum_sizes(self):
        rect = {
            "lower": [[0.01, 0.04], [0.02, 0.03]],
            "upper": [[0.08, 0.12], [0.09, 0.10]],
        }
        fit = cmr.cmr_stratified_from_rectangle(rect, {"A": 0.4, "B": 0.6})

        alloc = cmr.realize_allocation(fit, strata_counts={"A": 40, "B": 60})

        self.assertEqual(alloc.counts["1:A"] + alloc.counts["0:A"], 40)
        self.assertEqual(alloc.counts["1:B"] + alloc.counts["0:B"], 60)
        self.assertTrue(math.isfinite(alloc.realized_U_CMR))
        self.assertTrue(alloc.diagnostics["certificate_recomputed"])

    def test_allocation_diagnostics_distinguish_missing_and_infinite_certificates(self):
        fit = cmr.CMRResult(pi={"a": 0.5, "b": 0.5}, u_cmr=math.inf, rectangle=None)
        alloc = cmr.realize_allocation(fit, n_main=10, min_per_arm=0)

        self.assertEqual(alloc.realized_U_CMR, math.inf)
        self.assertFalse(alloc.diagnostics["certificate_recomputed"])

    def test_zero_realized_positive_arms_warn_and_report_infinite_excess(self):
        fit = cmr.cmr_two_arm_from_rectangle(
            {"v_l1": 0.01, "v_u1": 0.09, "v_l0": 0.04, "v_u0": 0.16}
        )

        with self.assertWarnsRegex(UserWarning, "zero realized units"):
            alloc = cmr.realize_allocation(fit, n_main=1, min_per_arm=0)
        self.assertEqual(alloc.realized_U_CMR, math.inf)
        self.assertEqual(alloc.excess_U_CMR, math.inf)
        self.assertTrue(alloc.diagnostics["certificate_recomputed"])

    def test_allocation_requires_enough_units_for_minimum_counts(self):
        with self.assertRaisesRegex(ValueError, "`n_main` is too small"):
            cmr.realize_allocation({"a": 0.5, "b": 0.5, "c": 0.0}, n_main=1)

    def test_binding_vertex_labels_are_order_independent_corners(self):
        vertices = cmr.multiarm_rectangle_vertices(
            {
                "v_l0": 0.02,
                "v_u0": 0.08,
                "v_l1": 0.04,
                "v_u1": 0.12,
                "v_l2": 0.01,
                "v_u2": 0.07,
            }
        )

        self.assertIn("l0_l1_l2", vertices["vertex_names"])
        self.assertFalse(
            any(name.startswith("vertex_") for name in vertices["vertex_names"])
        )


if __name__ == "__main__":
    unittest.main()
