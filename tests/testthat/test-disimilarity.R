#### correlation/association of a pair of variables ####

test_that("A pair of variables", {
  # data
  data <- data.frame(x = rnorm(10), y = rbinom(10, 1, 0.5))
  type1 <- c("numeric", "factor")
  type2 <-  c("numeric", "ordinal")
  cor1 <- pair_cor(data, type1)
  cor2 <- pair_cor(data, type2)

  # expectation
  ## correlation
  expect_gte(cor1[[1]], 0)
  expect_lte(cor1[[1]], 1)
  expect_gte(cor2[[1]], -1)
  expect_lte(cor2[[1]], 1)
  ## type
  expect_equal(cor1[[2]], "pseudoR2")
  expect_equal(cor2[[2]], "GKgamma")
  ## p values
  expect_gte(cor1[[3]], 0)
  expect_lte(cor1[[3]], 1)
  expect_gte(cor2[[3]], 0)
  expect_lte(cor2[[3]], 1)

  # both numeric variables
  expect_error(pair_cor(data, c("numeric", "numeric")))
})

##### pairwise correlation/association #####

test_that("Data frame", {

  df <- data.frame(x = rnorm(10),  y = rbinom(10, 1, 0.5),
                      z = rbinom(10, 5, 0.5))
  type_df <- c("numeric", "factor", "ordinal")
  cor_df <- pairwise_cor(df, type_df)

  cor_type <- matrix(c("spearman", "pseudoR2", "GKgamma",
                          "pseudoR2", "pseudoR2",  "pseudoR2",
                          "GKgamma",  "pseudoR2", "GKgamma"),
                        nrow=3, ncol=3)
  colnames(cor_type) <- rownames(cor_type) <- colnames(df)

  expect_s3_class(cor_df, "visx_cor")
  expect_equal(cor_df$cor_type, cor_type)
})

##### correctness of association values #####

test_that("GK gamma is 1 for perfectly concordant ordinal data", {
  # When both ordinal variables increase together perfectly, gamma should be 1
  df <- data.frame(x = rep(1:5, each = 20), y = rep(1:5, each = 20))
  result <- pair_cor(df, c("ordinal", "ordinal"))
  expect_equal(result$cor_type, "GKgamma")
  expect_equal(unname(result$cor_value), 1, tolerance = 0.01)
})

test_that("GK gamma is -1 for perfectly discordant ordinal data", {
  # When one ordinal variable increases as the other decreases, gamma should be -1
  df <- data.frame(x = rep(1:5, each = 20), y = rep(5:1, each = 20))
  result <- pair_cor(df, c("ordinal", "ordinal"))
  expect_equal(result$cor_type, "GKgamma")
  expect_equal(unname(result$cor_value), -1, tolerance = 0.01)
})

test_that("GK gamma matches MESS::gkgamma directly", {
  set.seed(123)
  df <- data.frame(x = sample(1:4, 100, TRUE), y = sample(1:3, 100, TRUE))
  result <- pair_cor(df, c("ordinal", "ordinal"))
  ref <- MESS::gkgamma(table(df))
  expect_equal(result$cor_value, ref$estimate)
  expect_equal(result$cor_p, ref$p.value)
})

test_that("pseudoR2 is high for perfectly separable factor", {
  set.seed(42)
  # Factor perfectly determined by numeric: a when x < 0, b when x >= 0
  x <- c(rnorm(50, -3), rnorm(50, 3))
  y <- factor(ifelse(x < 0, "a", "b"))
  df <- data.frame(x = x, y = y)
  result <- pair_cor(df, c("numeric", "factor"))
  expect_equal(result$cor_type, "pseudoR2")
  # sqrt(Nagelkerke pseudoR2) should be very high for perfect separation
  expect_gt(result$cor_value, 0.9)
})

test_that("pseudoR2 is near zero for independent factor and numeric", {
  set.seed(42)
  # Independent: factor assignment unrelated to numeric
  df <- data.frame(x = rnorm(200),
                   y = factor(sample(c("a", "b", "c"), 200, TRUE)))
  result <- pair_cor(df, c("numeric", "factor"))
  expect_equal(result$cor_type, "pseudoR2")
  expect_lt(result$cor_value, 0.3)
})

