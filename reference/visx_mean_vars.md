# Compute row-wise mean of selected columns

Compute row-wise mean of selected columns

## Usage

``` r
visx_mean_vars(df, vars, name = "mean_var")
```

## Arguments

- df:

  a data.frame

- vars:

  character vector of column names to average

- name:

  name for the new column

## Value

a single-column data.frame with row-wise means

## Examples

``` r
df <- data.frame(a = 1:5, b = 6:10, c = 11:15)
visx_mean_vars(df, c("a", "b", "c"))
#>   mean_var
#> 1        6
#> 2        7
#> 3        8
#> 4        9
#> 5       10
```
