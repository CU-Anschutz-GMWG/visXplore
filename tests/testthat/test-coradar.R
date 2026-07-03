
angdist <- function(a, b) {
  d <- abs(a - b) %% (2 * pi)
  pmin(d, 2 * pi - d)
}

##### coradar_pos: axis layout #####

test_that("coradar_pos returns valid named angles", {
  cm <- cor(mtcars, method = "spearman")
  pos <- coradar_pos(cm)

  expect_length(pos, ncol(mtcars))
  expect_named(pos, colnames(mtcars))
  expect_true(all(pos >= 0 & pos < 2 * pi))
  expect_equal(unname(pos[1]), 0)
})

test_that("coradar_pos places correlated variables closer than uncorrelated", {
  set.seed(42)
  n <- 200
  x <- rnorm(n)
  df <- data.frame(a = x, b = x + rnorm(n, sd = 0.1), c = rnorm(n), d = rnorm(n))
  pos <- coradar_pos(cor(df, method = "spearman"))

  expect_lt(angdist(pos["a"], pos["b"]), angdist(pos["a"], pos["c"]))
  expect_lt(angdist(pos["a"], pos["b"]), angdist(pos["a"], pos["d"]))
})

test_that("coradar_pos improves on the equidistant layout", {
  cm <- cor(mtcars, method = "spearman")
  target <- (1 - abs(cm)) * pi
  diag(target) <- 0
  stress <- function(th) {
    sum(abs(outer(th, th, angdist) - target)[upper.tri(target)])
  }
  n <- ncol(cm)
  eq <- 2 * pi * (seq_len(n) - 1) / n
  expect_lt(stress(coradar_pos(cm)), stress(eq))
})

test_that("coradar_pos honors minimum separation", {
  cm <- cor(mtcars, method = "spearman")
  pos <- coradar_pos(cm, min_degrees = 15)
  seps <- outer(pos, pos, angdist)
  diag(seps) <- Inf
  expect_gte(min(seps) * 180 / pi, 15 - 0.01)
})

test_that("coradar_pos accepts a visx_cor object", {
  vc <- pairwise_cor(mtcars[, c("mpg", "disp", "hp", "wt")])
  pos <- coradar_pos(vc)
  expect_named(pos, c("mpg", "disp", "hp", "wt"))
})

test_that("coradar_pos falls back to equidistant when min_degrees too large", {
  cm <- cor(mtcars, method = "spearman")
  expect_warning(pos <- coradar_pos(cm, min_degrees = 60), "min_degrees")
  expect_equal(unname(diff(sort(pos))), rep(2 * pi / 11, 10), tolerance = 1e-8)
})

test_that("coradar_pos rejects bad input", {
  m <- matrix(0.5, 2, 3)
  expect_error(coradar_pos(m), "square")
  m2 <- diag(3)
  expect_error(coradar_pos(m2), "column names")
  m3 <- cor(mtcars[1:4])
  m3[1, 2] <- NA
  expect_error(coradar_pos(m3), "missing")
})

##### coradar: constructor #####

test_that("coradar returns a valid visx_coradar object", {
  cr <- coradar(mtcars, vars = c("mpg", "disp", "hp", "wt", "qsec"))

  expect_s3_class(cr, "visx_coradar")
  expect_named(cr$positions, c("mpg", "disp", "hp", "wt", "qsec"))
  expect_equal(nrow(cr$stats), 5)
  expect_equal(levels(cr$stats$group), "Overall")
  expect_null(cr$groups)
  expect_true(all(cr$data_scaled >= 0 & cr$data_scaled <= 1))
})

test_that("coradar defaults to all numeric columns", {
  df <- data.frame(a = rnorm(20), b = rnorm(20), c = rnorm(20),
                   f = factor(rep(c("x", "y"), 10)))
  cr <- coradar(df)
  expect_named(cr$positions, c("a", "b", "c"))
})

test_that("coradar groups by a column, excluding it from axes", {
  cr <- coradar(mtcars, vars = c("mpg", "disp", "hp", "wt"), groups = "am")

  expect_false("am" %in% names(cr$positions))
  expect_equal(nlevels(cr$groups), 2)
  expect_equal(nrow(cr$stats), 8)  # 2 groups x 4 vars
  expect_equal(cr$group_var, "am")
})

