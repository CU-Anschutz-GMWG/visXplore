# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

VisXplore (formerly VisX) is an R package for interactive data preprocessing and variable selection across mixed variable types (numeric, nominal/factor, ordinal). It provides both a **code-forward S3 API** for use in scripts/notebooks and an optional **Shiny app** for interactive exploration.

Typical programmatic workflow:
```r
result <- pairwise_cor(mtcars)
result          # print summary
summary(result) # formatted correlation matrix with significance stars
plot(result)    # network plot (returns ggplot)
```

## Common Commands

```r
# Install dependencies and build
devtools::install_deps(dependencies = TRUE)
devtools::document()    # regenerate NAMESPACE and man/ from roxygen2 comments
devtools::build()

# Run full R CMD check (mirrors CI)
devtools::check()

# Run all tests
devtools::test()

# Run a single test file
testthat::test_file("tests/testthat/test-helpers.R")

# Load package for interactive development
devtools::load_all()

# Launch the Shiny app
devtools::load_all(); VisXplore(mtcars)
```

## Architecture

All source is in `R/`:

### S3 Class System
- **`visx_cor.R`** — `visx_cor` S3 class returned by `pairwise_cor()`. Methods: `print()`, `summary()` (wraps `corstars()`), `plot()` (wraps `npc_mixed_cor()`), `as.data.frame()`
- **`data_check.R`** — `visx_check` S3 class returned by `data_check()`. Has `print()` method and internal `format_check_html()` for Shiny rendering

### Core Statistical Engine
- **`dissimilarity.R`** — `pair_cor()` computes association between two variables (Spearman, PseudoR2, GK gamma depending on types); `pairwise_cor()` builds the full pairwise association matrix and returns a `visx_cor` object
- **`helpers.R`** — `corstars()` for formatted correlation matrix with significance stars; `get_r2()` for R-squared/pseudo-R-squared per variable
- **`npc_mixed_cor.R`** — Network plot visualization using MDS coordinates from the dissimilarity matrix, with dual color scales

### Data Transformation Helpers
- **`transforms.R`** — Standalone functions: `visx_transform()`, `visx_ratio()`, `visx_mean_vars()`, `visx_collapse_levels()`

### Shiny App
- **`launch_VisXplore.R`** — `VisXplore()` entry point (plus deprecated `VisX()` alias)
- **`ui_VisX.R`** — UI definition with tabs: Network Plot, Numeric/Categorical variables, Correlation matrix, Statistics, Data, Notes
- **`server_VisXplore.R`** — Server logic using the standalone functions above
- **`figure_functions.R`** — Internal `make_hist()` and `make_bar()` for distribution plots

## Key Design Decisions

- **S3 classes over plain lists**: `pairwise_cor()` returns `visx_cor` objects. These are still lists under the hood (backward-compatible with `result$cor_value`), but with `print`/`summary`/`plot` methods for a code-forward workflow.
- **Mixed-type association**: Numeric-numeric uses Spearman, factor-involved uses PseudoR2 via multinomial regression, ordinal uses GK gamma. Logic lives in `dissimilarity.R`.
- **Dual color scales**: The network plot uses `ggnewscale::new_scale_color()` to show directional (Spearman/GKgamma with sign) and non-directional (PseudoR) correlations on the same plot.
- **MDS layout**: Network plot positions computed via `cmdscale()` on `1 - |correlation|` dissimilarity, with fallback perturbation if result is < 2 dimensions.
- **Depends on `nnet`**: Uses `Depends: nnet` (not Imports) because `multinom()` is called in formulas throughout `dissimilarity.R` and `helpers.R`.

## CI

GitHub Actions runs `R-CMD-check` on push/PR to master across macOS, Windows, and Ubuntu (R release, devel, oldrel-1).

## Exported API

**Core**: `pairwise_cor()`, `npc_mixed_cor()`, `corstars()`, `get_r2()`, `data_check()`, `VisXplore()`
**S3 methods**: `print/summary/plot/as.data.frame.visx_cor`, `print.visx_check`
**Transforms**: `visx_transform()`, `visx_ratio()`, `visx_mean_vars()`, `visx_collapse_levels()`
**Deprecated**: `VisX()` (use `VisXplore()` instead)
