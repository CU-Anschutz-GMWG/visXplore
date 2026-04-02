
test_that("NPC with mixed types", {
  data(mtcars)

  types <- c("numeric", "factor", rep("numeric", 5), rep("ordinal", 4))

  test_cor <- pairwise_cor(mtcars, types)
  npc <- npc_mixed_cor(test_cor)
  expect_s3_class(npc, "gg")
})

test_that("npc_mixed_cor returns ggplot", {
  result <- pairwise_cor(mtcars)
  p <- npc_mixed_cor(result)
  expect_s3_class(p, "gg")
})

test_that("npc_mixed_cor with show_signif", {
  result <- pairwise_cor(mtcars)
  p <- npc_mixed_cor(result, show_signif = TRUE, sig.level = 0.05)
  expect_s3_class(p, "gg")
})

test_that("npc_mixed_cor with 2 variables", {
  df <- data.frame(x = rnorm(30), y = rnorm(30))
  result <- pairwise_cor(df)
  p <- npc_mixed_cor(result, min_cor = 0)
  expect_s3_class(p, "gg")
})

test_that("npc_mixed_cor rejects invalid min_cor", {
  result <- pairwise_cor(mtcars)
  expect_error(npc_mixed_cor(result, min_cor = -0.5))
  expect_error(npc_mixed_cor(result, min_cor = 1.5))
})

test_that("npc_mixed_cor with single variable does not crash", {
  df <- data.frame(x = rnorm(20))
  result <- pairwise_cor(df)
  p <- npc_mixed_cor(result, min_cor = 0)
  expect_s3_class(p, "gg")
})

test_that("npc_mixed_cor with high min_cor (no edges) does not crash", {
  df <- data.frame(x = rnorm(30), y = rnorm(30), z = rnorm(30))
  result <- pairwise_cor(df)
  # min_cor = 1 means only perfect correlations shown — likely none
  p <- npc_mixed_cor(result, min_cor = 0.99)
  expect_s3_class(p, "gg")
})

test_that("npc_mixed_cor with highly collinear data (MDS fallback)", {
  # Create data where all variables are nearly identical — dissimilarity ~ 0
  set.seed(42)
  x <- rnorm(50)
  df <- data.frame(a = x, b = x + rnorm(50, 0, 0.001), c = x + rnorm(50, 0, 0.001))
  result <- pairwise_cor(df)
  # This may trigger the MDS fallback with shifted distances
  p <- expect_no_error(npc_mixed_cor(result, min_cor = 0))
  expect_s3_class(p, "gg")
})
