# Pilot Planning

`cmr_plan()` implements an Appendix E-style planning screen for choosing a
pilot size before the main wave. It is a diagnostic tool, not a guarantee that
pilot-based CMR will improve every realized experiment.

## Inputs

The required inputs are:

- `n`: total experimental sample size.
- `sigma1`, `sigma0`: planning standard deviations for treatment and control.

Set `input = "variance"` when passing variances instead of standard deviations.

Core options:

- `alpha`: confidence level parameter used by the variance-bound routine.
- `method = "bounded"` or `"bernoulli"`.
- `accounting = "design_only"` or `"pooled"`.
- `desired_pilot`: optional pilot size to evaluate.

## Outputs

The returned object reports:

- `band$activation_threshold` in R or `plan["band"]["activation_threshold"]`
  in Python: smallest even pilot size that clears the method's basic activation
  condition.
- `band$break_even_share` / `plan["band"]["break_even_share"]`: design-only
  break-even pilot share implied by `sigma1` and `sigma0`.
- `band$feasible_pilot_sizes` / `plan["band"]["feasible_pilot_sizes"]`: even
  pilot sizes that clear the screen.
- `suggested_pilot`: default recommendation within the feasible set.
- `default_two_thirds_power`: the rounded even version of `n^(2/3)`.
- `desired_status`: diagnostics for a user-supplied pilot size.

## Accounting Choice

`accounting = "design_only"` applies both the activation threshold and the
break-even design screen. `accounting = "pooled"` keeps the activation
threshold but does not impose the design-only break-even cap.

## Example

R:

```r
cmr_plan(n = 2000, sigma1 = 0.30, sigma0 = 0.45, method = "bounded")
```

Python:

```python
import cmrdesign as cmr

cmr.cmr_plan(n=2000, sigma1=0.30, sigma0=0.45, method="bounded")
```
