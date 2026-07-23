"""Appendix E pilot-planning example."""

import cmrdesign as cmr

plan = cmr.cmr_plan(
    n=1000,
    sigma1=0.50,
    sigma0=0.25,
    alpha=0.05,
    method="bounded",
    desired_pilot=72,
    accounting="design_only",
)

print(plan["band"])
print(plan["recommendation"])
