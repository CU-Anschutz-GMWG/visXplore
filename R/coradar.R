
# Co-radar plots: radar plots with correlation-based axis placement.
# Axes are positioned by a force-directed layout so that highly associated
# variables point in similar directions, making the (otherwise arbitrary)
# ordering of radar axes meaningful.

#' Correlation-based radar axis positions
#'
#' @description Computes angular positions for radar plot axes from a
#' correlation/association matrix using a force-directed layout. Each pair of
#' axes is connected by a spring whose ideal length is proportional to
#' \code{1 - |correlation|}, so strongly associated variables end up pointing
#' in similar directions. The layout is annealed from two starting
#' configurations (equidistant axes and angles derived from 2-d MDS of the
#' dissimilarity), refined by coordinate descent, and the better solution is
#' kept. A minimum angular separation is enforced afterwards so that no two
#' axes coincide.
#'
#' @param cor_matrix a square correlation/association matrix with column names,
#'  or a \code{visx_cor} object from \code{\link{pairwise_cor}}
#' @param min_degrees minimum angular separation between any two axes,
#'  in degrees (default 10)
#' @param max_iterations number of annealing iterations (default 500)
#'
#' @return A named numeric vector of axis angles in radians, in \code{[0, 2*pi)},
#'  rotated so the first variable sits at angle 0.
#'
#' @examples
#' cm <- cor(mtcars, method = "spearman")
#' pos <- coradar_pos(cm)
#' round(pos * 180 / pi)
#'
#' @seealso \code{\link{coradar}} which computes positions and archetype
#'  summaries and has a \code{plot()} method
#' @export
coradar_pos <- function(cor_matrix, min_degrees = 10, max_iterations = 500) {
  if (inherits(cor_matrix, "visx_cor")) cor_matrix <- cor_matrix$cor_value
  cor_matrix <- as.matrix(cor_matrix)
  if (nrow(cor_matrix) != ncol(cor_matrix) || is.null(colnames(cor_matrix))) {
    stop("cor_matrix must be a square matrix with column names.")
  }
  if (any(is.na(cor_matrix))) {
    stop("cor_matrix contains missing values.")
  }

  n <- ncol(cor_matrix)
  theta <- 2 * pi * (seq_len(n) - 1) / n
  names(theta) <- colnames(cor_matrix)
  if (n < 2) return(theta)

  min_sep <- min_degrees * pi / 180
  if (n * min_sep >= 2 * pi) {
    warning("min_degrees too large to separate ", n,
            " axes; returning equidistant positions.")
    return(theta)
  }

  # Ideal angular separation: uncorrelated pairs sit opposite (pi apart),
  # perfectly correlated pairs coincide.
  target <- (1 - abs(cor_matrix)) * pi
  diag(target) <- 0

  # anneal + polish from each start, keep the lower-stress solution
  starts <- list(theta)
  mds_xy <- suppressWarnings(stats::cmdscale(target, k = 2))
  if (ncol(mds_xy) == 2) {
    mds_theta <- atan2(mds_xy[, 2], mds_xy[, 1]) %% (2 * pi)
    names(mds_theta) <- names(theta)
    starts <- c(starts, list(mds_theta))
  }
  fits <- lapply(starts, function(s) {
    polish_angles(anneal_angles(s, target, max_iterations), target)
  })
  stresses <- vapply(fits, angle_stress, numeric(1), target = target)
  theta <- fits[[which.min(stresses)]]

  theta <- enforce_min_sep(theta, min_sep)
  (theta - theta[1]) %% (2 * pi)
}


#' Total layout stress: sum of |achieved - target| angular separation
#' @noRd
angle_stress <- function(theta, target) {
  delta <- outer(theta, theta, "-")
  delta <- ((delta + pi) %% (2 * pi)) - pi
  sum(abs(abs(delta) - target)[upper.tri(target)])
}


#' Annealed force-directed refinement of axis angles
#' @noRd
anneal_angles <- function(theta, target, max_iterations) {
  n <- length(theta)
  best <- theta
  best_stress <- Inf
  for (it in seq_len(max_iterations)) {
    delta <- outer(theta, theta, "-")
    delta <- ((delta + pi) %% (2 * pi)) - pi   # signed shortest arc
    resid <- abs(delta) - target               # >0 attract, <0 repel
    stress <- sum(abs(resid[upper.tri(resid)]))
    if (stress < best_stress) {
      best_stress <- stress
      best <- theta
    }
    anneal <- (max_iterations - it + 1) / max_iterations
    theta <- (theta - anneal / n * rowSums(sign(delta) * resid)) %% (2 * pi)
  }
  best
}


