# Apply univariate transformation to selected columns

Apply univariate transformation to selected columns

## Usage

``` r
visx_transform(df, vars, fun = c("log", "sqrt"), suffix = NULL)
```

## Arguments

- df:

  a data.frame

- vars:

  character vector of column names to transform

- fun:

  transformation function name: "log" or "sqrt"

- suffix:

  suffix for new column names (defaults to the function name)

## Value

a data.frame with the transformed columns, named `<original>_<suffix>`

## Examples

``` r
df <- data.frame(a = exp(1:5), b = (1:5)^2)
visx_transform(df, c("a", "b"), fun = "log")
#>   a_log    b_log
#> 1     1 0.000000
#> 2     2 1.386294
#> 3     3 2.197225
#> 4     4 2.772589
#> 5     5 3.218876
visx_transform(df, "b", fun = "sqrt")
#>   b_sqrt
#> 1      1
#> 2      2
#> 3      3
#> 4      4
#> 5      5
```
