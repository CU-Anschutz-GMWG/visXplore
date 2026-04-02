
#### UI functions #####

test_that("UI function", {
  skip_if_not_installed("golem")
  skip_if_not_installed("DT")
  golem::expect_shinytaglist(ui())
})

#### app launch ####
#
# testthat::test_that(
#   "app launches",{
#     x <- process$new(
#       "R",
#       c(
#         "-e",
#         "VisXplore::VisXplore()"
#       )
#     )
#     Sys.sleep(5)
#     expect_true(x$is_alive())
#     x$kill()
#   }
# )
