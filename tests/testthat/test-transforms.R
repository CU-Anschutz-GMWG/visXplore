##### visx_transform #####

test_that("visx_transform log", {
  df <- data.frame(a = exp(1:10), b = exp(1:10))
  result <- visx_transform(df, c("a", "b"), fun = "log")
  expect_equal(ncol(result), 2)
  expect_equal(result[[1]], 1:10, tolerance = 1e-10)
  expect_true(all(grepl("_log$", names(result))))
})

test_that("visx_transform sqrt", {
  df <- data.frame(a = (1:10)^2)
  result <- visx_transform(df, "a", fun = "sqrt")
  expect_equal(result[[1]], 1:10, tolerance = 1e-10)
  expect_equal(names(result), "a_sqrt")
})

test_that("visx_transform custom suffix", {
  df <- data.frame(x = 1:5)
  result <- visx_transform(df, "x", fun = "log", suffix = "ln")
  expect_equal(names(result), "x_ln")
})

##### visx_ratio #####

test_that("visx_ratio computes correctly", {
  df <- data.frame(a = c(10, 20), b = c(2, 5))
  result <- visx_ratio(df, "a", "b")
  expect_equal(result[[1]], c(5, 4))
  expect_equal(names(result), "a_over_b")
})

test_that("visx_ratio with custom name", {
  df <- data.frame(a = c(10, 20), b = c(2, 5))
  result <- visx_ratio(df, "a", "b", name = "ratio_ab")
  expect_equal(names(result), "ratio_ab")
})

##### visx_mean_vars #####

test_that("visx_mean_vars computes row means", {
  df <- data.frame(a = c(1, 2, 3), b = c(3, 2, 1))
  result <- visx_mean_vars(df, c("a", "b"))
  expect_equal(result[[1]], c(2, 2, 2))
  expect_equal(names(result), "mean_var")
})

test_that("visx_mean_vars with custom name", {
  df <- data.frame(a = 1:3, b = 4:6)
  result <- visx_mean_vars(df, c("a", "b"), name = "avg")
  expect_equal(names(result), "avg")
})

##### visx_collapse_levels #####

test_that("visx_collapse_levels works", {
  df <- data.frame(color = c("red", "blue", "green", "red"))
  result <- visx_collapse_levels(df, "color", c("red", "blue"), "warm_cool")
  expect_equal(sum(result[[1]] == "warm_cool"), 3)
  expect_equal(result[[1]][3], "green")
  expect_equal(names(result), "color_bin")
})

test_that("visx_collapse_levels preserves non-collapsed levels", {
  df <- data.frame(size = c("S", "M", "L", "XL"))
  result <- visx_collapse_levels(df, "size", c("S", "M"), "small")
  expect_equal(result[[1]], c("small", "small", "L", "XL"))
})

##### domain warnings #####

test_that("visx_transform warns on log of negative values", {
  df <- data.frame(x = c(-1, 0, 1, 2))
  expect_warning(visx_transform(df, "x", fun = "log"),
                 "values <= 0")
})

test_that("visx_transform warns on log of zero", {
  df <- data.frame(x = c(0, 1, 2))
  expect_warning(visx_transform(df, "x", fun = "log"),
                 "values <= 0")
})

test_that("visx_transform warns on sqrt of negative values", {
  df <- data.frame(x = c(-4, 1, 4))
  expect_warning(visx_transform(df, "x", fun = "sqrt"),
                 "negative values")
})

test_that("visx_transform does not warn on valid inputs", {
  df <- data.frame(x = c(1, 2, 3))
  expect_no_warning(visx_transform(df, "x", fun = "log"))
  expect_no_warning(visx_transform(df, "x", fun = "sqrt"))
})

test_that("visx_ratio warns on zero denominator", {
  df <- data.frame(a = c(1, 2, 3), b = c(0, 1, 2))
  expect_warning(visx_ratio(df, "a", "b"),
                 "contains zeros")
})

test_that("visx_ratio does not warn on valid inputs", {
  df <- data.frame(a = c(1, 2, 3), b = c(1, 2, 3))
  expect_no_warning(visx_ratio(df, "a", "b"))
})
