# VisXplore

VisXplore provides dynamic, interactive visualization of the
distribution and correlation/association structure of multi-dimensional
data. It supports real-time data preprocessing and presents important
information for variable selection.

VisXplore offers both a **code-forward S3 API** for use in R scripts and
notebooks, and an optional **Shiny app** for interactive exploration.

## Installation

You can install the development version of VisXplore from
[GitHub](https://github.com/) with:

``` r
# install.packages("devtools")
devtools::install_github("CU-Anschutz-GMWG/VisXplore")
```

## Example

Use the programmatic API:

``` r
library(VisXplore)
result <- pairwise_cor(mtcars)
result
summary(result)
plot(result)
```

Or launch the interactive Shiny app:

``` r
library(VisXplore)
VisXplore(mtcars)
```

## Video walkthrough

A video walkthrough of the application has been made available, linked
to below:

[![VisXplore
video](https://img.youtube.com/vi/aZfLty00Mrc/0.jpg)](https://www.youtube.com/watch?v=aZfLty00Mrc)
