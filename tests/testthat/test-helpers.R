
##### corstars #####

test_that("correlation matrix with significance", {

  df <- data.frame(x1 = rnorm(100),
                   x2 = sample(c("a", "b", "c"), size = 100, replace = T),
                   x3 = sample(1:3, size = 100, replace = T))
  df$x4 <- df$x1+rnorm(100, 0, 0.01)
  type <- c("numeric", "factor", "ordinal", "numeric")
  test_cor <- pairwise_cor(df, type)
  test_mat <- corstars(test_cor$cor_value, test_cor$cor_p, type)

  expect_setequal(test_mat$col_id, c("numeric", "factor", "ordinal"))
  expect_setequal(test_mat$row_id, c("numeric", "numeric", "factor"))

})


##### get_r2 #####

test_that("get R-squared", {

  df <- data.frame(x1 = rnorm(100),
                   x2 = sample(c("a", "b", "c"), size = 100, replace = T),
                   x3 = sample(1:3, size = 100, replace = T))
  df$x4 <- df$x1+rnorm(100, 0, 0.01)
  type <- c("numeric", "factor", "ordinal", "numeric")

  test_r2 <- get_r2(df, type)

  expect_length(test_r2, ncol(df))
  expect_gt(test_r2[1], test_r2[2])
  expect_gt(test_r2[4], test_r2[3])

})

test_that("get_r2 with all-numeric data", {
  df <- data.frame(x = rnorm(100), y = rnorm(100), z = rnorm(100))
  r2 <- get_r2(df, rep("numeric", 3))
  expect_length(r2, 3)
  expect_true(all(r2 >= 0 & r2 <= 1))
})

test_that("get_r2 with factor variable", {
  set.seed(42)
  df <- data.frame(x = rnorm(100),
                   y = sample(c("a", "b"), 100, TRUE))
  r2 <- get_r2(df, c("numeric", "factor"))
  expect_length(r2, 2)
  expect_true(all(r2 >= 0 & r2 <= 1))
})

test_that("get_r2 does not corrupt data across multiple ordinal variables", {
  set.seed(42)
  df <- data.frame(
    ord1 = sample(c("low", "med", "high"), 50, TRUE),
    ord2 = sample(c("A", "B", "C"), 50, TRUE)
  )
  type <- c("ordinal", "ordinal")

  r2_together <- get_r2(df, type)

  # Compute each independently for ground truth
  df1 <- df; df1$ord1 <- as.numeric(as.factor(df1$ord1))
  r2_1 <- summary(lm(ord1 ~ ., df1))$r.squared

  df2 <- df; df2$ord2 <- as.numeric(as.factor(df2$ord2))
  r2_2 <- summary(lm(ord2 ~ ., df2))$r.squared

  expect_equal(r2_together[1], r2_1, tolerance = 1e-10)
  expect_equal(r2_together[2], r2_2, tolerance = 1e-10)
})

##### corstars edge cases #####

test_that("corstars with all-numeric data", {
  result <- pairwise_cor(mtcars[, 1:4])
  cs <- corstars(result$cor_value, result$cor_p, rep("numeric", 4))
  expect_true(all(cs$row_id == "numeric"))
  expect_true(all(cs$col_id == "numeric"))
  expect_equal(nrow(cs$Rnew), 3)
  expect_equal(ncol(cs$Rnew), 3)
})

test_that("corstars with all-factor data", {
  set.seed(42)
  df <- data.frame(a = sample(letters[1:3], 50, TRUE),
                   b = sample(letters[1:2], 50, TRUE),
                   c = sample(letters[1:4], 50, TRUE))
  result <- pairwise_cor(df, c("factor", "factor", "factor"))
  cs <- corstars(result$cor_value, result$cor_p, c("factor", "factor", "factor"))
  expect_true(all(cs$row_id == "factor"))
  expect_true(all(cs$col_id == "factor"))
})
