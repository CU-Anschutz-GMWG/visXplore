# Check for columns that are empty or identical

Check for columns that are empty or identical

## Usage

``` r
data_check(df)
```

## Arguments

- df:

  dataframe to check

## Value

A `visx_check` object with:

- empty_cols:

  character vector of column names that are entirely missing

- zero_var_cols:

  character vector of column names with no variation

- ok:

  logical, TRUE if no issues found

## Examples

``` r
df <- data.frame(x = rnorm(10), y = 1, z = NA)
result <- data_check(df)
result
#> Warning: z missing for all observations
#> Warning: y with same value for all observations
```
