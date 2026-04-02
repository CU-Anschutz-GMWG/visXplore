##### testServer tests: reactive logic #####

# Small test data with mixed types
mixed_df <- data.frame(
  x = rnorm(50),
  y = rnorm(50),
  g = sample(c("a", "b", "c"), 50, TRUE),
  stringsAsFactors = FALSE
)
mixed_types <- c("numeric", "numeric", "factor")

test_that("server initializes reactive data correctly", {
  server <- server_VisXplore(mtcars)
  testServer(server, {
    expect_equal(ncol(df_lst$df_all), ncol(mtcars))
    expect_equal(nrow(df_lst$df_all), nrow(mtcars))
    expect_length(df_lst$var_type, ncol(mtcars))
    expect_null(df_lst$df_new_num)
    expect_null(df_lst$df_new_cat)
  })
})

test_that("code recipe starts empty", {
  server <- server_VisXplore(mtcars)
  testServer(server, {
    recipe <- output$code_recipe
    expect_true(grepl("your_data", recipe))
    expect_true(grepl("pairwise_cor", recipe))
    expect_false(grepl("visx_transform", recipe))
  })
})

test_that("univariate transform updates data and code recipe", {
  server <- server_VisXplore(mtcars)
  testServer(server, {
    session$setInputs(vars_dist = c("mpg", "hp"), typetrans = "log")
    session$setInputs(newtrans = 1)

    # data should gain 2 new columns
    expect_equal(ncol(df_lst$df_all), ncol(mtcars) + 2)
    expect_true("mpg_log" %in% colnames(df_lst$df_all))
    expect_true("hp_log" %in% colnames(df_lst$df_all))

    # var_type extended
    expect_length(df_lst$var_type, ncol(mtcars) + 2)

    # code recipe should include dplyr::mutate with across
    recipe <- output$code_recipe
    expect_true(grepl("dplyr::mutate", recipe))
    expect_true(grepl("dplyr::across", recipe))
    expect_true(grepl("log", recipe))
    expect_true(grepl("mpg", recipe))
  })
})

test_that("sqrt transform works", {
  server <- server_VisXplore(mtcars)
  testServer(server, {
    session$setInputs(vars_dist = "hp", typetrans = "sqrt")
    session$setInputs(newtrans = 1)

    expect_true("hp_sqrt" %in% colnames(df_lst$df_all))
    recipe <- output$code_recipe
    expect_true(grepl("sqrt", recipe))
  })
})

test_that("ratio transform updates data and code recipe", {
  server <- server_VisXplore(mtcars)
  testServer(server, {
    session$setInputs(
      vars_dist = c("mpg", "hp"),
      typeop = "Ratio (alphabetical)",
      newvarname = "mpg_per_hp"
    )
    session$setInputs(newop = 1)

    expect_true("mpg_per_hp" %in% colnames(df_lst$df_all))
    recipe <- output$code_recipe
    expect_true(grepl("dplyr::mutate", recipe))
    expect_true(grepl("mpg_per_hp", recipe))
    expect_true(grepl("mpg / hp", recipe))
  })
})

test_that("reverse ratio transform works", {
  server <- server_VisXplore(mtcars)
  testServer(server, {
    session$setInputs(
      vars_dist = c("mpg", "hp"),
      typeop = "Ratio (reverse alphabetical)",
      newvarname = "hp_per_mpg"
    )
    session$setInputs(newop = 1)

    expect_true("hp_per_mpg" %in% colnames(df_lst$df_all))
    recipe <- output$code_recipe
    expect_true(grepl("dplyr::mutate", recipe))
    expect_true(grepl("hp / mpg", recipe))
  })
})

test_that("mean transform updates data and code recipe", {
  server <- server_VisXplore(mtcars)
  testServer(server, {
    session$setInputs(
      vars_dist = c("mpg", "hp"),
      typeop = "Mean",
      newvarname = "mean_mpg_hp"
    )
    session$setInputs(newop = 1)

    expect_true("mean_mpg_hp" %in% colnames(df_lst$df_all))
    recipe <- output$code_recipe
    expect_true(grepl("dplyr::mutate", recipe))
    expect_true(grepl("rowMeans", recipe))
    expect_true(grepl("mean_mpg_hp", recipe))
  })
})

