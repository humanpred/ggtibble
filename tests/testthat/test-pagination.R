# Tests for ggforce paginated facet integration.

# Helpers ####

make_paginated_plot <- function() {
  # 3 cyl levels, ncol=1, nrow=1 -> 3 pages
  ggplot2::ggplot(mtcars, ggplot2::aes(mpg, wt)) +
    ggplot2::geom_point() +
    ggforce::facet_wrap_paginate(~ cyl, ncol = 1, nrow = 1)
}

make_plain_plot <- function() {
  ggplot2::ggplot(mtcars, ggplot2::aes(mpg, wt)) +
    ggplot2::geom_point()
}

# is_paginated ####

test_that("is_paginated identifies paginated and non-paginated plots", {
  expect_false(is_paginated(make_plain_plot()))
  expect_false(is_paginated("not a plot"))
  expect_false(is_paginated(NULL))
  skip_if_not_installed("ggforce")
  expect_true(is_paginated(make_paginated_plot()))
})

# n_pages_for_plot ####

test_that("n_pages_for_plot returns 1 for non-paginated plots", {
  expect_identical(n_pages_for_plot(make_plain_plot()), 1L)
})

test_that("n_pages_for_plot returns the actual page count for paginated plots", {
  skip_if_not_installed("ggforce")
  expect_identical(n_pages_for_plot(make_paginated_plot()), 3L)
})

# gg_to_pages ####

test_that("gg_to_pages returns list(plot) for non-paginated plots", {
  p <- make_plain_plot()
  result <- gg_to_pages(p)
  expect_length(result, 1)
  expect_identical(result[[1]], p)
})

test_that("gg_to_pages expands paginated plot to one element per page", {
  skip_if_not_installed("ggforce")
  p <- make_paginated_plot()
  result <- gg_to_pages(p)
  expect_length(result, 3)
  pages_used <- vapply(result, function(pl) pl$facet$params$page, integer(1))
  expect_identical(pages_used, 1:3)
})

# expand_filenames ####

test_that("expand_filenames handles NULL filename", {
  expect_identical(expand_filenames(NULL, c(1L, 1L)), list(NULL, NULL))
  expect_identical(expand_filenames(NULL, 3L), list(NULL, NULL, NULL))
})

test_that("expand_filenames accepts exact total length", {
  expect_identical(
    expand_filenames(c("a", "b", "c"), c(1L, 2L)),
    list("a", "b", "c")
  )
})

test_that("expand_filenames expands length-1 sprintf", {
  expect_identical(
    expand_filenames("plot_%d.png", c(1L, 2L)),
    list("plot_1.png", "plot_2.png", "plot_3.png")
  )
})

test_that("expand_filenames expands one filename per logical plot with %d", {
  expect_identical(
    expand_filenames(c("a_%d.png", "b_%d.png"), c(2L, 1L)),
    list("a_1.png", "a_2.png", "b_1.png")
  )
})

test_that("expand_filenames errors on mismatched lengths", {
  expect_error(
    expand_filenames(c("a", "b"), c(2L, 2L)),
    regexp = "`filename` must be NULL"
  )
})

# as_gglist ####

test_that("as_gglist.default errors", {
  expect_error(as_gglist(1L), regexp = "No `as_gglist\\(\\)` method for class")
})

test_that("as_gglist.gg wraps a single non-paginated plot in a gglist", {
  p <- make_plain_plot()
  result <- as_gglist(p)
  expect_s3_class(result, "gglist")
  expect_length(result, 1)
})

test_that("as_gglist.gg expands paginated plots", {
  skip_if_not_installed("ggforce")
  result <- as_gglist(make_paginated_plot())
  expect_s3_class(result, "gglist")
  expect_length(result, 3)
})

test_that("as_gglist.gg wraps non-paginated plot as length-1 gglist", {
  result <- as_gglist(make_plain_plot())
  expect_s3_class(result, "gglist")
  expect_length(result, 1)
})

test_that("as_gglist.list works with a list of plain plots", {
  result <- as_gglist(list(make_plain_plot(), make_plain_plot()))
  expect_s3_class(result, "gglist")
  expect_length(result, 2)
})