#' Coordinate-descent polish: re-place one axis at a time at its optimal
#' angle on a fine grid, sweeping until no axis moves
#' @noRd
polish_angles <- function(theta, target, grid_n = 720L, max_sweeps = 20L) {
  n <- length(theta)
  grid <- 2 * pi * (seq_len(grid_n) - 1) / grid_n
  arc_dist <- function(a, b) {
    d <- abs(a - b) %% (2 * pi)
    pmin(d, 2 * pi - d)
  }
  for (s in seq_len(max_sweeps)) {
    moved <- FALSE
    for (i in seq_len(n)) {
      obj <- rowSums(abs(outer(grid, theta[-i], arc_dist) -
                           rep(target[i, -i], each = grid_n)))
      cur <- sum(abs(arc_dist(theta[i], theta[-i]) - target[i, -i]))
      if (min(obj) < cur - 1e-9) {
        theta[i] <- grid[which.min(obj)]
        moved <- TRUE
      }
    }
    if (!moved) break
  }
  theta
}


#' Enforce minimum angular separation between axis positions
#' @param theta named vector of angles in radians
#' @param min_sep minimum separation in radians
#' @return adjusted angles
#' @noRd
enforce_min_sep <- function(theta, min_sep) {
  if (min_sep <= 0) return(theta)
  n <- length(theta)
  # tiny deterministic offsets so exactly coincident axes can repel
  if (anyDuplicated(round(theta, 10))) {
    theta <- theta + (seq_len(n) - 1) * 1e-8
  }
  for (it in seq_len(200)) {
    delta <- outer(theta, theta, "-")
    delta <- ((delta + pi) %% (2 * pi)) - pi
    d <- abs(delta)
    diag(d) <- Inf
    if (all(d >= min_sep - 1e-9)) break
    push <- pmax(min_sep - d, 0) / 2
    theta <- (theta + rowSums(sign(delta) * push)) %% (2 * pi)
  }
  theta
}