test_that("collapse levels updates data and code recipe", {
  server <- server_VisXplore(mixed_df)
  testServer(server, {
    session$setInputs(
      vars_bin = "g",
      lev = c("a", "b"),
      newcat = "ab",
      binned_type = "factor"
    )
    session$setInputs(cattrans = 1)

    expect_true("g_bin" %in% colnames(df_lst$df_all))
    collapsed <- df_lst$df_all$g_bin
    expect_true(all(collapsed[mixed_df$g %in% c("a", "b")] == "ab"))
    expect_true(all(collapsed[mixed_df$g == "c"] == "c"))

    recipe <- output$code_recipe
    expect_true(grepl("dplyr::mutate", recipe))
    expect_true(grepl("ifelse", recipe))
    expect_true(grepl('"ab"', recipe))
  })
})

test_that("multiple transforms chain in code recipe", {
  server <- server_VisXplore(mtcars)
  testServer(server, {
    # first transform
    session$setInputs(vars_dist = "hp", typetrans = "log")
    session$setInputs(newtrans = 1)

    # second transform
    session$setInputs(
      vars_dist = c("mpg", "hp"),
      typeop = "Ratio (alphabetical)",
      newvarname = "mpg_per_hp"
    )
    session$setInputs(newop = 1)

    recipe <- output$code_recipe
    # should have pipe operators connecting steps
    expect_true(grepl("\\|>", recipe))
    expect_true(grepl("dplyr::across", recipe))
    expect_true(grepl("dplyr::mutate.*\\bmpg\\b.*\\bhp\\b", recipe))
  })
})

test_that("network plot filters by selected variables", {
  server <- server_VisXplore(mtcars[, 1:4])
  testServer(server, {
    # select only 2 of 4 variables
    session$setInputs(
      vars_cor = c("mpg", "cyl"),
      signif = "none",
      min_cor = 0.3
    )
    # output$npc is a plot, just check it doesn't error
    expect_no_error(output$npc)
  })
})

test_that("significance radio buttons accept numeric thresholds", {
  server <- server_VisXplore(mtcars[, 1:4])
  testServer(server, {
    session$setInputs(
      vars_cor = colnames(mtcars[, 1:4]),
      signif = "0.05",
      min_cor = 0.3
    )
    expect_no_error(output$npc)
  })
})

test_that("statistics tab filters by selected variables", {
  server <- server_VisXplore(mtcars[, 1:4])
  testServer(server, {
    # use only 3 of 4 variables
    session$setInputs(vars_stat = c("mpg", "cyl", "disp"))
    result <- output$stat
    # should contain HTML table output
    expect_true(grepl("table", result, ignore.case = TRUE))
    # hp should not appear
    expect_false(grepl("\\bhp\\b", result))
  })
})

test_that("data check output renders", {
  server <- server_VisXplore(mtcars)
  testServer(server, {
    result <- output$datacheck
    expect_true(is.character(result))
  })
})

test_that("VisXplore requires data argument", {
  expect_error(VisXplore(), "Please provide a data.frame")
})


##### shinytest2 integration test #####

test_that("app launches and renders without error", {
  skip_if_not_installed("shinytest2")
  skip_on_cran()
  skip_on_ci()

  # Write a temporary app.R using ::: to access internal functions
  app_dir <- withr::local_tempdir()
  writeLines(c(
    'library(VisXplore)',
    'shinyApp(ui = VisXplore:::ui, server = VisXplore:::server_VisXplore(mtcars[, 1:5]))'
  ), file.path(app_dir, "app.R"))

  app <- shinytest2::AppDriver$new(
    app_dir = app_dir,
    name = "visxplore-smoke",
    timeout = 20000,
    wait = TRUE
  )
  on.exit(app$stop(), add = TRUE)

  # app should be running

  vals <- app$get_values()
  expect_true("tabs1" %in% names(vals$input))

  # network plot tab should be active by default
  expect_equal(vals$input$tabs1, "Network Plot of Correlation and Association")
})
