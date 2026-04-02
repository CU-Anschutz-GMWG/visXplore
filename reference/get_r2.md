# R-squared

Compute R-squared for each variable versus all other covariates

## Usage

``` r
get_r2(df, type)
```

## Arguments

- df:

  data frame

- type:

  type corresponding to columns in df

## Value

A vector with values of R squared of each variable

## Details

R-squared is a measure of collinearity, defined as how one variable is
linearly associated with all other variables in the data set.

## Examples

``` r
df <- data.frame(X1 = rnorm(100), X2 = rnorm(100), X3 = rnorm(100))
if (FALSE) { # \dontrun{
get_r2(df, rep("numeric", 3))
} # }
```
