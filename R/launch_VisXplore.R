


#' Run the VisXplore application
#'
#' @description This function starts the VisXplore application for basic data
#' pre-processing and variable selection.
#' @details This application currently supports files in csv format.
#' @details Application interface will pop up after calling this function;
#' data can be uploaded in that interface;
#' close the interface or interrupt R to stop the application.
#'
#' @param data a data.frame to explore
#'
#' @return Histograms for continuous variables;
#' @return Barplots for discrete variables;
#' @return Correlation diagram;
#' @return Variance inflation factors (VIFs) and R-squared;
#' @return Correlation coefficient and p values from correlation test
#'
#' @export
#' @import shiny
#' @import dplyr
#' @import ggplot2
#' @importFrom janitor clean_names
#' @importFrom fastDummies dummy_cols
#' @importFrom kableExtra kable
#' @importFrom kableExtra kable_styling
#' @importFrom kableExtra pack_rows
#' @importFrom kableExtra add_header_above
#' @importFrom kableExtra scroll_box
#' @importFrom car vif
#' @import knitr
#' @import readr
#' @import stringr
#' @import tibble
#' @importFrom tidyr pivot_longer
#'

VisXplore <- function(data){
  if (missing(data)) stop("Please provide a data.frame, e.g. VisXplore(mtcars)")
  server <- server_VisXplore(data)
  shinyApp(ui = ui, server = server, options = list(width = 1600, height = 900))
}


#' @rdname VisXplore
#' @description \code{VisX()} is a deprecated alias for \code{VisXplore()}.
#' @export
VisX <- function(data){
  .Deprecated("VisXplore")
  VisXplore(data)
}