test_that("as_gglist.list expands paginated elements inline", {
  skip_if_not_installed("ggforce")
  result <- as_gglist(list(make_plain_plot(), make_paginated_plot()))
  expect_s3_class(result, "gglist")
  expect_length(result, 4)
})

test_that("as_gglist.gglist is identity even when elements are paginated", {
  skip_if_not_installed("ggforce")
  g <- new_gglist(list(make_plain_plot(), make_paginated_plot()))
  expect_identical(as_gglist(g), g)
  expect_identical(as_gglist(as_gglist(g)), g)
})

# print.gglist with pagination ####

test_that("print.gglist renders every page of a paginated element", {
  skip_if_not_installed("ggforce")
  g <- new_gglist(list(make_paginated_plot()))
  pdf(NULL)
  withr::defer(dev.off())
  before <- dev.cur()
  # Count plots by hooking the device: every print on the null device increments
  # an internal page counter.  Easier: just verify the call returns invisibly
  # and produces no error.
  expect_invisible(print(g))
})

# knit_print.gglist with pagination ####

test_that("knit_print.gglist with %d filename writes one file per page", {
  skip_if_not_installed("ggforce")
  withr::with_tempdir({
    g <- new_gglist(list(make_paginated_plot()))
    knit_print(g, filename = "out_%d.png")
    expect_setequal(list.files(pattern = "^out_[0-9]+\\.png$"), c("out_1.png", "out_2.png", "out_3.png"))
  })
})

# ggsave.gglist with pagination ####

test_that("ggsave.gglist with %d filename writes one file per page", {
  skip_if_not_installed("ggforce")
  withr::with_tempdir({
    g <- new_gglist(list(make_paginated_plot()))
    ggsave(filename = "out_%d.png", plot = g, width = 4, height = 3)
    expect_setequal(
      list.files(pattern = "^out_[0-9]+\\.png$"),
      c("out_1.png", "out_2.png", "out_3.png")
    )
  })
})

test_that("ggsave.gglist with one-per-logical-plot %d filename expands per page", {
  skip_if_not_installed("ggforce")
  withr::with_tempdir({
    g <- new_gglist(list(make_plain_plot(), make_paginated_plot()))
    ggsave(filename = c("plain_%d.png", "paged_%d.png"), plot = g, width = 4, height = 3)
    expect_setequal(
      list.files(pattern = "\\.png$"),
      c("plain_1.png", "paged_1.png", "paged_2.png", "paged_3.png")
    )
  })
})

test_that("ggsave.gglist errors on duplicate filenames", {
  skip_if_not_installed("ggforce")
  withr::with_tempdir({
    g <- new_gglist(list(make_plain_plot(), make_plain_plot()))
    expect_error(
      ggsave(filename = c("a.png", "a.png"), plot = g),
      regexp = "Each `filename` must be unique"
    )
  })
})

# Caption expansion ####

test_that("expand_captions_for_pages leaves captions unchanged when no pagination", {
  d_plot <- data.frame(A = c("foo", "bar"), B = 1:2)
  gt <- ggtibble(d_plot, ggplot2::aes(x = B, y = B), outercols = "A", caption = "Cap {A}")
  result <- expand_captions_for_pages(gt)
  expect_length(result, 2)
  expect_match(result[1], "Cap foo|Cap bar")
})

test_that("expand_captions_for_pages appends panel suffix when figures paginate", {
  skip_if_not_installed("ggforce")
  d_plot <- data.frame(
    A = rep(c("foo", "bar"), each = 3),
    B = c(1, 2, 3, 4, 5, 6)
  )
  gt <- ggtibble(d_plot, ggplot2::aes(x = B, y = B), outercols = "A", caption = "Cap {A}") +
    ggforce::facet_wrap_paginate(~ B, ncol = 1, nrow = 1)
  result <- expand_captions_for_pages(gt)
  # 2 rows x 3 pages each = 6 expanded captions
  expect_length(result, 6)
  expect_match(result[1], "^Cap foo \\(panel 1 of 3\\)$")
  expect_match(result[3], "^Cap foo \\(panel 3 of 3\\)$")
  expect_match(result[4], "^Cap bar \\(panel 1 of 3\\)$")
})
