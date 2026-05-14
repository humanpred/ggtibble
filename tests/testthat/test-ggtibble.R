test_that("ggtibble", {
  # Test length 1
  v1 <- ggtibble(data.frame(A = 1, B = 2))
  expect_named(v1, expected = c("data_plot", "figure", "caption"))
  expect_length(v1$figure, 1)
  expect_equal(v1$data_plot[[1]], tibble::tibble(A = 1, B = 2))
  expect_equal(v1$caption, "")

  # Test length >1
  v2 <- ggtibble(data.frame(A = 1:2, B = 3:4), outercols = "A", labs = list(x = "{A}"))
  expect_named(v2, expected = c("A", "data_plot", "figure", "caption"))
  expect_length(v2$figure, 2)
  expect_equal(
    v2$data_plot,
    list(
      tibble::tibble(B = 3),
      tibble::tibble(B = 4)
    )
  )
  expect_equal(v2$caption, rep("", 2))

  # Test captioning
  v3 <- ggtibble(data.frame(A = 1:2, B = 3:4), outercols = "A", caption = "A is {A}")
  expect_named(v3, expected = c("A", "data_plot", "figure", "caption"))
  expect_length(v3$figure, 2)
  expect_equal(
    v3$data_plot,
    list(
      tibble::tibble(B = 3),
      tibble::tibble(B = 4)
    )
  )
  expect_equal(v3$caption, paste("A is", 1:2))

  # Test labels
  v4 <- ggtibble(data.frame(A = 1:2, B = 3:4), outercols = "A", labs = list(x = "A is {A}"))
  expect_named(v4, expected = c("A", "data_plot", "figure", "caption"))
  expect_length(v4$figure, 2)
  expect_equal(
    v4$data_plot,
    list(
      tibble::tibble(B = 3),
      tibble::tibble(B = 4)
    )
  )
  expect_named(v4$figure[[1]]$labels, "x")
  expect_equal(
    v4$figure[[1]]$labels$x,
    "A is 1"
  )
  expect_equal(
    v4$figure[[2]]$labels$x,
    "A is 2"
  )
  expect_equal(v4$caption, rep("", 2))

  # Test math
  expect_error(
    v4 - ggplot2::geom_point(),
    regexp = "- is not defined for ggtibble objects",
    fixed = TRUE
  )
  expect_error(
    +v4,
    regexp = "Unary operations are not defined for ggtibble objects",
    fixed = TRUE
  )
  v5 <-
    ggtibble(
      data.frame(A = 1:2, B = 3:4),
      ggplot2::aes(x = B, y = B),
      outercols = "A",
      labs = list(x = "A is {A}")
    ) +
    ggplot2::geom_point()
  expect_equal(nrow(v5), 2)
  expect_equal(v4$figure[[1]]$layers, list())
  expect_s3_class(v5$figure[[1]]$layers[[1]]$geom, "GeomPoint")

  # NULL labels work (#6)
  v6 <-
    ggtibble(
      data.frame(A = 1:2, B = 3:4),
      ggplot2::aes(x = B, y = B),
      outercols = "A",
      labs = list(x = "A is {A}", y = NULL)
    ) +
    ggplot2::geom_point()
  expect_equal(
    v6$figure[[1]]$labels$x,
    "A is 1"
  )
  expect_equal(
    v6$figure[[1]]$labels$y,
    character(0)
  )
})

