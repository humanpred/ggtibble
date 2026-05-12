# gglist creation ####

test_that("gglist", {
  expect_length(
    gglist(list(data.frame(A = 1), data.frame(B = 2))),
    2
  )
})

# gglist math ####

test_that("vec_arith for gglists", {
  g1 <- new_gglist(list(ggplot2::ggplot(environment = emptyenv())))
  # add a single item to a single gglist
  expect_s3_class(
    g1 + ggplot2::geom_point(),
    "gglist"
  )
  # add a single item to a single gglist
  expect_s3_class(
    g1 + ggplot2::labs(x = "foo"),
    "gglist"
  )
  # add a guides object to a single gglist
  expect_s3_class(
    g1 + ggplot2::guides(colour = ggplot2::guide_legend(ncol = 1)),
    "gglist"
  )
  # add an aes object to a single gglist
  expect_s3_class(
    g1 + ggplot2::aes(x = 1),
    "gglist"
  )
  # add a data.frame to a single gglist
  expect_s3_class(
    g1 + data.frame(A = 1),
    "gglist"
  )
  # add a list of items to a single gglist
  expect_s3_class(
    g1 + list(ggplot2::labs(x = "foo")),
    "gglist"
  )
  expect_s3_class(
    g1 +
      list(
        ggplot2::geom_point(),
        ggplot2::labs(x = "foo")
      ),
    "gglist"
  )
  # List addition occurs per gglist element not per list element (like adding a
  # list to a ggplot2 object)
  expect_length(
    g1 +
      list(
        ggplot2::geom_point(),
        ggplot2::labs(x = "foo")
      ),
    1
  )
  # Add two gglists together ####
  g1 <- new_gglist(list(ggplot2::ggplot(environment = emptyenv())))
  g2 <- new_gglist(list(ggplot2::ggplot(environment = emptyenv())))
  expect_error(g1 + g2) # Can't add two ggplots to each other
  # Can add one element to one element
  g1 <- new_gglist(list(ggplot2::ggplot(environment = emptyenv())))
  g2 <- new_gglist(list(ggplot2::geom_point()))
  expect_length(g1 + g2, 1)
  # Can't add two elements to one element
  g1 <- new_gglist(list(ggplot2::ggplot(environment = emptyenv())))
  g2 <- new_gglist(list(ggplot2::geom_point(), ggplot2::geom_line()))
  expect_error(g1 + g2)
  # Can add two element to two elements
  g1 <- new_gglist(list(ggplot2::ggplot(environment = emptyenv()), ggplot2::ggplot(environment = emptyenv())))
  g2 <- new_gglist(list(ggplot2::geom_point(), ggplot2::geom_line()))
  added <- g1 + g2
  expect_length(added, 2)
  expect_s3_class(added[[1]]$layers[[1]]$geom, "GeomPoint")
  expect_s3_class(added[[2]]$layers[[1]]$geom, "GeomLine")
  # Can add one element to two elements
  g1 <- new_gglist(list(ggplot2::ggplot(environment = emptyenv()), ggplot2::ggplot(environment = emptyenv())))
  g2 <- new_gglist(list(ggplot2::geom_point()))
  expect_length(g1 + g2, 2)
})

test_that("ggbreak arithmetic", {
  skip_if_not_installed("ggbreak")
  g1 <- new_gglist(list(ggplot2::ggplot(environment = emptyenv())))
  # add a single item to a single gglist
  expect_s3_class(
    g1 + ggbreak::scale_x_break(c(1, 2)),
    "gglist"
  )
})

# new_gglist ####

test_that("new_gglist accepted input classes", {
  expect_s3_class(
    new_gglist(list(ggplot2::labs(x = "foo"))),
    "gglist"
  )
  expect_s3_class(
    new_gglist(list(ggplot2::ggplot())),
    "gglist"
  )
  expect_s3_class(
    new_gglist(list(NULL)),
    "gglist"
  )
})

test_that("new_gglist errors", {
  expect_error(new_gglist("A"), regexp = "`x` must be a list")
  expect_error(
    new_gglist(list("A")),
    regexp = "the contents of 'x' must be NULL, a 'gg' (ggplot), or a 'labels' object",
    fixed = TRUE
  )
})

# knit_print.gg ####

test_that("knit_print.gg", {
  p <- ggplot2::ggplot()
  expect_output(knit_print(p), "\n\n\n")
  expect_output(knit_print(p, fig_prefix = "prefix"), "prefix")
  expect_output(knit_print(p, fig_suffix = "suffix"), "suffix")
})

# Trivial tests for 100% coverage ####

test_that("gglist trivial", {
  p <- gglist(list(data.frame(A = 1), data.frame(A = 2)))
  expect_equal(vec_ptype_abbr.gglist(p), "gglst")
  expect_equal(format(p), rep("A ggplot object", 2))
  expect_invisible(print(p))
})