#' Co-radar plot: radar plot with correlation-based axes
#'
#' @description Builds a co-radar plot object: a radar (spider) plot whose axis
#' angles are determined by the correlation structure of the data (see
#' \code{\link{coradar_pos}}), rather than arbitrary equidistant ordering.
#' Variables are normalized to a common scale, and one or more group
#' "archetypes" (mean shapes with a variability band) are summarized for
#' display via \code{plot()}.
#'
#' @param data a data.frame
#' @param vars variables to display as axes (default: all numeric columns).
#'  Ordinal variables can be included by coding them as numeric first.
#' @param groups controls archetype grouping. One of:
#' \describe{
#'   \item{\code{NULL}}{a single overall archetype (default)}
#'   \item{a column name}{group by that column of \code{data} (the column is
#'     excluded from the axes)}
#'   \item{a single number \code{k}}{k-means clustering with \code{k} clusters
#'     on the normalized variables (set a seed first for reproducibility)}
#'   \item{a vector with one value per row}{pre-computed group assignments}
#' }
#' @param normalize how to scale each variable to the common radial axis:
#'  \code{"minmax"} (default; observed range maps to \code{[0, 1]}),
#'  \code{"rank"} (rank-transform, robust to skew), or \code{"none"}
#'  (data must already share a comparable non-negative scale)
#' @param cor_matrix optional correlation/association matrix (or
#'  \code{visx_cor} object) used for axis placement. Defaults to the Spearman
#'  correlation of \code{vars} in \code{reference} if supplied, otherwise in
#'  \code{data}. Use this to lay the axes out according to an association
#'  structure estimated elsewhere (a published matrix, or a reference cohort)
#' @param reference optional data.frame of external reference data containing
#'  \code{vars}, used to define the radial scale so that a given radius means
#'  the same thing across datasets. When \code{cor_matrix} is not supplied the
#'  axis layout is estimated from \code{reference} as well. For
#'  \code{normalize = "minmax"} only the reference range matters, so a
#'  two-row data.frame of per-variable minima and maxima is enough; for
#'  \code{normalize = "rank"} the full reference distribution is used. Values
#'  in \code{data} outside the reference range are held at the axis bounds
#'  (with a warning)
#' @param min_degrees minimum angular separation between axes, in degrees
#' @param max_iterations annealing iterations for the axis layout
#'
#' @return A \code{visx_coradar} object (S3 class) containing:
#' \describe{
#'   \item{positions}{named vector of axis angles in radians}
#'   \item{stats}{data.frame of archetype summaries (group, variable, mean, sd, pos)}
#'   \item{data}{the complete-case data for \code{vars}}
#'   \item{data_scaled}{the normalized data}
#'   \item{groups}{factor of group assignments (or NULL)}
#'   \item{group_source}{how groups were formed: "overall", "column",
#'     "assignment", or "kmeans"}
#'   \item{cor_matrix}{the matrix used for axis placement}
#'   \item{scale_ref}{the data defining the radial scale: \code{reference} if
#'     supplied, otherwise \code{data}}
#'   \item{has_reference}{TRUE when an external \code{reference} was supplied}
#' }
#' Use \code{print()} and \code{plot()} methods on the result.
#'
#' @examples
#' result <- coradar(mtcars, vars = c("mpg", "disp", "hp", "drat", "wt", "qsec"))
#' result
#' plot(result)
#'
#' # two k-means archetypes
#' set.seed(1)
#' plot(coradar(mtcars, vars = c("mpg", "disp", "hp", "drat", "wt", "qsec"),
#'              groups = 2))
#'
#' # group by an existing column
#' plot(coradar(mtcars, vars = c("mpg", "disp", "hp", "wt", "qsec"),
#'              groups = "am"))
#'
#' # axes and radial scale taken from an external reference cohort, so the
#' # two subgroup plots below are directly comparable
#' v <- c("mpg", "disp", "hp", "drat", "wt", "qsec")
#' plot(coradar(mtcars[mtcars$am == 0, ], vars = v, reference = mtcars))
#' plot(coradar(mtcars[mtcars$am == 1, ], vars = v, reference = mtcars))
#'
#' @importFrom stats complete.cases cor kmeans
#' @export
coradar <- function(data, vars = NULL, groups = NULL,
                    normalize = c("minmax", "rank", "none"),
                    cor_matrix = NULL, reference = NULL,
                    min_degrees = 10, max_iterations = 500) {
  normalize <- match.arg(normalize)
  if (!is.data.frame(data)) stop("data must be a data.frame.")
  data <- as.data.frame(data)

  # a single string names a grouping column
  group_var <- NULL
  if (is.character(groups) && length(groups) == 1) {
    if (!groups %in% names(data)) {
      stop("groups column '", groups, "' not found in data.")
    }
    group_var <- groups
    groups <- data[[group_var]]
  }

  if (is.null(vars)) {
    vars <- names(data)[vapply(data, is.numeric, logical(1))]
  }
  vars <- setdiff(vars, group_var)
  missing_vars <- setdiff(vars, names(data))
  if (length(missing_vars)) {
    stop("Variables not found in data: ", paste(missing_vars, collapse = ", "))
  }
  non_num <- vars[!vapply(data[vars], is.numeric, logical(1))]
  if (length(non_num)) {
    stop("Co-radar axes must be numeric. Non-numeric variables: ",
         paste(non_num, collapse = ", "),
         ". Code ordinal variables as numeric to include them.")
  }
  if (length(vars) < 3) {
    stop("A co-radar plot requires at least 3 numeric variables.")
  }

  x <- data[vars]
  keep <- complete.cases(x)
  if (!all(keep)) {
    message("Removed ", sum(!keep), " rows with missing values.")
    x <- x[keep, , drop = FALSE]
  }
  if (nrow(x) < 2) stop("Not enough complete rows to summarize.")

  # an external reference cohort defines the radial scale, and (unless a
  # cor_matrix is given) the association structure behind the axis layout
  scale_ref <- validate_reference(reference, vars)
  has_reference <- !is.null(scale_ref)
  if (!has_reference) scale_ref <- x

  # axis placement from association structure
  if (is.null(cor_matrix)) {
    cor_source <- if (has_reference) scale_ref else x
    if (has_reference && sum(complete.cases(cor_source)) < 3) {
      stop("reference has fewer than 3 complete rows, which is not enough to ",
           "estimate an association structure. Supply cor_matrix instead.")
    }
    cmat <- spearman_layout(cor_source, vars)
  } else {
    if (inherits(cor_matrix, "visx_cor")) cor_matrix <- cor_matrix$cor_value
    cor_matrix <- as.matrix(cor_matrix)
    if (is.null(rownames(cor_matrix)) && !is.null(colnames(cor_matrix))) {
      rownames(cor_matrix) <- colnames(cor_matrix)
    }
    labs <- intersect(rownames(cor_matrix), colnames(cor_matrix))
    if (!all(vars %in% labs)) {
      stop("cor_matrix must have all plotted variables as both row and ",
           "column names. Missing: ",
           paste(setdiff(vars, labs), collapse = ", "))
    }
    cmat <- cor_matrix[vars, vars]
  }
  positions <- coradar_pos(cmat, min_degrees, max_iterations)

  # normalize on the reference scale; with an external reference the data can
  # fall outside it, so clamp to keep radii on the axes (see rescale_var)
  if (has_reference && normalize == "minmax") {
    outside <- vars[vapply(vars, function(v) {
      rng <- range(scale_ref[[v]], na.rm = TRUE)
      any(x[[v]] < rng[1] | x[[v]] > rng[2], na.rm = TRUE)
    }, logical(1))]
    if (length(outside)) {
      warning("Values outside the reference range were clamped to the axis ",
              "bounds for: ", paste(outside, collapse = ", "))
    }
  }
  x_scaled <- as.data.frame(
    Map(function(v, nm) rescale_var(v, normalize, ref = scale_ref[[nm]],
                                    clamp = has_reference),
        x, vars),
    check.names = FALSE
  )

  # resolve archetype groups
  if (is.null(groups)) {
    grp <- NULL
    group_source <- "overall"
  } else if (is.numeric(groups) && length(groups) == 1) {
    k <- as.integer(groups)
    if (k < 1) stop("groups must be a positive number of clusters.")
    n_distinct <- nrow(unique(x_scaled))
    if (k > n_distinct) {
      stop("Requested ", k, " clusters but only ", n_distinct,
           " distinct complete observations are available.")
    }
    km <- kmeans(x_scaled, centers = k, nstart = 20)
    grp <- factor(paste("Cluster", km$cluster))
    group_source <- "kmeans"
  } else if (length(groups) == nrow(data)) {
    grp <- factor(groups[keep])
    group_source <- if (!is.null(group_var)) "column" else "assignment"
  } else {
    stop("groups must be NULL, a column name, a number of clusters, ",
         "or a vector with one value per row of data.")
  }

  # archetype summaries on the normalized scale
  g <- if (is.null(grp)) factor(rep("Overall", nrow(x_scaled))) else grp
  stats_df <- do.call(rbind, lapply(levels(g), function(lev) {
    sub <- x_scaled[!is.na(g) & g == lev, , drop = FALSE]
    data.frame(group = lev, variable = vars,
               mean = vapply(sub, mean, numeric(1)),
               sd = vapply(sub, stats::sd, numeric(1)),
               pos = unname(positions[vars]),
               row.names = NULL)
  }))
  stats_df$group <- factor(stats_df$group, levels = levels(g))

  structure(
    list(
      positions = positions,
      stats = stats_df,
      data = x,
      data_scaled = x_scaled,
      groups = grp,
      group_var = group_var,
      group_source = group_source,
      cor_matrix = cmat,
      normalize = normalize,
      scale_ref = scale_ref,
      has_reference = has_reference
    ),
    class = "visx_coradar"
  )
}