test_that("coradar runs k-means when groups is a number", {
  set.seed(1)
  cr <- coradar(mtcars, vars = c("mpg", "disp", "hp", "wt"), groups = 2)
  expect_equal(nlevels(cr$groups), 2)
  expect_length(cr$groups, nrow(mtcars))
})

test_that("coradar accepts a vector of group assignments", {
  grp <- rep(c("A", "B"), length.out = nrow(mtcars))
  cr <- coradar(mtcars, vars = c("mpg", "disp", "hp", "wt"), groups = grp)
  expect_equal(levels(cr$groups), c("A", "B"))
})

test_that("coradar drops incomplete rows with a message", {
  df <- mtcars[, c("mpg", "disp", "hp", "wt")]
  df$mpg[c(1, 5)] <- NA
  expect_message(cr <- coradar(df), "2 rows")
  expect_equal(nrow(cr$data_scaled), nrow(mtcars) - 2)
})

test_that("coradar rank normalization is robust to scale", {
  df <- data.frame(a = exp(rnorm(50)), b = rnorm(50), c = rnorm(50))
  cr <- coradar(df, normalize = "rank")
  expect_true(all(cr$data_scaled >= 0 & cr$data_scaled <= 1))
})

test_that("coradar uses a supplied visx_cor for axis placement", {
  vars <- c("mpg", "disp", "hp", "wt")
  vc <- pairwise_cor(mtcars[, vars])
  cr <- coradar(mtcars, vars = vars, cor_matrix = vc)
  expect_equal(cr$cor_matrix, vc$cor_value[vars, vars])
})

test_that("coradar rejects bad input", {
  expect_error(coradar(mtcars, vars = c("mpg", "wt")), "at least 3")
  expect_error(coradar(mtcars, vars = c("mpg", "wt", "nope")), "not found")
  df <- data.frame(a = rnorm(10), b = rnorm(10), f = letters[1:10])
  expect_error(coradar(df, vars = c("a", "b", "f")), "numeric")
  expect_error(coradar(mtcars, groups = "nope"), "not found")
  expect_error(coradar(mtcars, groups = c("A", "B")), "groups must be")
  expect_error(coradar("not a df"), "data.frame")
})

##### print and plot methods #####

test_that("print.visx_coradar summarizes the object", {
  cr <- coradar(mtcars, vars = c("mpg", "disp", "hp", "wt"), groups = "am")
  out <- capture.output(ret <- print(cr))
  expect_identical(ret, cr)
  expect_true(any(grepl("4 variables", out)))
  expect_true(any(grepl("am", out)))
})

test_that("plot.visx_coradar returns a ggplot", {
  cr <- coradar(mtcars, vars = c("mpg", "disp", "hp", "wt"))
  p <- plot(cr)
  expect_s3_class(p, "ggplot")
  expect_s3_class(plot(cr, sd_band = FALSE), "ggplot")
})

test_that("plot.visx_coradar overlays individuals by index and data.frame", {
  cr <- coradar(mtcars, vars = c("mpg", "disp", "hp", "wt"))
  expect_s3_class(plot(cr, individuals = c(1, 3)), "ggplot")
  expect_s3_class(plot(cr, individuals = mtcars[2, ]), "ggplot")
  expect_error(plot(cr, individuals = 999), "out of range")
  expect_error(plot(cr, individuals = mtcars[2, c("mpg", "disp")]), "missing")
})

test_that("plot.visx_coradar highlight validates variable names", {
  cr <- coradar(mtcars, vars = c("mpg", "disp", "hp", "wt"))
  expect_s3_class(plot(cr, highlight = c("mpg", "wt")), "ggplot")
  expect_error(plot(cr, highlight = "nope"), "not on the plot")
})

test_that("plots build without errors", {
  cr <- coradar(mtcars, vars = c("mpg", "disp", "hp", "wt"), groups = "am")
  expect_no_error(ggplot2::ggplot_build(plot(cr, individuals = 1)))
})
