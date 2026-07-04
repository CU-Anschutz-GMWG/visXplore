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

# Regenerate README.md after editing README.Rmd (never edit README.md directly)
devtools::build_readme()
```

## Architecture

All source is in `R/`:

### S3 Class System
- **`visx_cor.R`** — `visx_cor` S3 class returned by `pairwise_cor()`. Methods: `print()`, `summary()` (wraps `corstars()`), `plot()` (wraps `npc_mixed_cor()`), `as.data.frame()`
- **`coradar.R`** — `visx_coradar` S3 class returned by `coradar()`: correlation-based radar plots where axis angles come from the association structure (force-directed layout in `coradar_pos()`). Methods: `print()`, `plot()` (archetype polygons + variability bands, `individuals` and `highlight` overlays)
- **`data_check.R`** — `visx_check` S3 class returned by `data_check()`. Has `print()` method and internal `format_check_html()` for Shiny rendering

### Core Statistical Engine
- **`dissimilarity.R`** — `pair_cor()` computes association between two variables (Spearman, PseudoR2, GK gamma depending on types); `pairwise_cor()` builds the full pairwise association matrix and returns a `visx_cor` object
- **`helpers.R`** — `corstars()` for formatted correlation matrix with significance stars; `get_r2()` for R-squared/pseudo-R-squared per variable
- **`npc_mixed_cor.R`** — Network plot visualization using MDS coordinates from the dissimilarity matrix, with dual color scales
- **`globals.R`** — `utils::globalVariables()` declarations for NSE, plus internal `nagelkerke_r2()` (see Key Design Decisions)

### Data
- **`R/data.R`** documents the bundled `hers` dataset (`data/hers.rda`); regenerate it with `data-raw/hers.R` (reads the gitignored `archive/coradar/hers_data.rds`). Both `archive/` and `data-raw/` are in `.Rbuildignore`.

### Shiny App
- **`launch_VisXplore.R`** — `VisXplore()` entry point (plus deprecated `VisX()` alias)
- **`ui_VisX.R`** — UI definition with tabs: Network Plot, Numeric/Categorical variables, Co-radar plot, Correlation matrix, Statistics, Data, Code, Note
- **`server_VisXplore.R`** — Server logic using the standalone functions above. Applies transformations inline and accumulates a reproducible pipeline shown in the Code tab as portable `dplyr::mutate()` calls (no package-specific wrappers; the old `visx_transform()`-style helpers were removed in 2.1.0)
- **`figure_functions.R`** — Internal `make_hist()` and `make_bar()` for distribution plots

## Key Design Decisions

- **S3 classes over plain lists**: `pairwise_cor()` returns `visx_cor` objects. These are still lists under the hood (backward-compatible with `result$cor_value`), but with `print`/`summary`/`plot` methods for a code-forward workflow.
- **Mixed-type association**: Numeric-numeric uses Spearman, factor-involved uses PseudoR2 via multinomial regression, ordinal uses GK gamma. Logic lives in `dissimilarity.R`.
- **Preprocessing is the user's job**: Users preprocess with `dplyr::mutate()` before calling `pairwise_cor()`. The Shiny app's Code tab generates the equivalent `dplyr` code so interactive sessions stay reproducible.
- **Dual color scales**: The network plot uses `ggnewscale::new_scale_color()` to show directional (Spearman/GKgamma with sign) and non-directional (PseudoR) correlations on the same plot.
- **MDS layout**: Network plot positions computed via `cmdscale()` on `1 - |correlation|` dissimilarity, with fallback perturbation if result is < 2 dimensions.
- **Co-radar axis layout**: `coradar_pos()` targets angular separation `(1 - |r|) * pi` per pair, anneals a vectorized force simulation from two starts (equidistant and MDS-derived angles), polishes with coordinate descent, keeps the lower-stress solution, then enforces a minimum axis separation. Grant context and the original prototype live in `archive/coradar/`.
- **`nnet` in Imports, not Depends**: Pseudo-R-squared is computed by the internal `nagelkerke_r2()` in `globals.R` rather than `DescTools::PseudoR2`, because DescTools re-evaluates the model call and fails when `multinom()` is not on the search path. Keep using `nnet::multinom()` (namespaced) and `nagelkerke_r2()`.

## Testing

Tests live in `tests/testthat/`, one file per source file plus:
- **`test-shiny.R`** — `shiny::testServer()` tests for reactive server logic (transformations, code recipe, variable filtering, significance), plus a `shinytest2` integration smoke test (skipped when `shinytest2` is not installed)
- **`test-app_VisXplore.R`** — UI structure test via `golem::expect_shinytaglist()` (skipped when `golem` is not installed)

## CI

GitHub Actions runs `R-CMD-check` on push/PR to master across macOS, Windows, and Ubuntu (R release, devel, oldrel-1). A separate `pkgdown` workflow builds the documentation site (config in `_pkgdown.yml`, published from `docs/`).

## Exported API

**Core**: `pairwise_cor()`, `npc_mixed_cor()`, `coradar()`, `coradar_pos()`, `corstars()`, `get_r2()`, `data_check()`, `VisXplore()`
**S3 methods**: `print/summary/plot/as.data.frame.visx_cor`, `print/plot.visx_coradar`, `print.visx_check`
**Deprecated**: `VisX()` (use `VisXplore()` instead)
