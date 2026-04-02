
# this script writes functions for calculating measures of association
# between two variables

#### association ####

#' Calculate association measure between a pair of variables
#'
#' @param df a dataframe with 2 columns
#' @param type a vector with 2 elements corresponding to types of variables in df.
#' Types can be "numeric", "ordinal" or "factor",
#' but cannot both be numeric.
#'
#' @return values and type of association measure,
#' as well as p value from corresponding association test
#'
#' @details The following associated measures and tests are implemented dependent on variable type:
#'
#' factor vs numeric, factor or ordinal: Pseudo R^2 and p value from multinomial regression
#'
#' ordinal vs ordinal or numeric: GK gamma and GK gamma correlation test
#'
#' @importFrom car Anova
#' @importFrom MESS gkgamma
#'
#' @examples \dontrun{
#' data1 <- data.frame(x = rnorm(10), y = rbinom(10, 1, 0.5))
#' # second variable as factor
#' type1 <- c("numeric", "factor")
#' pair_cor(data1, type1)
#' # second variable as ordinal
#' type2 <- c("numeric", "ordinal")
#' pair_cor(data1, type2)
#' }
pair_cor <- function(df, type){

  # check
  if(type[1]=="numeric"&type[2]=="numeric"){
    stop("Not supported")
  }
  # pseudo R^2
  if("factor" %in% type){
    # multinomial regression
    varnames <- colnames(df)
    resp_idx <- ifelse(length(unique(df[, 1])) <= length(unique(df[, 2])), 1, 2)
    f <- as.formula(paste(varnames[resp_idx], "~", varnames[3 - resp_idx]))
    f_null <- as.formula(paste(varnames[resp_idx], "~ 1"))
    mult_fit <- try(multinom(f, data = df, model = T, trace = FALSE), silent = TRUE)
    cor_type <- "pseudoR2"

    if(!("try-error" %in% class(mult_fit)) ) {
      null_fit <- multinom(f_null, data = df, model = T, trace = FALSE)
      cor_value <- sqrt(nagelkerke_r2(mult_fit, null_fit))
      discard <- capture.output(cor_p <- Anova(mult_fit, trace = FALSE)$`Pr(>Chisq)`)
    } else if (all(df[,1] == df[,2])) {
      cor_value <- 1
      cor_p <- NA
    } else {
      warning("Could not compute association between ",
              colnames(df)[1], " and ", colnames(df)[2],
              ". Returning NA.")
      cor_value <- NA
      cor_p <- NA
    }

  }
  # GK gamma
  else{
    #cor_value <- GoodmanKruskalGamma(df[, 1], df[, 2])
    cor_test <- gkgamma(table(df))
    cor_value <- cor_test$estimate
    cor_p <- cor_test$p.value
    cor_type <- "GKgamma"
  }

  return(list(cor_value = cor_value, cor_type = cor_type, cor_p = cor_p))
}

##### pairwise association #####

#' Calculate pairwise association of data with mixed types of variables
#'
#' @param df dataframe with mixed types of variables
#' @param var_type a character vector corresponding to types of variables in df.
#'  If not provided, will guess based on column classes.
#'
#' @return A \code{visx_cor} object (S3 class) containing:
#' \describe{
#'   \item{cor_value}{numeric matrix of pairwise association values}
#'   \item{cor_type}{character matrix of association types (spearman, pseudoR2, GKgamma)}
#'   \item{cor_p}{numeric matrix of p-values}
#'   \item{var_type}{character/factor vector of variable types}
#'   \item{data}{the original data.frame}
#' }
#'
#' Use \code{print()}, \code{summary()}, \code{plot()}, and \code{as.data.frame()}
#' methods on the result.
#'
#' @details The following associated measures and tests are implemented dependent on variable type:
#'
#' factor vs numeric, factor or ordinal: Pseudo R^2 and p value from multinomial regression
#'
#' ordinal vs ordinal or numeric: GK gamma and GK gamma correlation test
#'
#' numeric vs numeric: Spearman correlation and p value
#'
#' @importFrom Hmisc rcorr
#' @importFrom nnet multinom
#' @importFrom car Anova
#' @importFrom MESS gkgamma
#' @importFrom janitor clean_names
#' @importFrom utils capture.output
#' @export
#'
#' @examples
#' data1 <- data.frame(x = rnorm(10),
#'  y = rbinom(10, 1, 0.5),
#' z = rbinom(10, 5, 0.5))
#' type1 <- c("numeric", "factor", "ordinal")
#' result <- pairwise_cor(data1, type1)
#' result
#' summary(result)
#'
pairwise_cor <- function(df, var_type = NULL){

  # Guesses if not specified
  if(!length(var_type)) {
    types <- sapply(df, class)
    var_type <- factor(types,
                    levels = c("numeric", "integer", "factor", "character", "logical", "NULL"),
                    labels = c("numeric", "numeric", "factor", "factor", "factor", "factor"))
  }

  # set-up
  p <- ncol(df)
  id_num <- which(var_type == "numeric")
  id_non_num <- which(var_type != "numeric")

  # container
  cor_value_mat <- matrix(NA, p, p)
  cor_type_mat <- matrix(NA, p, p)
  cor_p_mat <- matrix(NA, p, p)

  colnames(cor_value_mat) <- rownames(cor_value_mat) <- colnames(df)
  colnames(cor_type_mat) <- rownames(cor_type_mat) <- colnames(df)
  colnames(cor_p_mat) <- rownames(cor_p_mat) <- colnames(df)

  # calculate correlation
  ## numeric variables alone (Spearman)
  if(length(id_num) > 1){
    num_cor <- rcorr(as.matrix(df[, id_num]), type = "spearman")
    cor_value_mat[id_num, id_num] <- num_cor$r
    cor_p_mat[id_num, id_num] <- num_cor$P
    cor_type_mat[id_num, id_num] <- "spearman"
  } else if(length(id_num) == 1){
    # Single numeric: diagonal is 1, no Spearman to compute
    cor_value_mat[id_num, id_num] <- 1
    cor_type_mat[id_num, id_num] <- "spearman"
  }

  ## non-numeric pairs: iterate only unique pairs involving at least one non-numeric
  if(length(id_non_num) > 0){
    # Build unique pairs (i < j) where at least one is non-numeric
    all_pairs <- which(upper.tri(cor_value_mat), arr.ind = TRUE)
    needs_pair_cor <- apply(all_pairs, 1, function(idx) {
      any(idx %in% id_non_num)
    })
    non_num_pairs <- all_pairs[needs_pair_cor, , drop = FALSE]

    for(k in seq_len(nrow(non_num_pairs))){
      i <- non_num_pairs[k, 1]
      j <- non_num_pairs[k, 2]
      this_cor <- pair_cor(df[, c(i, j)], var_type[c(i, j)])
      cor_value_mat[i, j] <- cor_value_mat[j, i] <- this_cor$cor_value
      cor_type_mat[i, j] <- cor_type_mat[j, i] <- this_cor$cor_type
      cor_p_mat[i, j] <- cor_p_mat[j, i] <- this_cor$cor_p
    }

    # Fill diagonal for non-numeric variables
    for(j in id_non_num){
      cor_value_mat[j, j] <- 1
      cor_type_mat[j, j] <- if(var_type[j] == "factor") "pseudoR2" else "GKgamma"
    }
  }

  new_visx_cor(cor_value_mat, cor_type_mat, cor_p_mat, var_type, data = df)
}
