# Changelog

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
- [`visx_transform()`](https://CU-Anschutz-GMWG.github.io/VisXplore/reference/visx_transform.md):
  apply log/sqrt transformations to columns
- [`visx_ratio()`](https://CU-Anschutz-GMWG.github.io/VisXplore/reference/visx_ratio.md):
  compute ratio of two columns
- [`visx_mean_vars()`](https://CU-Anschutz-GMWG.github.io/VisXplore/reference/visx_mean_vars.md):
  row-wise mean of selected columns
- [`visx_collapse_levels()`](https://CU-Anschutz-GMWG.github.io/VisXplore/reference/visx_collapse_levels.md):
  collapse factor levels

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
