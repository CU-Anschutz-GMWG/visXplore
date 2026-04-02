# Compute ratio of two columns

Compute ratio of two columns

## Usage

``` r
visx_ratio(df, var1, var2, name = NULL)
```

## Arguments

- df:

  a data.frame

- var1:

  name of numerator column

- var2:

  name of denominator column

- name:

  name for the new column (defaults to `var1_over_var2`)

## Value

a single-column data.frame with the ratio

## Examples

``` r
df <- data.frame(a = c(10, 20), b = c(2, 5))
visx_ratio(df, "a", "b")
#>   a_over_b
#> 1        5
#> 2        4
```
