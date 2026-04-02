# Correlation and association matrix

Calculate pairwise correlation matrix with significance marked by stars.
Columns and rows are grouped by variable type

## Usage

``` r
corstars(cor_value, cor_p, var_type)
```

## Arguments

- cor_value:

  association matrix

- cor_p:

  significance of association test

- var_type:

  type of variables that correlation and association is calculated for

## Value

Correlation coefficient and significance of correlation test between
each pair of variables, as well as variable type corresponding to rows
and columns for display in shiny app

## Examples

``` r
data(mtcars)
library(VisXplore)
types <- rep("numeric", ncol(mtcars))
test <- VisXplore::pairwise_cor(mtcars, types)
type <- c("numeric", "factor",  rep("numeric", 5), rep("factor", 2), rep("ordinal", 2))
corstars(test$cor_value, test$cor_p, type)
#> $Rnew
#>           disp        hp      drat        wt      qsec       cyl        vs
#> mpg  -0.91**** -0.89****  0.65**** -0.89****  0.47**   -0.91****  0.71****
#> disp            0.85**** -0.68****   0.9**** -0.46**    0.93**** -0.72****
#> hp                       -0.52**    0.77**** -0.67****   0.9**** -0.75****
#> drat                               -0.75****  0.09     -0.68****  0.45*   
#> wt                                           -0.23      0.86**** -0.59*** 
#> qsec                                                   -0.57***   0.79****
#> cyl                                                              -0.81****
#> vs                                                                        
#> am                                                                        
#> gear                                                                      
#>             am      gear      carb
#> mpg   0.56***   0.54**   -0.66****
#> disp -0.62***  -0.59***   0.54**  
#> hp   -0.36*    -0.33      0.73****
#> drat  0.69****  0.74**** -0.13    
#> wt   -0.74**** -0.68****   0.5**  
#> qsec  -0.2     -0.15     -0.66****
#> cyl  -0.52**   -0.56***   0.58*** 
#> vs    0.17      0.28     -0.63****
#> am              0.81**** -0.06    
#> gear                      0.11    
#> 
#> $row_id
#>  [1] numeric numeric numeric numeric numeric numeric factor  factor  factor 
#> [10] ordinal
#> Levels: numeric factor ordinal
#> 
#> $col_id
#>  [1] numeric numeric numeric numeric numeric factor  factor  factor  ordinal
#> [10] ordinal
#> Levels: numeric factor ordinal
#> 
```