test_that("pseudoR2 matches manual multinom computation", {
  set.seed(99)
  df <- data.frame(x = rnorm(100), y = factor(sample(c("a", "b"), 100, TRUE)))
  result <- pair_cor(df, c("numeric", "factor"))

  # Reproduce manually using Nagelkerke's formula
  fit <- multinom(y ~ x, data = df, model = TRUE, trace = FALSE)
  null_fit <- multinom(y ~ 1, data = df, model = TRUE, trace = FALSE)
  n <- nrow(df)
  ll_full <- as.numeric(logLik(fit))
  ll_null <- as.numeric(logLik(null_fit))
  cox_snell <- 1 - exp((2 / n) * (ll_null - ll_full))
  ref_r2 <- sqrt(cox_snell / (1 - exp((2 / n) * ll_null)))
  expect_equal(unname(result$cor_value), ref_r2, tolerance = 1e-6)
})

test_that("Spearman correlation in pairwise_cor matches cor()", {
  set.seed(42)
  df <- data.frame(x = rnorm(50), y = rnorm(50), z = rnorm(50))
  result <- pairwise_cor(df)

  ref <- cor(df, method = "spearman")
  expect_equal(result$cor_value, ref, tolerance = 1e-6)
})

test_that("pairwise_cor values are symmetric", {
  set.seed(42)
  df <- data.frame(x = rnorm(50),
                   y = sample(c("a", "b"), 50, TRUE),
                   z = sample(1:3, 50, TRUE))
  result <- pairwise_cor(df, c("numeric", "factor", "ordinal"))
  expect_true(isSymmetric(result$cor_value))
  expect_true(isSymmetric(result$cor_type))
})

##### edge cases #####

test_that("pairwise_cor with all-numeric data", {
  df <- mtcars[, 1:5]
  result <- pairwise_cor(df)
  expect_s3_class(result, "visx_cor")
  expect_true(all(result$cor_type == "spearman"))
})

test_that("pairwise_cor with all-factor data", {
  set.seed(42)
  df <- data.frame(a = sample(letters[1:3], 50, TRUE),
                   b = sample(letters[1:2], 50, TRUE),
                   c = sample(letters[1:4], 50, TRUE))
  result <- pairwise_cor(df, c("factor", "factor", "factor"))
  expect_s3_class(result, "visx_cor")
  expect_true(all(result$cor_type == "pseudoR2"))
})

test_that("pairwise_cor with single numeric variable", {
  df <- data.frame(x = rnorm(20))
  result <- pairwise_cor(df)
  expect_s3_class(result, "visx_cor")
  expect_equal(dim(result$cor_value), c(1, 1))
  expect_equal(result$cor_value[1, 1], 1)
})

test_that("pairwise_cor handles missing values in numeric data", {
  df <- data.frame(x = c(rnorm(18), NA, NA), y = rnorm(20))
  result <- pairwise_cor(df)
  expect_s3_class(result, "visx_cor")
})

test_that("pairwise_cor auto-guesses variable types", {
  df <- data.frame(x = rnorm(20), y = factor(sample(letters[1:3], 20, TRUE)))
  result <- pairwise_cor(df)
  expect_s3_class(result, "visx_cor")
  expect_true("pseudoR2" %in% result$cor_type)
})

##### pair_cor error handling #####

test_that("pair_cor warns and returns NA when multinom fails (single-level factor)", {
  df <- data.frame(x = rnorm(20), y = factor(rep("a", 20)))
  result <- expect_warning(pair_cor(df, c("numeric", "factor")),
                           "Could not compute association")
  expect_equal(result$cor_type, "pseudoR2")
  expect_true(is.na(result$cor_value))
  expect_true(is.na(result$cor_p))
})

test_that("pair_cor returns near-1 for identical factor columns", {
  vals <- sample(c("a", "b", "c"), 20, TRUE)
  df <- data.frame(x = vals, y = vals)
  result <- pair_cor(df, c("factor", "factor"))
  # multinom succeeds on identical cols; sqrt(PseudoR2) is ~1 but not exact
  expect_gt(unname(result$cor_value), 0.99)
})

test_that("pairwise_cor with heavy NAs in factor column", {
  set.seed(42)
  df <- data.frame(x = rnorm(40),
                   y = factor(c(rep(NA, 20), sample(c("a", "b"), 20, TRUE))))
  result <- pairwise_cor(df, c("numeric", "factor"))
  expect_s3_class(result, "visx_cor")
  # Should complete; value may be NA or computed from complete cases
  expect_true(is.numeric(result$cor_value[1, 2]) || is.na(result$cor_value[1, 2]))
})

test_that("pairwise_cor with factor with many levels", {
  set.seed(42)
  df <- data.frame(x = rnorm(200),
                   y = factor(sample(letters, 200, TRUE)))
  result <- pairwise_cor(df, c("numeric", "factor"))
  expect_s3_class(result, "visx_cor")
})
