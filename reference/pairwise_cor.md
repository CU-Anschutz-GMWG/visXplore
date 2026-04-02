# Calculate pairwise association of data with mixed types of variables

Calculate pairwise association of data with mixed types of variables

## Usage

``` r
pairwise_cor(df, var_type = NULL)
```

## Arguments

- df:

  dataframe with mixed types of variables

- var_type:

  a character vector corresponding to types of variables in df. If not
  provided, will guess based on column classes.

## Value

A `visx_cor` object (S3 class) containing:

- cor_value:

  numeric matrix of pairwise association values

- cor_type:

  character matrix of association types (spearman, pseudoR2, GKgamma)

- cor_p:

  numeric matrix of p-values

- var_type:

  character/factor vector of variable types

- data:

  the original data.frame

Use [`print()`](https://rdrr.io/r/base/print.html),
[`summary()`](https://rdrr.io/r/base/summary.html),
[`plot()`](https://rdrr.io/r/graphics/plot.default.html), and
[`as.data.frame()`](https://rdrr.io/r/base/as.data.frame.html) methods
on the result.

## Details

The following associated measures and tests are implemented dependent on
variable type:

factor vs numeric, factor or ordinal: Pseudo R^2 and p value from
multinomial regression

ordinal vs ordinal or numeric: GK gamma and GK gamma correlation test

numeric vs numeric: Spearman correlation and p value

## Examples

``` r
data1 <- data.frame(x = rnorm(10),
 y = rbinom(10, 1, 0.5),
z = rbinom(10, 5, 0.5))
type1 <- c("numeric", "factor", "ordinal")
result <- pairwise_cor(data1, type1)
result
#> Pairwise associations for 3 variables (1 numeric, 1 factor, 1 ordinal)
#> 1 of 3 pairs significant at p < 0.05
#> 
#> Variables: x, y, z 
summary(result)
#> Correlation/Association Matrix
#> Significance: **** p<0.0001, *** p<0.001, ** p<0.01, * p<0.05
#> 
#>          y        z
#> x 0.34     0.28*   
#> y          0.05    
#> 
```
