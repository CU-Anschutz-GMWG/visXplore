# Visualize numeric variables

This functions generates histograms and marks out mean and one standard
deviation band around the mean for each numeric variable

## Usage

``` r
make_hist(df_hist)
```

## Arguments

- df_hist:

  A wide-format data include all numeric variables to visualize

## Value

Annotated histograms in numeric variable tab

## Details

This function only run internally in VisXplore application because it
depends on reactive values from user input
