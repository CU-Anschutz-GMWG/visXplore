

#' Apply univariate transformation to selected columns
#'
#' @param df a data.frame
#' @param vars character vector of column names to transform
#' @param fun transformation function name: "log" or "sqrt"
#' @param suffix suffix for new column names (defaults to the function name)
#'
#' @return a data.frame with the transformed columns, named \code{<original>_<suffix>}
#' @export
#'
#' @examples
#' df <- data.frame(a = exp(1:5), b = (1:5)^2)
#' visx_transform(df, c("a", "b"), fun = "log")
#' visx_transform(df, "b", fun = "sqrt")
#'
visx_transform <- function(df, vars, fun = c("log", "sqrt"), suffix = NULL) {
  fun <- match.arg(fun)
  if (is.null(suffix)) suffix <- fun
  fn <- match.fun(fun)

  result <- df[, vars, drop = FALSE]

  # Warn about domain issues before transforming
  if (fun == "log") {
    all_vals <- unlist(result)
    if (any(all_vals <= 0, na.rm = TRUE)) {
      warning("log transformation: input contains values <= 0, ",
              "which will produce NaN or -Inf")
    }
  } else if (fun == "sqrt") {
    all_vals <- unlist(result)
    if (any(all_vals < 0, na.rm = TRUE)) {
      warning("sqrt transformation: input contains negative values, ",
              "which will produce NaN")
    }
  }

  result <- as.data.frame(lapply(result, fn))
  colnames(result) <- paste0(vars, "_", suffix)
  result
}


#' Compute ratio of two columns
#'
#' @param df a data.frame
#' @param var1 name of numerator column
#' @param var2 name of denominator column
#' @param name name for the new column (defaults to \code{var1_over_var2})
#'
#' @return a single-column data.frame with the ratio
#' @export
#'
#' @examples
#' df <- data.frame(a = c(10, 20), b = c(2, 5))
#' visx_ratio(df, "a", "b")
#'
visx_ratio <- function(df, var1, var2, name = NULL) {
  if (is.null(name)) name <- paste0(var1, "_over_", var2)
  if (any(df[[var2]] == 0, na.rm = TRUE)) {
    warning("Denominator '", var2, "' contains zeros, which will produce Inf values")
  }
  result <- data.frame(df[[var1]] / df[[var2]])
  colnames(result) <- name
  result
}


#' Compute row-wise mean of selected columns
#'
#' @param df a data.frame
#' @param vars character vector of column names to average
#' @param name name for the new column
#'
#' @return a single-column data.frame with row-wise means
#' @export
#'
#' @examples
#' df <- data.frame(a = 1:5, b = 6:10, c = 11:15)
#' visx_mean_vars(df, c("a", "b", "c"))
#'
visx_mean_vars <- function(df, vars, name = "mean_var") {
  result <- data.frame(rowMeans(df[, vars, drop = FALSE]))
  colnames(result) <- name
  result
}


#' Collapse levels of a categorical variable
#'
#' @param df a data.frame
#' @param var name of the column to collapse
#' @param levels character vector of levels to combine
#' @param new_label the label for the collapsed levels
#' @param new_type type of the resulting variable: "factor" or "ordinal"
#'
#' @return a single-column data.frame with the collapsed variable,
#'   named \code{<var>_bin}
#' @export
#'
#' @examples
#' df <- data.frame(color = c("red", "blue", "green", "red", "blue"))
#' visx_collapse_levels(df, "color", c("red", "blue"), "warm")
#'
visx_collapse_levels <- function(df, var, levels, new_label,
                                 new_type = c("factor", "ordinal")) {
  new_type <- match.arg(new_type)
  values <- df[[var]]
  values <- ifelse(values %in% levels, new_label, values)
  result <- data.frame(values, stringsAsFactors = FALSE)
  colnames(result) <- paste0(var, "_bin")
  result
}
