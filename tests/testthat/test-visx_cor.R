##### S3 class tests #####

test_that("pairwise_cor returns visx_cor class", {
  result <- pairwise_cor(mtcars)
  expect_s3_class(result, "visx_cor")
  expect_true(all(c("cor_value", "cor_type", "cor_p", "var_type", "data") %in% names(result)))
})

test_that("print.visx_cor produces informative output", {
  result <- pairwise_cor(mtcars)
  output <- capture.output(print(result))
  expect_true(any(grepl("11 variables", output)))
  expect_true(any(grepl("numeric", output)))
  expect_true(any(grepl("significant", output)))
})

test_that("summary.visx_cor returns corstars-compatible result", {
  result <- pairwise_cor(mtcars)
  s <- summary(result)
  expect_true("Rnew" %in% names(s))
  expect_true("row_id" %in% names(s))
  expect_true("col_id" %in% names(s))
})

test_that("plot.visx_cor returns ggplot", {
  result <- pairwise_cor(mtcars)
  p <- plot(result)
  expect_s3_class(p, "gg")
})

test_that("as.data.frame.visx_cor works", {
  result <- pairwise_cor(mtcars)
  df <- as.data.frame(result)
  expect_s3_class(df, "data.frame")
  expect_equal(nrow(df), ncol(mtcars))
  expect_equal(ncol(df), ncol(mtcars))
})

test_that("backward compat: list access still works", {
  result <- pairwise_cor(mtcars)
  expect_true(is.matrix(result$cor_value))
  expect_true(is.matrix(result$cor_p))
  expect_true(is.matrix(result$cor_type))
})

test_that("print.visx_cor with mixed types", {
  set.seed(42)
  df <- data.frame(x = rnorm(50),
                   y = sample(c("a", "b"), 50, TRUE),
                   z = sample(1:3, 50, TRUE))
  result <- pairwise_cor(df, c("numeric", "factor", "ordinal"))
  output <- capture.output(print(result))
  expect_true(any(grepl("3 variables", output)))
  expect_true(any(grepl("factor", output)))
  expect_true(any(grepl("ordinal", output)))
})

test_that("plot.visx_cor and npc_mixed_cor produce equivalent ggplots", {
  result <- pairwise_cor(mtcars)
  p1 <- plot(result, min_cor = 0.5)
  p2 <- npc_mixed_cor(result, min_cor = 0.5)
  # Both should be ggplot objects with the same data layers
  expect_s3_class(p1, "gg")
  expect_s3_class(p2, "gg")
  expect_equal(length(p1$layers), length(p2$layers))
})
