"""Conditional Minimax Regret design rules."""

from importlib.metadata import PackageNotFoundError, version

from .core import assign_neyman, oracle_variance, regret, variance_objective
from .multiarm import (
    assign_multiarm_neyman,
    cmr_multiarm,
    cmr_multiarm_from_rectangle,
    multiarm_oracle_variance,
    multiarm_rectangle_vertices,
    multiarm_regret,
    multiarm_variance_objective,
    rectangle_multiarm,
)
from .multiple_outcomes import cmr_multiple_outcomes, rectangle_multiple_outcomes
from .planning import (
    activation_threshold_bernoulli,
    activation_threshold_bounded,
    break_even_pilot_share,
    cmr_plan,
    pilot_plan,
    pilot_viability_band,
)
from .proxy import (
    cmr_delayed_outcome,
    cmr_proxy,
    rectangle_delayed_outcome,
    rectangle_proxy,
)
from .rectangles import (
    rectangle_bernoulli_binary,
    rectangle_binary,
    rectangle_bounded_binary,
    rectangle_two_arm,
)
from .results import CMRResult, RectangleResult
from .stratified import (
    assign_stratified_neyman,
    cmr_stratified,
    cmr_stratified_from_rectangle,
    rectangle_stratified,
    stratified_oracle_variance,
    stratified_rectangle_vertices,
    stratified_regret,
    stratified_variance_objective,
)
from .two_arm import (
    binary_rectangle_corners,
    binary_rectangle_regret,
    cmr_binary,
    cmr_binary_from_rectangle,
    cmr_two_arm,
    cmr_two_arm_from_rectangle,
)
from .unbounded import (
    cmr_unbounded,
    cmr_unbounded_from_rectangle,
    rectangle_unbounded,
    variance_bounds_unbounded_mom,
)
from .variance_bounds import (
    folded_binomial_pmf,
    folded_binomial_tails,
    variance_bounds_bernoulli_exact,
    variance_bounds_martinez_taboada_ramdas,
    variance_bounds_maurer_pontil,
)

try:
    __version__ = version("cmrdesign")
except PackageNotFoundError:  # pragma: no cover - source tree without install
    __version__ = "0.0.0.9000"

__all__ = [
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
    "rectangle_binary",
    "rectangle_bounded_binary",
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
]