#' Validate an external reference cohort for coradar()
#' @param reference a data.frame (or NULL)
#' @param vars variables that must be present and numeric
#' @return the reference restricted to vars, or NULL
#' @noRd
validate_reference <- function(reference, vars) {
  if (is.null(reference)) return(NULL)
  if (!is.data.frame(reference)) stop("reference must be a data.frame.")
  reference <- as.data.frame(reference, check.names = FALSE)
  missing_ref <- setdiff(vars, names(reference))
  if (length(missing_ref)) {
    stop("reference is missing plotted variables: ",
         paste(missing_ref, collapse = ", "))
  }
  ref <- reference[vars]
  non_num <- vars[!vapply(ref, is.numeric, logical(1))]
  if (length(non_num)) {
    stop("reference variables must be numeric. Non-numeric: ",
         paste(non_num, collapse = ", "))
  }
  empty <- vars[vapply(ref, function(v) all(is.na(v)), logical(1))]
  if (length(empty)) {
    stop("reference has no non-missing values for: ",
         paste(empty, collapse = ", "))
  }
  ref
}


#' Spearman association matrix used for axis layout
#'
#' Constant columns have undefined correlation; they are placed neutrally so
#' the layout still runs.
#' @param df a data.frame containing vars
#' @param vars variables to include
#' @return a square correlation matrix over vars
#' @noRd
spearman_layout <- function(df, vars) {
  d <- df[vars]
  constant <- vapply(d, function(v) {
    rng <- range(v, na.rm = TRUE)
    isTRUE(diff(rng) == 0)
  }, logical(1))
  if (any(constant)) {
    message("Constant variable(s) treated as uncorrelated on the layout: ",
            paste(vars[constant], collapse = ", "))
  }
  # constant columns make cor() warn about zero standard deviation and return
  # NA; we handle those NAs explicitly below, so suppress the warning
  cmat <- suppressWarnings(
    cor(d, method = "spearman", use = "pairwise.complete.obs")
  )
  cmat[is.na(cmat)] <- 0
  diag(cmat) <- 1
  cmat
}


#' Normalize a variable to the common radial scale
#' @param v numeric vector
#' @param method "minmax", "rank", or "none"
#' @param ref reference vector defining the scale (defaults to v itself);
#'  used to place new observations on the scale of the original data
#' @param clamp if TRUE, hold values outside the reference range at the axis
#'  bounds (used for individual overlays so an out-of-range value cannot map
#'  to a negative radius and reflect through the plot origin)
#' @return rescaled numeric vector
#' @noRd
rescale_var <- function(v, method, ref = v, clamp = FALSE) {
  out <- switch(method,
    minmax = {
      rng <- range(ref, na.rm = TRUE)
      if (diff(rng) == 0) rep(0.5, length(v))
      else (v - rng[1]) / diff(rng)
    },
    rank = stats::ecdf(ref)(v),
    none = v
  )
  if (clamp && method != "none") out <- pmin(pmax(out, 0), 1)
  out
}


