

#' Check for columns that are empty or identical
#'
#' @param df dataframe to check
#'
#' @return A \code{visx_check} object with:
#' \describe{
#'   \item{empty_cols}{character vector of column names that are entirely missing}
#'   \item{zero_var_cols}{character vector of column names with no variation}
#'   \item{ok}{logical, TRUE if no issues found}
#' }
#'
#' @export
#'
#' @examples
#' df <- data.frame(x = rnorm(10), y = 1, z = NA)
#' result <- data_check(df)
#' result
#'
data_check <- function(df){

  # check for empty columns
  empty_col <- apply(df, 2, function(x){sum(!(is.na(x)|x==""|is.null(x)))})
  empty_names <- colnames(df)[empty_col==0]

  # check for columns with no variation (excluding empty columns)
  identical_col <- apply(df, 2, function(x)length(unique(x)))
  identical_names <- colnames(df)[identical_col==1]
  identical_names <- identical_names[!identical_names %in% empty_names]

  structure(
    list(
      empty_cols = empty_names,
      zero_var_cols = identical_names,
      ok = length(empty_names) == 0 && length(identical_names) == 0
    ),
    class = "visx_check"
  )
}


#' Print method for visx_check objects
#'
#' @param x a visx_check object
#' @param ... additional arguments (ignored)
#'
#' @return x, invisibly
#' @export
print.visx_check <- function(x, ...) {
  if (x$ok) {
    cat("Data check passed: no issues found.\n")
  } else {
    if (length(x$empty_cols) > 0) {
      cat("Warning:", paste(x$empty_cols, collapse = ", "),
          "missing for all observations\n")
    }
    if (length(x$zero_var_cols) > 0) {
      cat("Warning:", paste(x$zero_var_cols, collapse = ", "),
          "with same value for all observations\n")
    }
  }
  invisible(x)
}


#' Format visx_check result as HTML for Shiny display
#' @param check a visx_check object
#' @return HTML string
#' @noRd
format_check_html <- function(check) {
  msgs <- character(0)

  if (length(check$empty_cols) > 0) {
    msgs <- c(msgs, paste("Warning:",
                          paste(check$empty_cols, collapse = ", "),
                          "missing for all observations"))
  }
  if (length(check$zero_var_cols) > 0) {
    msgs <- c(msgs, paste("Warning:",
                          paste(check$zero_var_cols, collapse = ", "),
                          "with same value for all observations"))
  }

  paste(msgs, collapse = " <br/> ")
}
