# Plot method for visx_cor objects

Generates a network plot of correlations and associations.

## Usage

``` r
# S3 method for class 'visx_cor'
plot(x, min_cor = 0.3, sig.level = 0.05, show_signif = FALSE, ...)
```

## Arguments

- x:

  a visx_cor object

- min_cor:

  minimum association to visualize (default 0.3)

- sig.level:

  significance threshold (default 0.05)

- show_signif:

  whether to show significance overlay (default FALSE)

- ...:

  additional arguments passed to
  [`npc_mixed_cor`](https://CU-Anschutz-GMWG.github.io/VisXplore/reference/npc_mixed_cor.md)

## Value

a ggplot object, invisibly
