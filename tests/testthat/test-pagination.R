# Tests for as_gglist() and the ggforce paginated-facet expansion it performs.

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

# as_gglist ####

test_that("as_gglist.default errors", {
  expect_error(as_gglist(1L), regexp = "No `as_gglist\\(\\)` method for class")
})

test_that("as_gglist.NULL wraps NULL in a length-1 gglist", {
  result <- as_gglist(NULL)
  expect_s3_class(result, "gglist")
  expect_length(result, 1)
  expect_null(result[[1]])
})

test_that("as_gglist.labels wraps a labels object", {
  result <- as_gglist(ggplot2::labs(x = "foo"))
  expect_s3_class(result, "gglist")
  expect_length(result, 1)
})

test_that("as_gglist.gg wraps a non-paginated plot as a length-1 gglist", {
  result <- as_gglist(make_plain_plot())
  expect_s3_class(result, "gglist")
  expect_length(result, 1)
})

test_that("as_gglist.gg expands a paginated plot to one element per page", {
  skip_if_not_installed("ggforce")
  result <- as_gglist(make_paginated_plot())
  expect_s3_class(result, "gglist")
  expect_length(result, 3)
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

test_that("as_gglist.gglist is identity (idempotent for non-paginated)", {
  g <- new_gglist(list(make_plain_plot(), make_plain_plot()))
  expect_identical(as_gglist(g), g)
})

test_that("as_gglist.gglist is identity even when elements are paginated", {
  skip_if_not_installed("ggforce")
  g <- new_gglist(list(make_plain_plot(), make_paginated_plot()))
  expect_identical(as_gglist(g), g)
  expect_identical(as_gglist(as_gglist(g)), g)
})

# Render integration through as_gglist ####

test_that("ggsave() saves every page when the gglist is first passed through as_gglist", {
  skip_if_not_installed("ggforce")
  withr::with_tempdir({
    flat <- as_gglist(make_paginated_plot())
    ggsave(filename = c("p1.png", "p2.png", "p3.png"), plot = flat, width = 4, height = 3)
    expect_setequal(list.files(pattern = "\\.png$"), c("p1.png", "p2.png", "p3.png"))
  })
})
