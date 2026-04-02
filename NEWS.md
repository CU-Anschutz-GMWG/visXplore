
# 2.0.0

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

# 0.3.0

- Updated documentation, reduced dependencies
- Exported more functions so that plots + associations can be worked with 
  outside shiny (interactively in R)
- Added download data button
- Added dependency on `nnet`  (previously imported, but this was causing issues)

# 0.2.0

- Initial version completed
