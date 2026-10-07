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
    regexp = "There must be one `filename` per `plot`",
    fixed = TRUE
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

test_that("ggsave.ggtibble names files from the labels when `filename` is not given", {
  labelled <-
    ggtibble(
      data.frame(A = c("foo", "bar"), B = 1:2),
      ggplot2::aes(x = B, y = B),
      outercols = "A",
      label = "fig-{A}"
    ) +
    ggplot2::geom_point()
  td <- withr::local_tempdir()
  expect_equal(
    ggsave(plot = labelled, path = td, width = 2, height = 2),
    file.path(td, c("fig-foo.png", "fig-bar.png"))
  )
  expect_equal(
    ggsave(plot = labelled, device = "pdf", path = td, width = 2, height = 2),
    file.path(td, c("fig-foo.pdf", "fig-bar.pdf"))
  )
  expect_equal(
    sort(list.files(td)),
    c("fig-bar.pdf", "fig-bar.png", "fig-foo.pdf", "fig-foo.png")
  )
  # An explicit filename still wins
  expect_equal(
    ggsave(filename = "{A}.png", plot = labelled, path = td, width = 2, height = 2),
    file.path(td, c("foo.png", "bar.png"))
  )
})

test_that("ggsave.ggtibble without `filename` needs every label and a string device", {
  partly <-
    ggtibble(data.frame(A = c("foo", "bar"), B = 1:2), outercols = "A", label = "{A}")
  partly$label[2] <- ""
  expect_error(
    ggsave(plot = partly, path = tempdir()),
    regexp = "`filename` is required unless every row of the ggtibble has a `label`",
    fixed = TRUE,
    class = "ggtibble_error_label_missing"
  )
  unlabelled <- ggtibble(data.frame(A = c("foo", "bar"), B = 1:2), outercols = "A", caption = "{A}")
  expect_error(
    ggsave(plot = unlabelled, path = tempdir()),
    class = "ggtibble_error_label_missing"
  )
  labelled <- ggtibble(data.frame(A = c("foo", "bar"), B = 1:2), outercols = "A", label = "{A}")
  expect_error(
    ggsave(plot = labelled, device = grDevices::png, path = tempdir()),
    regexp = "`filename` is required when `device` is not a string, because the file extension cannot be chosen from it",
    fixed = TRUE,
    class = "ggtibble_error_device_extension"
  )
})
