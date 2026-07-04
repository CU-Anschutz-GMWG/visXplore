# Plot method for visx_coradar objects

Draws the co-radar plot: axes placed by correlation structure, one mean
polygon per archetype, and (optionally) a shaded band showing
within-group variability that fades with distance from the mean shape.

## Usage

``` r
# S3 method for class 'visx_coradar'
plot(
  x,
  sd_band = TRUE,
  band_width = 1,
  rounded = FALSE,
  individuals = NULL,
  highlight = NULL,
  label_size = 4,
  legend = TRUE,
  ...
)
```

## Arguments

- x:

  a visx_coradar object

- sd_band:

  if TRUE (default), shade a band of `mean +/- band_width * sd / 2`
  around each archetype

- band_width:

  multiplier for the width of the variability band (default 1)

- rounded:

  if TRUE, draw archetype shapes, variability bands, and individual
  overlays as rounded closed curves instead of straight-edged polygons.
  Between adjacent axes the radius changes monotonically (equal values
  trace a perfect circular arc, and the curve never moves opposite to
  the net direction), with slopes allowed to change abruptly at each
  axis. Useful when correlated axes occupy a narrow arc: the segment
  closing a straight polygon (last axis back to the first) cuts across
  the plot, while a rounded shape sweeps around it

- individuals:

  optional individual observations to overlay as black polygons: either
  row indices into the (complete-case) data, or a data.frame of raw
  values containing the plotted variables (normalized to the scale of
  the original data)

- highlight:

  optional character vector of variable names whose axes are emphasized;
  remaining axes and labels are greyed out

- label_size:

  size of the axis labels (default 4)

- legend:

  if TRUE, show the archetype legend when groups are present

- ...:

  additional arguments (ignored)

## Value

a ggplot object, invisibly

## Examples

``` r
result <- coradar(mtcars, vars = c("mpg", "disp", "hp", "drat", "wt", "qsec"))
plot(result, individuals = 1)

plot(result, highlight = c("mpg", "wt"))

plot(result, rounded = TRUE)

```