#' Print method for visx_coradar objects
#'
#' @param x a visx_coradar object
#' @param ... additional arguments (ignored)
#'
#' @return x, invisibly
#' @export
print.visx_coradar <- function(x, ...) {
  cat("Co-radar plot of", length(x$positions), "variables,",
      nrow(x$data_scaled), "observations\n")
  if (!is.null(x$groups)) {
    src <- switch(x$group_source,
                  column = paste0("column '", x$group_var, "'"),
                  assignment = "supplied assignment",
                  "k-means")
    cat("Archetypes (", src, "): ",
        paste(levels(x$groups), collapse = ", "), "\n", sep = "")
  }
  cat("Normalization:", x$normalize, "\n")
  if (isTRUE(x$has_reference)) {
    cat("Radial scale from an external reference of ",
        nrow(x$scale_ref), " rows\n", sep = "")
  }
  deg <- round(sort(x$positions) * 180 / pi)
  cat("\nAxis positions (degrees):\n")
  print(deg)
  invisible(x)
}


#' Plot method for visx_coradar objects
#'
#' @description Draws the co-radar plot: axes placed by correlation structure,
#' one mean polygon per archetype, and (optionally) a shaded band showing
#' within-group variability that fades with distance from the mean shape.
#'
#' @param x a visx_coradar object
#' @param sd_band if TRUE (default), shade a band of \code{mean +/- band_width * sd / 2}
#'  around each archetype
#' @param band_width multiplier for the width of the variability band (default 1)
#' @param rounded if TRUE, draw archetype shapes, variability bands, and
#'  individual overlays as rounded closed curves instead of straight-edged
#'  polygons. Between adjacent axes the radius changes monotonically (equal
#'  values trace a perfect circular arc, and the curve never moves opposite
#'  to the net direction), with slopes allowed to change abruptly at each
#'  axis. Useful when correlated axes occupy a narrow arc: the segment closing
#'  a straight polygon (last axis back to the first) cuts across the plot,
#'  while a rounded shape sweeps around it
#' @param individuals optional individual observations to overlay as black
#'  polygons: either row indices into the (complete-case) data, or a data.frame
#'  of raw values containing the plotted variables (normalized to the scale of
#'  the original data)
#' @param highlight optional character vector of variable names whose axes are
#'  emphasized; remaining axes and labels are greyed out
#' @param imputed optional multiply imputed data for individuals with missing
#'  values: a list of M completed data.frames with identical rows, each
#'  containing the plotted variables (for example
#'  \code{mice::complete(imp, "all")}). Each requested individual is drawn as
#'  a shaded envelope across the M draws with a dashed median shape. Where a
#'  variable was observed all draws agree, so the envelope pinches to a point
#'  on that axis; where it was imputed the envelope opens into a region
#'  spanning the plausible values
#' @param imputed_rows rows of the completed data.frames to draw. These index
#'  the data that was passed to the imputation model, not the complete-case
#'  data held in \code{x}. Defaults to the rows that actually differ across
#'  the imputations, i.e. the people who were missing at least one plotted
#'  variable; complete rows carry no uncertainty and are skipped. If more than
#'  12 rows qualify, choose them explicitly rather than overplotting
#' @param extent width of the imputation envelope: \code{"range"} (default,
#'  the full min-to-max span of the M draws) or \code{"quantile"}
#' @param probs two probabilities defining the envelope when
#'  \code{extent = "quantile"} (default 10th and 90th percentiles)
#' @param label_size size of the axis labels (default 4)
#' @param legend if TRUE, show the archetype legend when groups are present
#' @param ... additional arguments (ignored)
#'
#' @return a ggplot object, invisibly
#'
#' @examples
#' result <- coradar(mtcars, vars = c("mpg", "disp", "hp", "drat", "wt", "qsec"))
#' plot(result, individuals = 1)
#' plot(result, highlight = c("mpg", "wt"))
#' plot(result, rounded = TRUE)
#'
#' # a person whose hp and wt are missing, with 5 imputations of each. In
#' # practice these come from mice::complete(imp, "all")
#' set.seed(1)
#' person <- mtcars[1, c("mpg", "disp", "hp", "drat", "wt", "qsec")]
#' imps <- lapply(1:5, function(i) {
#'   d <- person
#'   d$hp <- sample(mtcars$hp, 1)
#'   d$wt <- sample(mtcars$wt, 1)
#'   d
#' })
#' plot(result, imputed = imps, rounded = TRUE)
#'
#' @import ggplot2
#' @export
plot.visx_coradar <- function(x, sd_band = TRUE, band_width = 1,
                              rounded = FALSE,
                              individuals = NULL, highlight = NULL,
                              imputed = NULL, imputed_rows = NULL,
                              extent = c("range", "quantile"),
                              probs = c(0.1, 0.9),
                              label_size = 4, legend = TRUE, ...) {
  extent <- match.arg(extent)
  theta <- x$positions
  vars <- names(theta)
  has_groups <- !is.null(x$groups)
  n_bands <- 10L

  if (!is.null(highlight)) {
    bad <- setdiff(highlight, vars)
    if (length(bad)) {
      stop("highlight variables not on the plot: ", paste(bad, collapse = ", "))
    }
  }

  # reference circles and axis spokes
  circ_theta <- seq(0, 2 * pi, length.out = 181)
  circles <- do.call(rbind, lapply(c(0.25, 0.5, 0.75, 1), function(r) {
    data.frame(id = r, x = r * cos(circ_theta), y = r * sin(circ_theta))
  }))
  axes <- data.frame(
    variable = vars,
    xend = cos(theta), yend = sin(theta),
    lx = 1.12 * cos(theta), ly = 1.12 * sin(theta),
    emphasized = if (is.null(highlight)) TRUE else vars %in% highlight
  )

  shape <- x$stats[order(x$stats$group, x$stats$pos), ]

  p <- ggplot() +
    geom_path(data = circles, aes(x, y, group = id),
              color = "grey85", linewidth = 0.3) +
    geom_segment(data = axes,
                 aes(x = 0, y = 0, xend = xend, yend = yend),
                 color = ifelse(axes$emphasized, "grey40", "grey85"),
                 linewidth = ifelse(axes$emphasized, 0.4, 0.3))

  # variability bands: nested translucent annuli whose overlap fades the
  # shading with distance from the mean shape. Outer and inner boundaries are
  # separate subgroups so even-odd filling leaves the hole open and covers the
  # full circuit (including the sector between the last and first axes)
  if (sd_band) {
    band_alpha <- 1 - (1 - 0.35)^(1 / n_bands)
    bands <- do.call(rbind, lapply(split(shape, shape$group), function(s) {
      hw <- band_width * ifelse(is.na(s$sd), 0, s$sd) / 2
      do.call(rbind, lapply(seq_len(n_bands), function(j) {
        f <- j / n_bands
        outer_xy <- radar_outline(s$pos, s$mean + f * hw, rounded)
        inner_xy <- radar_outline(s$pos, pmax(s$mean - f * hw, 0), rounded)
        data.frame(
          group = s$group[1],
          poly_id = paste(s$group[1], j),
          ring = rep(1:2, c(nrow(outer_xy), nrow(inner_xy))),
          rbind(outer_xy, inner_xy)
        )
      }))
    }))
    p <- p + geom_polygon(data = bands,
                          aes(x, y, group = poly_id, subgroup = ring,
                              fill = group),
                          alpha = band_alpha, color = NA)
  }

  # archetype mean shapes
  outlines <- do.call(rbind, lapply(split(shape, shape$group), function(s) {
    data.frame(group = s$group[1], radar_outline(s$pos, s$mean, rounded))
  }))
  p <- p + geom_polygon(data = outlines,
                        aes(x, y, group = group, color = group),
                        fill = NA, linewidth = 1)

  # overlay multiply imputed individuals as pinched envelopes. Same annulus
  # construction as the variability band: outer and inner boundaries are
  # polygon subgroups so even-odd filling leaves the interior open
  if (!is.null(imputed)) {
    env <- imputed_envelope(x, imputed, imputed_rows, extent, probs)
    imp_bands <- do.call(rbind, lapply(seq_along(env), function(k) {
      outer_xy <- radar_outline(theta, env[[k]]$hi[vars], rounded)
      inner_xy <- radar_outline(theta, env[[k]]$lo[vars], rounded)
      data.frame(
        poly_id = k,
        ring = rep(1:2, c(nrow(outer_xy), nrow(inner_xy))),
        rbind(outer_xy, inner_xy)
      )
    }))
    imp_mid <- do.call(rbind, lapply(seq_along(env), function(k) {
      data.frame(poly_id = k, radar_outline(theta, env[[k]]$mid[vars], rounded))
    }))
    p <- p +
      geom_polygon(data = imp_bands,
                   aes(x, y, group = poly_id, subgroup = ring),
                   fill = "grey20", alpha = 0.25, color = NA) +
      geom_polygon(data = imp_mid, aes(x, y, group = poly_id),
                   fill = NA, color = "black", linewidth = 0.6,
                   linetype = "22")
  }

  # overlay individual observations
  if (!is.null(individuals)) {
    ind <- individuals_scaled(x, individuals)
    ind_long <- do.call(rbind, lapply(seq_len(nrow(ind)), function(i) {
      data.frame(poly_id = i,
                 radar_outline(theta, unlist(ind[i, vars]), rounded))
    }))
    p <- p + geom_polygon(data = ind_long, aes(x, y, group = poly_id),
                          fill = NA, color = "black", linewidth = 0.6)
  }

  legend_name <- if (!is.null(x$group_var)) x$group_var else "Archetype"
  p <- p +
    geom_text(data = axes,
              aes(x = lx, y = ly, label = variable),
              color = ifelse(axes$emphasized, "black", "grey70"),
              fontface = ifelse(axes$emphasized, "bold", "plain"),
              size = label_size) +
    scale_color_discrete(name = legend_name) +
    scale_fill_discrete(name = legend_name) +
    coord_equal(clip = "off") +
    theme_void() +
    theme(legend.position = if (legend && has_groups) "right" else "none")

  print(p)
  invisible(p)
}


