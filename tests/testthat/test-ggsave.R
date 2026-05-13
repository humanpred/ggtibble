test_that("ggsave", {
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
  expected_files <- file.path(tempdir(), c("foo.png", "bar.png"))
  expect_equal(
    ggsave(filename = "{A}.png", plot = all_plots, path = tempdir()),
    expected_files
  )
  unlink(expected_files)

  # Enough filenames must be given
  expect_error(
    ggsave(filename = "a.png", plot = all_plots$figure, path = tempdir()),
    regexp = "`filename` must be NULL"
  )
  # Filenames must be unique (don't accidentally overwrite anything)
  expect_error(
    ggsave(filename = "{Bunit}.png", plot = all_plots, path = tempdir()),
    regexp = "Each `filename` must be unique",
    fixed = TRUE
  )
})

test_that("ggsave with all filenames specified (#25)", {
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
  expected_files <- file.path(tempdir(), c("foo.png", "bar.png"))
  expect_equal(
    ggsave(filename = c("foo.png", "bar.png"), plot = all_plots, path = tempdir()),
    expected_files
  )
  unlink(expected_files)

  expect_error(
    ggsave(filename = c("foo.png", "bar.png", "baz.png"), plot = all_plots, path = tempdir()),
    regexp = "Assertion on 'filename' failed: Must have length <= 2, but has length 3.",
    fixed = TRUE
  )
  expect_error(
    ggsave(filename = character(), plot = all_plots, path = tempdir()),
    regexp = "Assertion on 'filename' failed: Must have length >= 1, but has length 0.",
    fixed = TRUE
  )
})

test_that("ggsave.default", {
  d_plot <-
    data.frame(
      A = rep(c("foo", "bar"), each = 4),
      B = 1:8,
      C = 11:18,
      Bunit = "mg",
      Cunit = "km"
    )
  current_plots <-
    ggplot2::ggplot(
      d_plot,
      ggplot2::aes(x = B, y = C)
    ) +
    ggplot2::geom_point() +
    ggplot2::geom_line()
  expected_file <- file.path(tempdir(), "foo.png")
  expect_equal(
    ggsave(filename = "foo.png", plot = current_plots, path = tempdir()),
    expected_file
  )
  unlink(expected_file)
})
