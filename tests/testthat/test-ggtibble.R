test_that("ggtibble", {
  # Test length 1
  v1 <- ggtibble(data.frame(A = 1, B = 2))
  expect_named(v1, expected = c("data_plot", "figure", "caption", "footnote", "label"))
  expect_length(v1$figure, 1)
  expect_equal(v1$data_plot[[1]], tibble::tibble(A = 1, B = 2))
  expect_equal(v1$caption, "")

  # Test length >1
  v2 <- ggtibble(data.frame(A = 1:2, B = 3:4), outercols = "A", labs = list(x = "{A}"))
  expect_named(v2, expected = c("A", "data_plot", "figure", "caption", "footnote", "label"))
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
  expect_named(v3, expected = c("A", "data_plot", "figure", "caption", "footnote", "label"))
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
  expect_named(v4, expected = c("A", "data_plot", "figure", "caption", "footnote", "label"))
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
    regexp = "The following `outercols` are not used in `caption`, `footnote`, `label`, or `labs`: `B`",
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

# footnote and label columns ####

test_that("footnote and label columns are built from glue specifications per row", {
  v <- ggtibble(
    data.frame(A = c("x", "y"), B = 3:4),
    outercols = "A",
    caption = "Cap {A}",
    footnote = "Note on {A}",
    label = "fig-{A}"
  )
  expect_equal(as.character(v$caption), c("Cap x", "Cap y"))
  expect_equal(as.character(v$footnote), c("Note on x", "Note on y"))
  expect_equal(as.character(v$label), c("fig-x", "fig-y"))
})

test_that("footnote and label default to empty strings", {
  v <- ggtibble(data.frame(A = 1:2, B = 3:4), outercols = "A", caption = "{A}")
  expect_equal(as.character(v$footnote), c("", ""))
  expect_equal(as.character(v$label), c("", ""))
})

test_that("an outercol used only in `footnote` or `label` does not warn", {
  d_plot <- data.frame(A = 1:2, B = c("u", "v"), x = 1)
  expect_silent(
    ggtibble(d_plot, outercols = c("A", "B"), caption = "{A}", footnote = "{B}")
  )
  expect_silent(
    ggtibble(d_plot, outercols = c("A", "B"), caption = "{A}", label = "lab-{B}")
  )
})

test_that("duplicated labels are refused with the duplicates named", {
  expect_error(
    ggtibble(data.frame(A = 1:3, B = c("a", "a", "b")), outercols = c("A", "B"), caption = "{A}", label = "{B}"),
    regexp = "Each `label` must be unique, ignoring case; duplicated: `a`",
    fixed = TRUE,
    class = "ggtibble_error_label_duplicated"
  )
})

test_that("labels with characters outside letters, digits, hyphens, underscores, and dots are refused", {
  expect_error(
    ggtibble(data.frame(A = c("a b", "c:d", "ok_1.x-y")), outercols = "A", label = "{A}"),
    regexp = "Each `label` may contain only letters, digits, hyphens, underscores, and dots; invalid: `a b`, `c:d`",
    fixed = TRUE,
    class = "ggtibble_error_label_invalid"
  )
})

test_that("validate_ggtibble_labels ignores empty and NA labels", {
  expect_identical(validate_ggtibble_labels(c("", NA, "", "a")), c("", NA, "", "a"))
  expect_identical(validate_ggtibble_labels(character()), character())
})

test_that("new_ggtibble adds empty footnote and label columns and validates labels", {
  v <- new_ggtibble(tibble::tibble(figure = list(ggplot2::ggplot(), ggplot2::ggplot()), caption = c("a", "b")))
  expect_named(v, c("figure", "caption", "footnote", "label"))
  expect_equal(v$footnote, c("", ""))
  expect_equal(v$label, c("", ""))
  expect_error(
    new_ggtibble(tibble::tibble(figure = list(ggplot2::ggplot()), caption = "a", label = "a/b")),
    class = "ggtibble_error_label_invalid"
  )
})

test_that("ggtibble_text_column reads a missing column and NA as empty", {
  x <- tibble::tibble(caption = c("a", NA))
  expect_equal(ggtibble_text_column(x, "caption"), c("a", ""))
  expect_equal(ggtibble_text_column(x, "footnote"), c("", ""))
})

test_that("labels that differ only by case are duplicates, since they name the same file on Windows and macOS", {
  expect_error(
    ggtibble(data.frame(A = c("A", "a", "c")), outercols = "A", label = "{A}"),
    regexp = "Each `label` must be unique, ignoring case; duplicated: `A`, `a`",
    fixed = TRUE,
    class = "ggtibble_error_label_duplicated"
  )
})