#' Boundary points of a radar shape
#'
#' @param pos axis angles in radians (any order; paired with r)
#' @param r radius at each axis
#' @param rounded if TRUE, return a dense closed curve through the axis
#'  points; otherwise just the vertices. Each inter-axis segment interpolates
#'  the radius with a smoothstep (cubic Hermite with zero end-slopes), so the
#'  curve is tangent to a circle at every axis: equal adjacent values trace a
#'  perfect circular arc, and the radius moves strictly monotonically between
#'  unequal values — it never reverses direction within a segment. Slopes are
#'  intentionally not continuous across axes
#' @return data.frame with columns x, y, ordered by angle
#' @noRd
radar_outline <- function(pos, r, rounded, n_dense = 361L) {
  ord <- order(pos)
  pos <- pos[ord]
  r <- r[ord]
  if (rounded) {
    # close the loop and build each segment independently
    pos_c <- c(pos, pos[1] + 2 * pi)
    r_c <- c(r, r[1])
    segs <- lapply(seq_along(pos), function(i) {
      width <- pos_c[i + 1] - pos_c[i]
      k <- max(2L, ceiling(width / (2 * pi) * n_dense))
      tt <- seq(0, 1, length.out = k)
      data.frame(pos = pos_c[i] + tt * width,
                 r = r_c[i] + (r_c[i + 1] - r_c[i]) * (3 * tt^2 - 2 * tt^3))
    })
    segs <- do.call(rbind, segs)
    pos <- segs$pos
    r <- segs$r
  }
  data.frame(x = r * cos(pos), y = r * sin(pos))
}


