# Convert CMR target shares to integer allocation counts

Convert the continuous assignment shares returned by a CMR rule into
executable integer counts for a main-wave sample. Counts are rounded by
the deterministic largest-remainder rule. When `x` is a CMR result
object, `realize_allocation()` also recomputes the regret certificate at
the realized integer shares whenever the result contains enough
rectangle information.

## Usage

``` r
realize_allocation(
  x,
  n_main = NULL,
  strata_counts = NULL,
  min_per_arm = 1L,
  max_vertices = 65536L
)

# S3 method for class 'cmr_allocation'
print(x, ...)
```

## Arguments

- x:

  A CMR result object, an unnamed scalar two-arm treatment share, or a
  named vector of target assignment shares. Named target vectors must
  have at least two arms or cells. Multi-arm targets should be named by
  arm, with control arm `"0"` when using CMR multi-arm fits. Stratified
  fixed-count targets currently support two-arm cells named like `"1:A"`
  and `"0:A"`.

- n_main:

  Main-wave sample size to allocate. Required unless `strata_counts` is
  supplied. If both are supplied, `n_main` must equal the sum of
  `strata_counts`.

- strata_counts:

  Optional named vector or list of fixed main-wave counts by stratum.
  When supplied, treatment/control counts are rounded within each
  stratum while preserving the stratum totals exactly. Unknown strata,
  missing strata, and non-two-arm cells are rejected rather than
  silently ignored.

- min_per_arm:

  Minimum integer count assigned to each positive target share. Set to
  `0` when zero counts are acceptable.

- max_vertices:

  Maximum number of hyperrectangle vertices to enumerate when
  recomputing multi-arm or stratified certificates.

- ...:

  Reserved for future extensions.

## Value

A list of class `cmr_allocation` with integer `counts`, realized
`shares`, realized `pi`, normalized `target_pi`, total `n_main`,
rounding metadata, continuous and realized CMR certificates when
available, and diagnostics. The diagnostics field
`certificate_recomputed` is `TRUE` only when a realized certificate was
recomputed from rectangle information.

## See also

Other assignment helpers:
[`assign_balance()`](https://juancyamin.github.io/cmrdesign/reference/assign_balance.md),
[`multiarm_variance_objective()`](https://juancyamin.github.io/cmrdesign/reference/multiarm_variance_objective.md),
[`stratified_variance_objective()`](https://juancyamin.github.io/cmrdesign/reference/stratified_variance_objective.md),
[`variance_objective()`](https://juancyamin.github.io/cmrdesign/reference/variance_objective.md)

## Examples

``` r
set.seed(21)
d <- rep(c(1, 0), each = 40)
y <- c(rbeta(40, 2, 6), rbeta(40, 4, 4))
fit <- cmr_two_arm(y, d)
realize_allocation(fit, n_main = 101)
#> <cmr_allocation>
#>   counts: treatment=51, control=50
#>   n_main: 101
#>   realized_U_CMR: 0.255

realize_allocation(c("0" = 0.34, "1" = 0.33, "2" = 0.33), n_main = 10,
                   min_per_arm = 0)
#> <cmr_allocation>
#>   counts: 0=4, 1=3, 2=3
#>   n_main: 10
```