test_that("knit_print.ggtibble", {
  d_plot <-
    data.frame(
      A = rep(c("foo", "bar"), each = 4),
      B = 1:8,
      C = 11:18,
      Bunit = "mg",
      Cunit = "km"
    )
  all_plots <-
    ggtibble(
      d_plot,
      ggplot2::aes(x = B, y = C),
      outercols = c("A", "Bunit", "Cunit"),
      caption = "All the {A}",
      labs = list(x = "B ({Bunit})", y = "C ({Cunit})")
    ) +
    ggplot2::geom_point() +
    ggplot2::geom_line()

  expect_error(
    knit_print(all_plots, filename = file.path(tempdir(), "foo.png")),
    regexp = "`filename` must be NULL, the same length as `x`, or an sprintf format"
  )

  # Write manually-named files
  output_file <- file.path(tempdir(), paste0("test_knit_print_", c("a", "b"), ".png"))
  # Ensure that the files do not exist before the test
  found_files <- list.files(path = tempdir(), pattern = "^test_knit_print_[ab]\\.png$", full.names = TRUE)
  if (length(found_files) > 0) {
    unlink(found_files)
  }
  # Write the output, find the files, ensure that the files are remvoed after
  # testing, and test that they exist
  knit_print(all_plots, filename = output_file)
  found_files <- list.files(path = tempdir(), pattern = "^test_knit_print_[ab]\\.png$", full.names = TRUE)
  withr::defer(unlink(found_files))
  expect_equal(file.exists(found_files), rep(TRUE, 2))

  # Write files with a pattern
  output_file <- file.path(tempdir(), "test_knit_print_%d.png")
  # Ensure that the files do not exist before the test
  found_files <- list.files(path = tempdir(), pattern = "^test_knit_print_[0-9]+\\.png$", full.names = TRUE)
  if (length(found_files) > 0) {
    unlink(found_files)
  }
  # Write the output, find the files, ensure that the files are remvoed after
  # testing, and test that they exist
  knit_print(all_plots, filename = output_file)
  found_files <- list.files(path = tempdir(), pattern = "^test_knit_print_[0-9]+\\.png$", full.names = TRUE)
  withr::defer(unlink(found_files))
  expect_equal(file.exists(found_files), rep(TRUE, 2))

  withr::deferred_clear()
})

test_that("labels are not always the same (#3)", {
  d_plot <-
    data.frame(
      A = c("A", "B"),
      B = c("C", "D"),
      x = 1,
      y = 1
    )

  p <-
    ggtibble(d_plot, ggplot2::aes(x = x, y = y), outercols = c("A", "B"), labs = list(x = "{A} {B}")) +
    ggplot2::geom_point()

  fig1 <- p$figure[[1]]
  fig2 <- p$figure[[2]]

  expect_true(fig1$labels$x != fig2$labels$x)
})

test_that("new_ggtibble() works", {
  expect_s3_class(
    new_ggtibble(tibble::tibble(figure = list(ggplot2::ggplot()), caption = "")),
    "ggtibble"
  )
})

test_that("Check that all `outercols` are used either in the `caption` or the `labs` (#13)", {
  d_plot <-
    data.frame(
      A = c("A", "B"),
      B = c("C", "D"),
      x = 1,
      y = 1
    )
  expect_silent(
    ggtibble(d_plot, ggplot2::aes(x = x, y = y), outercols = c("A", "B"), labs = list(x = "{A} {B}"))
  )
  expect_warning(
    ggtibble(d_plot, ggplot2::aes(x = x, y = y), outercols = c("A", "B"), labs = list(x = "{A}")),
    regexp = "The following `outercols` are not used in `caption` or `labs`: `B`",
    fixed = TRUE
  )
})

test_that("%+% works (#16)", {
  d_plot <-
    data.frame(
      A = rep(c("foo", "bar"), each = 4),
      B = 1:8,
      C = 11:18,
      Bunit = "mg",
      Cunit = "km"
    )
  all_plots <-
    ggtibble(
      d_plot,
      ggplot2::aes(x = B, y = C),
      outercols = c("A", "Bunit", "Cunit"),
      caption = "All the {A}",
      labs = list(x = "B ({Bunit})", y = "C ({Cunit})")
    ) +
    ggplot2::geom_point() +
    ggplot2::geom_line()
  expect_s3_class(all_plots %+% ggplot2::aes(y = B), "ggtibble")
})