#' Pointwise envelope of multiply imputed individuals
#'
#' Scales every completed dataset onto the co-radar's reference scale and
#' summarizes, for each requested row, the spread of the M draws at each axis.
#' Because an observed value is identical across imputations, \code{lo} and
#' \code{hi} coincide there and the resulting band pinches to a point; only
#' imputed axes open into a region.
#'
#' @param x a visx_coradar object
#' @param imputed list of M completed data.frames with identical row counts
#' @param rows rows of the completed data to summarize. Defaults to the rows
#'  that actually differ across imputations, i.e. those that were missing at
#'  least one plotted variable
#' @param extent "range" (min to max) or "quantile"
#' @param probs two probabilities used when extent = "quantile"
#' @param max_auto largest number of rows to select automatically before
#'  asking the caller to choose
#' @return list with one element per row: row, lo, hi, mid (named by variable)
#' @noRd
imputed_envelope <- function(x, imputed, rows = NULL, extent = "range",
                             probs = c(0.1, 0.9), max_auto = 12L) {
  vars <- names(x$positions)
  if (inherits(imputed, "mids")) {
    stop("imputed must be a list of completed data.frames. Convert a mids ",
         "object first with mice::complete(obj, \"all\").")
  }
  if (is.data.frame(imputed) || !is.list(imputed)) {
    stop("imputed must be a list of completed data.frames, one per imputation.")
  }
  frames <- lapply(imputed, function(d) as.data.frame(d, check.names = FALSE))
  if (length(frames) < 2) {
    stop("imputed must contain at least 2 completed datasets.")
  }
  nr <- vapply(frames, nrow, integer(1))
  if (length(unique(nr)) != 1) {
    stop("all completed datasets must have the same number of rows.")
  }
  if (is.null(rows)) {
    # only rows that were actually imputed carry any uncertainty; a complete
    # row is identical in every draw and would plot as a bare outline
    missing_vars <- setdiff(vars, Reduce(intersect, lapply(frames, names)))
    if (length(missing_vars)) {
      stop("imputed data is missing plotted variables: ",
           paste(missing_vars, collapse = ", "))
    }
    base <- as.matrix(frames[[1]][vars])
    varies <- Reduce(`|`, lapply(frames[-1], function(d) {
      differs <- as.matrix(d[vars]) != base
      differs[is.na(differs)] <- TRUE
      apply(differs, 1, any)
    }))
    rows <- which(varies)
    if (!length(rows)) {
      stop("No rows differ across the imputations, so there is nothing to ",
           "draw. The plotted variables are complete for every row; use ",
           "individuals = to overlay observed people.")
    }
    if (length(rows) > max_auto) {
      stop(length(rows), " rows have imputed values among the plotted ",
           "variables, which would overplot. Choose which to draw with ",
           "imputed_rows, e.g. imputed_rows = c(",
           paste(rows[seq_len(min(3L, length(rows)))], collapse = ", "), ").")
    }
    if (length(rows) > 1) {
      message("Drawing ", length(rows), " individuals with imputed values ",
              "(rows ", paste(rows, collapse = ", "), ").")
    }
  } else {
    if (!is.numeric(rows) || !is.null(dim(rows))) {
      stop("imputed_rows must be a numeric vector of row indices.")
    }
    if (any(rows < 1 | rows > nr[1])) {
      stop("imputed_rows out of range (1 to ", nr[1], ").")
    }
    rows <- as.integer(rows)
  }
  if (!length(rows)) stop("imputed_rows selected no rows.")

  if (extent == "quantile") {
    if (!is.numeric(probs) || length(probs) != 2 ||
        any(is.na(probs)) || any(probs < 0 | probs > 1)) {
      stop("probs must be two probabilities between 0 and 1.")
    }
    probs <- sort(probs)
  }

  # scale every draw on the co-radar's reference scale; out-of-range draws are
  # clamped by individuals_scaled(), which would otherwise warn once per draw
  clamped <- FALSE
  scaled <- lapply(frames, function(d) {
    withCallingHandlers(
      individuals_scaled(x, d[rows, , drop = FALSE]),
      warning = function(w) {
        if (grepl("clamped", conditionMessage(w))) {
          clamped <<- TRUE
          invokeRestart("muffleWarning")
        }
      }
    )
  })
  if (clamped) {
    warning("Some imputed values fall outside the reference range and were ",
            "clamped to the axis bounds.")
  }

  lapply(seq_along(rows), function(i) {
    draws <- do.call(rbind, lapply(scaled, function(s) {
      as.numeric(s[i, vars])
    }))
    if (extent == "range") {
      lo <- apply(draws, 2, min)
      hi <- apply(draws, 2, max)
    } else {
      lo <- apply(draws, 2, stats::quantile, probs = probs[1], names = FALSE)
      hi <- apply(draws, 2, stats::quantile, probs = probs[2], names = FALSE)
    }
    mid <- apply(draws, 2, stats::median)
    list(row = rows[i],
         lo = stats::setNames(lo, vars),
         hi = stats::setNames(hi, vars),
         mid = stats::setNames(mid, vars))
  })
}


