# Changelog

## VisXplore 2.1.0

### Shiny app improvements

- Variable checkboxes now filter the network plot, correlation matrix,
  and statistics tabs reactively
- Significance radio buttons now work correctly (fixed string-to-numeric
  conversion)
- Statistics tab handles both all-numeric (VIF) and mixed-type (GVIF)
  data
- Added variable checkbox panel to the Statistics tab for interactive
  feature selection
- Fixed crash on launch caused by lazy evaluation of the `data` argument
- Clear error message when calling
  [`VisXplore()`](https://CU-Anschutz-GMWG.github.io/VisXplore/reference/VisXplore.md)
  without data
- Fixed `xtfrm` / “undefined columns selected” errors on the Categorical
  variables tab
- Suppressed `stat_bin()` warning by setting explicit bin count in
  histograms
- Fixed duplicate HTML element IDs between `uiOutput` containers and
  their inputs

### Code recipe tab

- New “Code” tab in the Shiny app accumulates a reproducible R pipeline
  as users apply transformations
- Recipe emits standard
  [`dplyr::mutate()`](https://dplyr.tidyverse.org/reference/mutate.html)
  calls (not package-specific wrappers), so the output is portable
- Includes a “Copy to clipboard” button

### API simplification

- Removed exported transform helpers: `visx_transform()`,
  `visx_ratio()`, `visx_mean_vars()`, `visx_collapse_levels()`
- Users should use
  [`dplyr::mutate()`](https://dplyr.tidyverse.org/reference/mutate.html)
  for preprocessing before passing data to
  [`pairwise_cor()`](https://CU-Anschutz-GMWG.github.io/VisXplore/reference/pairwise_cor.md)
- The Shiny app’s Code tab generates the equivalent `dplyr` code
  automatically

### plot.visx_cor fix

- [`plot()`](https://rdrr.io/r/graphics/plot.default.html) on a
  `visx_cor` object now displays the plot (previously returned invisibly
  without rendering)

### Testing

- Added `testServer()` tests for Shiny reactive logic (transformations,
  code recipe, variable filtering, significance)
- Added `shinytest2` integration smoke test
- Added `shinytest2` to Suggests

## VisXplore 2.0.0

### Package renamed: VisX → VisXplore

- Package renamed to VisXplore and moved to CU-Anschutz-GMWG GitHub
  organization
- Main function renamed
  [`VisX()`](https://CU-Anschutz-GMWG.github.io/VisXplore/reference/VisXplore.md)
  →
  [`VisXplore()`](https://CU-Anschutz-GMWG.github.io/VisXplore/reference/VisXplore.md);
  [`VisX()`](https://CU-Anschutz-GMWG.github.io/VisXplore/reference/VisXplore.md)
  still works but is deprecated
- Forked from yingljin/VisX with full git history preserved

### S3 class system

- [`pairwise_cor()`](https://CU-Anschutz-GMWG.github.io/VisXplore/reference/pairwise_cor.md)
  now returns a `visx_cor` S3 object with
  [`print()`](https://rdrr.io/r/base/print.html),
  [`summary()`](https://rdrr.io/r/base/summary.html),
  [`plot()`](https://rdrr.io/r/graphics/plot.default.html), and
  [`as.data.frame()`](https://rdrr.io/r/base/as.data.frame.html) methods
- Users can now do
  `result <- pairwise_cor(df); plot(result); summary(result)` without
  launching Shiny
- [`data_check()`](https://CU-Anschutz-GMWG.github.io/VisXplore/reference/data_check.md)
  now returns a `visx_check` S3 object with
  [`print()`](https://rdrr.io/r/base/print.html) method

### New exported functions

- [`get_r2()`](https://CU-Anschutz-GMWG.github.io/VisXplore/reference/get_r2.md):
  R-squared / pseudo-R-squared per variable
- [`data_check()`](https://CU-Anschutz-GMWG.github.io/VisXplore/reference/data_check.md):
  data validation utility
- `visx_transform()`: apply log/sqrt transformations to columns
- `visx_ratio()`: compute ratio of two columns
- `visx_mean_vars()`: row-wise mean of selected columns
- `visx_collapse_levels()`: collapse factor levels

### Bug fixes

- Fixed guard condition in
  [`pairwise_cor()`](https://CU-Anschutz-GMWG.github.io/VisXplore/reference/pairwise_cor.md)
  that always evaluated to TRUE
- Fixed redundant computation of symmetric pairs in
  [`pairwise_cor()`](https://CU-Anschutz-GMWG.github.io/VisXplore/reference/pairwise_cor.md)
- Handle single-numeric-variable case in
  [`pairwise_cor()`](https://CU-Anschutz-GMWG.github.io/VisXplore/reference/pairwise_cor.md)

### Code improvements

- Replaced deprecated `mutate_all()`/`mutate_at()` with `across()`
- Vectorized edge-building loops in
  [`npc_mixed_cor()`](https://CU-Anschutz-GMWG.github.io/VisXplore/reference/npc_mixed_cor.md)
- Expanded test suite with edge cases and new test files
