
# VisXplore 2.3.0

## Co-radar improvements
- New `rounded` option in `plot.visx_coradar()`: archetype shapes,
  variability bands, and individual overlays are drawn as rounded closed
  curves instead of straight-edged polygons. The radius changes
  monotonically between adjacent axes — equal values trace a perfect
  circular arc and the curve never moves opposite to the net direction
  within a segment — with slopes intentionally discontinuous at each axis
- Fixed the variability band not covering the sector between the last and
  first axes; bands are now drawn as true annuli (outer and inner
  boundaries as polygon subgroups with even-odd fill)
- Added a "Rounded shapes" checkbox to the Shiny co-radar tab

# VisXplore 2.2.0

## Co-radar plots
- New `coradar()` function creates correlation-based radar plots: axis angles
  are set by the association structure of the data (via a force-directed
  layout), so strongly correlated variables point in similar directions and
  the arbitrary axis ordering of traditional radar plots is resolved
- Returns a `visx_coradar` S3 object with `print()` and `plot()` methods
- Archetype support: summarize the whole sample, groups defined by a column,
  or k-means clusters as mean shapes with a shaded variability band
- `plot()` options to overlay individual observations (`individuals`) and to
  emphasize model-selected axes (`highlight`)
- Normalization options: min-max (default), rank (robust to skew), or none
- New `coradar_pos()` exposes the axis-placement algorithm directly; accepts a
  plain correlation matrix or a `pairwise_cor()` result, enforces a minimum
  angular separation between axes
- The layout algorithm anneals from equidistant and MDS-derived starting
  positions and refines with coordinate descent; it achieves lower layout
  stress than the original prototype at a fraction of the runtime
- New "Co-radar plot" tab in the Shiny app with variable selection, k-means
  archetypes, minimum axis separation, and variability band controls

## Code improvements
- Clearer matrix indexing in `corstars()`, removed a redundant data copy in
  `get_r2()`, moved a constant alpha out of `aes()` in `npc_mixed_cor()`
- Fixed typos in the Shiny app Note tab

# VisXplore 2.1.0

## Shiny app improvements
- Variable checkboxes now filter the network plot, correlation matrix, and statistics tabs reactively
- Significance radio buttons now work correctly (fixed string-to-numeric conversion)
- Statistics tab handles both all-numeric (VIF) and mixed-type (GVIF) data
- Added variable checkbox panel to the Statistics tab for interactive feature selection
- Fixed crash on launch caused by lazy evaluation of the `data` argument
- Clear error message when calling `VisXplore()` without data
- Fixed `xtfrm` / "undefined columns selected" errors on the Categorical variables tab
- Suppressed `stat_bin()` warning by setting explicit bin count in histograms
- Fixed duplicate HTML element IDs between `uiOutput` containers and their inputs

## Code recipe tab
- New "Code" tab in the Shiny app accumulates a reproducible R pipeline as users apply transformations
- Recipe emits standard `dplyr::mutate()` calls (not package-specific wrappers), so the output is portable
- Includes a "Copy to clipboard" button

## API simplification
- Removed exported transform helpers: `visx_transform()`, `visx_ratio()`, `visx_mean_vars()`, `visx_collapse_levels()`
- Users should use `dplyr::mutate()` for preprocessing before passing data to `pairwise_cor()`
- The Shiny app's Code tab generates the equivalent `dplyr` code automatically

## plot.visx_cor fix
- `plot()` on a `visx_cor` object now displays the plot (previously returned invisibly without rendering)

## Testing
- Added `testServer()` tests for Shiny reactive logic (transformations, code recipe, variable filtering, significance)
- Added `shinytest2` integration smoke test
- Added `shinytest2` to Suggests

# VisXplore 2.0.0

## Package renamed: VisX → VisXplore
- Package renamed to VisXplore and moved to CU-Anschutz-GMWG GitHub organization
- Main function renamed `VisX()` → `VisXplore()`; `VisX()` still works but is deprecated
- Forked from yingljin/VisX with full git history preserved

## S3 class system
- `pairwise_cor()` now returns a `visx_cor` S3 object with `print()`, 
  `summary()`, `plot()`, and `as.data.frame()` methods
- Users can now do `result <- pairwise_cor(df); plot(result); summary(result)` 
  without launching Shiny
- `data_check()` now returns a `visx_check` S3 object with `print()` method

## New exported functions
- `get_r2()`: R-squared / pseudo-R-squared per variable
- `data_check()`: data validation utility
- `visx_transform()`: apply log/sqrt transformations to columns
- `visx_ratio()`: compute ratio of two columns
- `visx_mean_vars()`: row-wise mean of selected columns
- `visx_collapse_levels()`: collapse factor levels

## Bug fixes
- Fixed guard condition in `pairwise_cor()` that always evaluated to TRUE
- Fixed redundant computation of symmetric pairs in `pairwise_cor()`
- Handle single-numeric-variable case in `pairwise_cor()`

## Code improvements
- Replaced deprecated `mutate_all()`/`mutate_at()` with `across()`
- Vectorized edge-building loops in `npc_mixed_cor()` 
- Expanded test suite with edge cases and new test files

# VisX 0.3.0

- Updated documentation, reduced dependencies
- Exported more functions so that plots + associations can be worked with 
  outside shiny (interactively in R)
- Added download data button
- Added dependency on `nnet`  (previously imported, but this was causing issues)

# VisX 0.2.0

- Initial version completed
