# Co-radar plot: radar plot with correlation-based axes

Builds a co-radar plot object: a radar (spider) plot whose axis angles
are determined by the correlation structure of the data (see
[`coradar_pos`](https://CU-Anschutz-GMWG.github.io/VisXplore/reference/coradar_pos.md)),
rather than arbitrary equidistant ordering. Variables are normalized to
a common scale, and one or more group "archetypes" (mean shapes with a
variability band) are summarized for display via
[`plot()`](https://rdrr.io/r/graphics/plot.default.html).

## Usage

``` r
coradar(
  data,
  vars = NULL,
  groups = NULL,
  normalize = c("minmax", "rank", "none"),
  cor_matrix = NULL,
  reference = NULL,
  min_degrees = 10,
  max_iterations = 500
)
```

## Arguments

- data:

  a data.frame

- vars:

  variables to display as axes (default: all numeric columns). Ordinal
  variables can be included by coding them as numeric first.

- groups:

  controls archetype grouping. One of:

  `NULL`

  :   a single overall archetype (default)

  a column name

  :   group by that column of `data` (the column is excluded from the
      axes)

  a single number `k`

  :   k-means clustering with `k` clusters on the normalized variables
      (set a seed first for reproducibility)

  a vector with one value per row

  :   pre-computed group assignments

- normalize:

  how to scale each variable to the common radial axis: `"minmax"`
  (default; observed range maps to `[0, 1]`), `"rank"` (rank-transform,
  robust to skew), or `"none"` (data must already share a comparable
  non-negative scale)

- cor_matrix:

  optional correlation/association matrix (or `visx_cor` object) used
  for axis placement. Defaults to the Spearman correlation of `vars` in
  `reference` if supplied, otherwise in `data`. Use this to lay the axes
  out according to an association structure estimated elsewhere (a
  published matrix, or a reference cohort)

- reference:

  optional data.frame of external reference data containing `vars`, used
  to define the radial scale so that a given radius means the same thing
  across datasets. When `cor_matrix` is not supplied the axis layout is
  estimated from `reference` as well. For `normalize = "minmax"` only
  the reference range matters, so a two-row data.frame of per-variable
  minima and maxima is enough; for `normalize = "rank"` the full
  reference distribution is used. Values in `data` outside the reference
  range are held at the axis bounds (with a warning)

- min_degrees:

  minimum angular separation between axes, in degrees

- max_iterations:

  annealing iterations for the axis layout

## Value

A `visx_coradar` object (S3 class) containing:

- positions:

  named vector of axis angles in radians

- stats:

  data.frame of archetype summaries (group, variable, mean, sd, pos)

- data:

  the complete-case data for `vars`

- data_scaled:

  the normalized data

- groups:

  factor of group assignments (or NULL)

- group_source:

  how groups were formed: "overall", "column", "assignment", or "kmeans"

- cor_matrix:

  the matrix used for axis placement

- scale_ref:

  the data defining the radial scale: `reference` if supplied, otherwise
  `data`

- has_reference:

  TRUE when an external `reference` was supplied

Use [`print()`](https://rdrr.io/r/base/print.html) and
[`plot()`](https://rdrr.io/r/graphics/plot.default.html) methods on the
result.

## Examples

``` r
result <- coradar(mtcars, vars = c("mpg", "disp", "hp", "drat", "wt", "qsec"))
result
#> Co-radar plot of 6 variables, 32 observations
#> Normalization: minmax 
#> 
#> Axis positions (degrees):
#>  mpg disp   wt drat qsec   hp 
#>    0   10   22   67  266  341 
plot(result)


# two k-means archetypes
set.seed(1)
plot(coradar(mtcars, vars = c("mpg", "disp", "hp", "drat", "wt", "qsec"),
             groups = 2))


# group by an existing column
plot(coradar(mtcars, vars = c("mpg", "disp", "hp", "wt", "qsec"),
             groups = "am"))


# axes and radial scale taken from an external reference cohort, so the
# two subgroup plots below are directly comparable
v <- c("mpg", "disp", "hp", "drat", "wt", "qsec")
plot(coradar(mtcars[mtcars$am == 0, ], vars = v, reference = mtcars))

plot(coradar(mtcars[mtcars$am == 1, ], vars = v, reference = mtcars))

```
