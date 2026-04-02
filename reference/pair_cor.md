# Calculate association measure between a pair of variables

Calculate association measure between a pair of variables

## Usage

``` r
pair_cor(df, type)
```

## Arguments

- df:

  a dataframe with 2 columns

- type:

  a vector with 2 elements corresponding to types of variables in df.
  Types can be "numeric", "ordinal" or "factor", but cannot both be
  numeric.

## Value

values and type of association measure, as well as p value from
corresponding association test

## Details

The following associated measures and tests are implemented dependent on
variable type:

factor vs numeric, factor or ordinal: Pseudo R^2 and p value from
multinomial regression

ordinal vs ordinal or numeric: GK gamma and GK gamma correlation test

## Examples

``` r
if (FALSE) { # \dontrun{
data1 <- data.frame(x = rnorm(10), y = rbinom(10, 1, 0.5))
# second variable as factor
type1 <- c("numeric", "factor")
pair_cor(data1, type1)
# second variable as ordinal
type2 <- c("numeric", "ordinal")
pair_cor(data1, type2)
} # }
```
