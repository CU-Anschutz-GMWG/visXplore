# Tests for data_check (now returns visx_check S3 object)

test_that("data_check returns visx_check for clean data", {
  df <- data.frame(x = rnorm(10), y = rnorm(10))
  result <- data_check(df)
  expect_s3_class(result, "visx_check")
  expect_true(result$ok)
  expect_length(result$empty_cols, 0)
  expect_length(result$zero_var_cols, 0)
})

test_that("data_check detects empty columns", {
  df <- data.frame(x1 = rnorm(100), x2 = rnorm(100), x3 = NA)
  result <- data_check(df)
  expect_s3_class(result, "visx_check")
  expect_false(result$ok)
  expect_equal(result$empty_cols, "x3")
})

test_that("data_check detects zero-variance columns", {
  df <- data.frame(x1 = rnorm(100), x2 = rnorm(100), x3 = 1)
  result <- data_check(df)
  expect_false(result$ok)
  expect_equal(result$zero_var_cols, "x3")
  expect_length(result$empty_cols, 0)
})

test_that("data_check detects both empty and zero-variance", {
  df <- data.frame(x1 = rnorm(100), x2 = rnorm(100), x3 = 1, x4 = NA)
  result <- data_check(df)
  expect_false(result$ok)
  expect_equal(result$empty_cols, "x4")
  expect_equal(result$zero_var_cols, "x3")
})

test_that("print.visx_check shows issues", {
  df <- data.frame(x = rnorm(10), bad = NA)
  result <- data_check(df)
  output <- capture.output(print(result))
  expect_true(any(grepl("bad", output)))
  expect_true(any(grepl("missing", output)))
})

test_that("print.visx_check shows ok for clean data", {
  df <- data.frame(x = rnorm(10), y = rnorm(10))
  result <- data_check(df)
  output <- capture.output(print(result))
  expect_true(any(grepl("passed", output)))
})

test_that("format_check_html returns HTML string", {
  df <- data.frame(x = rnorm(10), bad = NA, constant = 1)
  result <- data_check(df)
  html <- format_check_html(result)
  expect_type(html, "character")
  expect_true(grepl("bad", html))
  expect_true(grepl("constant", html))
})
