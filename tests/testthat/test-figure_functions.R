##### make_hist #####

test_that("make_hist returns ggplot", {
  df <- data.frame(x = rnorm(100), y = rnorm(100))
  p <- make_hist(df)
  expect_s3_class(p, "gg")
})

test_that("make_hist handles single variable", {
  df <- data.frame(x = rnorm(50))
  p <- make_hist(df)
  expect_s3_class(p, "gg")
})

##### make_bar #####

test_that("make_bar returns ggplot", {
  df <- data.frame(x = sample(letters[1:3], 100, TRUE),
                   y = sample(letters[1:2], 100, TRUE))
  p <- make_bar(df)
  expect_s3_class(p, "gg")
})

test_that("make_bar handles single variable", {
  df <- data.frame(x = sample(c("a", "b"), 30, TRUE))
  p <- make_bar(df)
  expect_s3_class(p, "gg")
})
