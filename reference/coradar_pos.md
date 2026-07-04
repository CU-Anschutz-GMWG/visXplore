# Correlation-based radar axis positions

Computes angular positions for radar plot axes from a
correlation/association matrix using a force-directed layout. Each pair
of axes is connected by a spring whose ideal length is proportional to
`1 - |correlation|`, so strongly associated variables end up pointing in
similar directions. The layout is annealed from two starting
configurations (equidistant axes and angles derived from 2-d MDS of the
dissimilarity), refined by coordinate descent, and the better solution
is kept. A minimum angular separation is enforced afterwards so that no
two axes coincide.

## Usage

``` r
coradar_pos(cor_matrix, min_degrees = 10, max_iterations = 500)
```

## Arguments

- cor_matrix:

  a square correlation/association matrix with column names, or a
  `visx_cor` object from
  [`pairwise_cor`](https://CU-Anschutz-GMWG.github.io/VisXplore/reference/pairwise_cor.md)

- min_degrees:

  minimum angular separation between any two axes, in degrees (default
  10)

- max_iterations:

  number of annealing iterations (default 500)

## Value

A named numeric vector of axis angles in radians, in `[0, 2*pi)`,
rotated so the first variable sits at angle 0.

## See also

[`coradar`](https://CU-Anschutz-GMWG.github.io/VisXplore/reference/coradar.md)
which computes positions and archetype summaries and has a
[`plot()`](https://rdrr.io/r/graphics/plot.default.html) method

## Examples

``` r
cm <- cor(mtcars, method = "spearman")
pos <- coradar_pos(cm)
round(pos * 180 / pi)
#>  mpg  cyl disp   hp drat   wt qsec   vs   am gear carb 
#>    0   10  350   22  298  340   94   52  267  282   76 
```
