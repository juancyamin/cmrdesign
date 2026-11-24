# Pilot Planning

`cmr_plan()` implements the pilot-size planning screen from Appendix E of the
accompanying paper (Yamin 2026). It is a
diagnostic tool, not a guarantee that pilot-based CMR will improve every
realized experiment.

## Inputs

The required inputs are:

- `n`: total experimental sample size.
- `sigma1`, `sigma0`: planning standard deviations for treatment and control.

Set `input = "variance"` when passing variances instead of standard deviations.

Core options:

- `alpha`: joint error level used by the variance-bound activation screen, as
  in the estimation functions.
- `method = "bounded"` or `"bernoulli"`.
- `accounting = "design_only"` or `"pooled"`.
- `desired_pilot`: optional pilot size to evaluate.
- `strict_upper`: whether a pilot equal to the break-even cap is excluded. The
  default is `FALSE`/`False`, which matches the band `m_act <= m <= cap` of the
  paper.

## Outputs

The returned object reports:

- `band$activation_threshold` in R or `plan["band"]["activation_threshold"]`
  in Python: smallest even pilot size that clears the method's basic activation
  condition.
- `band$break_even_share` / `plan["band"]["break_even_share"]`: design-only
  break-even pilot share implied by `sigma1` and `sigma0`.
- `band$feasible_pilot_sizes` / `plan["band"]["feasible_pilot_sizes"]`: even
  pilot sizes that clear the screen.
- `suggested_pilot`: the smallest pilot size in the feasible set. It is the
  least costly pilot at which CMR can leave balance. It is a floor, not an
  optimal size.
- `default_two_thirds_power`: the pilot size `2 * ceiling(n^(2/3) / 2)` from the
  two-thirds-power rule of the paper.
- `two_thirds_status`: where that size falls relative to the feasible set.
- `desired_status`: the same classification for a user-supplied pilot size.

The two sizes answer different questions. The two-thirds-power size is the
worst-case-optimal scale of the pilot. The feasible set is a necessary screen
at the planning values you supplied. Under design-only accounting the
two-thirds-power size can exceed the break-even cap, and `two_thirds_status`
then reads `above_break_even_cap`. With `n = 3000`, `sigma1 = 0.18`, and
`sigma0 = 0.28`, for example, the feasible set is 72 to 134 while the
two-thirds-power size is 210. Under pooled accounting the cap does not apply.

## Accounting Choice

`accounting = "design_only"` applies both the activation threshold and the
break-even design screen. `accounting = "pooled"` keeps the activation
threshold but does not impose the design-only break-even cap.

## Example

R:

```r
plan <- cmr_plan(n = 2000, sigma1 = 0.30, sigma0 = 0.45, method = "bounded")
plan
plan$two_thirds_status
```

Python:

```python
import cmrdesign as cmr

plan = cmr.cmr_plan(n=2000, sigma1=0.30, sigma0=0.45, method="bounded")
plan["band"]["min_feasible"], plan["band"]["max_feasible"]
plan["two_thirds_status"]
```