#' Resolve and normalize the individuals argument of plot.visx_coradar
#' @param x a visx_coradar object
#' @param individuals row indices or a data.frame of raw values
#' @return data.frame of normalized values with the plotted variables
#' @noRd
individuals_scaled <- function(x, individuals) {
  vars <- names(x$positions)
  if (is.numeric(individuals) && is.null(dim(individuals))) {
    bad <- individuals[individuals < 1 | individuals > nrow(x$data_scaled)]
    if (length(bad)) {
      stop("individuals indices out of range (1 to ", nrow(x$data_scaled), ").")
    }
    return(x$data_scaled[individuals, , drop = FALSE])
  }
  individuals <- as.data.frame(individuals, check.names = FALSE)
  missing_vars <- setdiff(vars, names(individuals))
  if (length(missing_vars)) {
    stop("individuals data is missing plotted variables: ",
         paste(missing_vars, collapse = ", "))
  }
  # objects built before scale_ref existed fall back to the training data
  ref <- if (!is.null(x$scale_ref)) x$scale_ref else x$data
  out <- individuals[vars]
  outside <- FALSE
  for (v in vars) {
    rng <- range(ref[[v]], na.rm = TRUE)
    if (x$normalize == "minmax" &&
        any(out[[v]] < rng[1] | out[[v]] > rng[2], na.rm = TRUE)) {
      outside <- TRUE
    }
    out[[v]] <- rescale_var(out[[v]], x$normalize, ref = ref[[v]],
                            clamp = TRUE)
  }
  if (outside) {
    warning("Some individual values fall outside the observed range of the ",
            "data and were clamped to the axis bounds.")
  }
  out
}
