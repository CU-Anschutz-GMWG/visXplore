# Collapse levels of a categorical variable

Collapse levels of a categorical variable

## Usage

``` r
visx_collapse_levels(
  df,
  var,
  levels,
  new_label,
  new_type = c("factor", "ordinal")
)
```

## Arguments

- df:

  a data.frame

- var:

  name of the column to collapse

- levels:

  character vector of levels to combine

- new_label:

  the label for the collapsed levels

- new_type:

  type of the resulting variable: "factor" or "ordinal"

## Value

a single-column data.frame with the collapsed variable, named
`<var>_bin`

## Examples

``` r
df <- data.frame(color = c("red", "blue", "green", "red", "blue"))
visx_collapse_levels(df, "color", c("red", "blue"), "warm")
#>   color_bin
#> 1      warm
#> 2      warm
#> 3     green
#> 4      warm
#> 5      warm
```
