
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

test_that("coradar handles constant columns without erroring", {
  set.seed(1)
  df <- data.frame(a = rnorm(20), b = rnorm(20), c = rnorm(20), z = rep(1, 20))
  expect_message(cr <- coradar(df), "Constant")
  expect_s3_class(cr, "visx_coradar")
  # a constant variable normalizes to the mid-radius and places on the layout
  expect_equal(unique(cr$data_scaled$z), 0.5)
  expect_true("z" %in% names(cr$positions))
})

test_that("coradar validates cluster count against distinct rows", {
  df <- mtcars[1:5, c("mpg", "disp", "hp", "wt")]
  expect_error(coradar(df, groups = 8), "distinct")
})

test_that("coradar errors on a cor_matrix without row names", {
  vars <- c("mpg", "disp", "hp", "wt")
  cm <- cor(mtcars[vars], method = "spearman")
  rownames(cm) <- NULL
  # colnames alone are enough (rownames restored from colnames)
  expect_s3_class(coradar(mtcars, vars = vars, cor_matrix = cm), "visx_coradar")
  # but a matrix missing a variable is rejected informatively
  cm2 <- cor(mtcars[c("mpg", "disp", "hp")], method = "spearman")
  expect_error(coradar(mtcars, vars = vars, cor_matrix = cm2), "wt")
})

test_that("coradar records how groups were formed", {
  vars <- c("mpg", "disp", "hp", "wt")
  expect_equal(coradar(mtcars, vars = vars)$group_source, "overall")
  expect_equal(coradar(mtcars, vars = vars, groups = "am")$group_source, "column")
  grp <- rep(c("A", "B"), length.out = nrow(mtcars))
  expect_equal(coradar(mtcars, vars = vars, groups = grp)$group_source,
               "assignment")
  set.seed(1)
  expect_equal(coradar(mtcars, vars = vars, groups = 2)$group_source, "kmeans")
})

##### print and plot methods #####

test_that("print.visx_coradar summarizes the object", {
  cr <- coradar(mtcars, vars = c("mpg", "disp", "hp", "wt"), groups = "am")
  out <- capture.output(ret <- print(cr))
  expect_identical(ret, cr)
  expect_true(any(grepl("4 variables", out)))
  expect_true(any(grepl("am", out)))
})

test_that("print distinguishes supplied assignments from k-means", {
  vars <- c("mpg", "disp", "hp", "wt")
  grp <- rep(c("A", "B"), length.out = nrow(mtcars))
  out <- capture.output(print(coradar(mtcars, vars = vars, groups = grp)))
  expect_true(any(grepl("supplied assignment", out)))
  expect_false(any(grepl("k-means", out)))

  set.seed(1)
  out2 <- capture.output(print(coradar(mtcars, vars = vars, groups = 2)))
  expect_true(any(grepl("k-means", out2)))
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

test_that("out-of-range individual values are clamped, not reflected", {
  cr <- coradar(mtcars, vars = c("mpg", "disp", "hp", "wt"))
  newobs <- mtcars[1, ]
  newobs$mpg <- 5  # below observed minimum (10.4)
  expect_warning(scaled <- individuals_scaled(cr, newobs), "clamped")
  expect_gte(scaled$mpg, 0)
  expect_lte(scaled$mpg, 1)
})

test_that("individuals overlay works with non-syntactic column names", {
  set.seed(1)
  df <- data.frame(`my var` = rnorm(20), b = rnorm(20), c = rnorm(20),
                   check.names = FALSE)
  cr <- coradar(df)
  expect_identical(names(cr$data_scaled), c("my var", "b", "c"))
  expect_s3_class(plot(cr, individuals = 1), "ggplot")
  expect_s3_class(plot(cr, individuals = df[2, ]), "ggplot")
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

test_that("variability bands are full annuli (no gap at the wrap)", {
  cr <- coradar(mtcars, vars = c("mpg", "disp", "hp", "wt"))
  built <- ggplot2::ggplot_build(plot(cr))
  # layer 3 is the band polygons (circles, spokes, bands, outline, labels)
  band_data <- built$data[[3]]
  expect_true("subgroup" %in% names(band_data))
  rings <- table(band_data$group, band_data$subgroup)
  # every band has an outer and an inner ring, one vertex per axis each
  expect_true(all(rings == 4))
})

test_that("rounded plots build and pass through the axis values", {
  cr <- coradar(mtcars, vars = c("mpg", "disp", "hp", "wt"), groups = "am")
  expect_s3_class(plot(cr, rounded = TRUE), "ggplot")
  expect_no_error(ggplot2::ggplot_build(plot(cr, rounded = TRUE,
                                             individuals = 1)))

  # the interpolated boundary hits each axis point and never overshoots
  pos <- c(0, pi / 2, pi, 4)
  r <- c(0.2, 1, 0.4, 0.7)
  xy <- radar_outline(pos, r, rounded = TRUE)
  radius <- sqrt(xy$x^2 + xy$y^2)
  angle <- atan2(xy$y, xy$x) %% (2 * pi)
  for (i in seq_along(pos)) {
    j <- which.min(pmin(abs(angle - pos[i]), 2 * pi - abs(angle - pos[i])))
    expect_equal(radius[j], r[i], tolerance = 1e-6)
  }
  expect_true(all(radius <= max(r) + 1e-9))
  expect_true(all(radius >= min(r) - 1e-9))

  # the radius is monotone within each inter-axis segment
  seg <- radius[angle > pi / 2 + 1e-9 & angle < pi - 1e-9]
  expect_true(all(diff(seg) <= 1e-9))
})

test_that("rounded outline traces a circular arc between equal values", {
  pos <- c(0, pi / 2, pi, 3 * pi / 2)
  r <- c(0.5, 0.5, 0.8, 0.5)
  xy <- radar_outline(pos, r, rounded = TRUE)
  radius <- sqrt(xy$x^2 + xy$y^2)
  angle <- atan2(xy$y, xy$x) %% (2 * pi)
  arc <- radius[angle >= 0 & angle <= pi / 2]
  expect_equal(arc, rep(0.5, length(arc)), tolerance = 1e-9)
})
