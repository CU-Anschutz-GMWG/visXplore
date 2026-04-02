# Suppress R CMD check notes for non-standard evaluation in ggplot2/dplyr
utils::globalVariables(c(
  "name", "value", "N",           # make_hist, make_bar
  "type", "x", "y", "xend", "yend", "id",  # npc_mixed_cor
  "proximity", "sign", "var_type",          # npc_mixed_cor
  "ave", "sd"                               # make_hist
))


#' Compute Nagelkerke's pseudo R-squared from a fitted multinom model
#'
#' Avoids DescTools::PseudoR2 which re-evaluates the model call internally
#' and fails when multinom is not on the search path (i.e. when nnet is
#' in Imports rather than Depends).
#'
#' @param model a fitted multinom object
#' @param null_model a fitted null multinom object (response ~ 1)
#' @return Nagelkerke's pseudo R-squared (scalar)
#' @importFrom stats nobs logLik
#' @noRd
nagelkerke_r2 <- function(model, null_model) {
  n <- nobs(model)
  ll_full <- as.numeric(stats::logLik(model))
  ll_null <- as.numeric(stats::logLik(null_model))
  cox_snell <- 1 - exp((2 / n) * (ll_null - ll_full))
  max_cox_snell <- 1 - exp((2 / n) * ll_null)
  cox_snell / max_cox_snell
}
