
# S3 class for pairwise association results

#' Constructor for visx_cor objects
#' @param cor_value numeric matrix of pairwise association values
#' @param cor_type character matrix of association types
#' @param cor_p numeric matrix of p-values
#' @param var_type character/factor vector of variable types
#' @param data the original data.frame (optional)
#' @return a visx_cor object
#' @noRd
new_visx_cor <- function(cor_value, cor_type, cor_p, var_type, data = NULL) {
  structure(
    list(
      cor_value = cor_value,
      cor_type = cor_type,
      cor_p = cor_p,
      var_type = var_type,
      data = data
    ),
    class = "visx_cor"
  )
}


#' Print method for visx_cor objects
#'
#' @param x a visx_cor object
#' @param ... additional arguments (ignored)
#'
#' @return x, invisibly
#' @export
print.visx_cor <- function(x, ...) {
  p <- ncol(x$cor_value)
  vt <- as.character(x$var_type)

  # Variable type counts
  type_counts <- table(factor(vt, levels = c("numeric", "factor", "ordinal")))
  type_labels <- c("numeric", "factor", "ordinal")
  type_parts <- character(0)
  for (i in seq_along(type_labels)) {
    if (type_counts[type_labels[i]] > 0) {
      type_parts <- c(type_parts, paste0(type_counts[type_labels[i]], " ", type_labels[i]))
    }
  }
  type_str <- paste(type_parts, collapse = ", ")

  # Significant pairs
  upper_p <- x$cor_p[upper.tri(x$cor_p)]
  n_pairs <- length(upper_p)
  n_sig <- sum(upper_p < 0.05, na.rm = TRUE)

  cat("Pairwise associations for", p, "variables")
  cat(" (", type_str, ")\n", sep = "")
  cat(n_sig, "of", n_pairs, "pairs significant at p < 0.05\n")

  # Show variable names
  cat("\nVariables:", paste(colnames(x$cor_value), collapse = ", "), "\n")

  invisible(x)
}


#' Summary method for visx_cor objects
#'
#' @description Displays a formatted correlation/association matrix with
#' significance indicated by stars.
#'
#' @param object a visx_cor object
#' @param ... additional arguments (ignored)
#'
#' @return a list with formatted matrix (Rnew), row_id, and col_id, invisibly
#' @export
summary.visx_cor <- function(object, ...) {
  result <- corstars(object$cor_value, object$cor_p, object$var_type)

  # Print header
  cat("Correlation/Association Matrix\n")
  cat("Significance: **** p<0.0001, *** p<0.001, ** p<0.01, * p<0.05\n\n")

  # Print the matrix
  print(result$Rnew)
  cat("\n")

  invisible(result)
}


#' Plot method for visx_cor objects
#'
#' @description Generates a network plot of correlations and associations.
#'
#' @param x a visx_cor object
#' @param min_cor minimum association to visualize (default 0.3)
#' @param sig.level significance threshold (default 0.05)
#' @param show_signif whether to show significance overlay (default FALSE)
#' @param ... additional arguments passed to \code{\link{npc_mixed_cor}}
#'
#' @return a ggplot object, invisibly
#' @export
plot.visx_cor <- function(x, min_cor = 0.3, sig.level = 0.05,
                          show_signif = FALSE, ...) {
  p <- npc_mixed_cor(x, min_cor = min_cor, sig.level = sig.level,
                     show_signif = show_signif, ...)
  print(p)
  invisible(p)
}


#' Convert visx_cor to data.frame
#'
#' @description Returns the association value matrix as a data.frame.
#'
#' @param x a visx_cor object
#' @param ... additional arguments (ignored)
#'
#' @return a data.frame of pairwise association values
#' @export
as.data.frame.visx_cor <- function(x, ...) {
  as.data.frame(x$cor_value)
}
