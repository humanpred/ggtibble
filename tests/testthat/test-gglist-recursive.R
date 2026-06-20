# Recursive (nested) and named gglist behavior ####

test_that("new_gglist accepts a nested gglist element", {
  inner <- new_gglist(list(ggplot2::ggplot(environment = emptyenv())))
  outer <- new_gglist(list(ggplot2::ggplot(environment = emptyenv()), inner))
  expect_s3_class(outer, "gglist")
  expect_length(outer, 2)
  expect_s3_class(outer[[2]], "gglist")
})

test_that("gglist preserves element names through construction and subsetting", {
  g <- new_gglist(stats::setNames(
    list(
      ggplot2::ggplot(environment = emptyenv()),
      ggplot2::ggplot(environment = emptyenv())
    ),
    c("a", "b")
  ))
  expect_named(g, c("a", "b"))
  expect_s3_class(g[["a"]], "gg")
  expect_named(g["b"], "b")
})

test_that("gglist preserves names through the `+` broadcast", {
  g <- new_gglist(stats::setNames(
    list(
      ggplot2::ggplot(environment = emptyenv()),
      ggplot2::ggplot(environment = emptyenv())
    ),
    c("a", "b")
  ))
  g2 <- g + ggplot2::geom_point()
  expect_named(g2, c("a", "b"))
  expect_s3_class(g2[["a"]]$layers[[1]]$geom, "GeomPoint")
})

test_that("`+` broadcast recurses into nested gglists", {
  inner <- new_gglist(stats::setNames(
    list(ggplot2::ggplot(environment = emptyenv())), "leaf"
  ))
  outer <- new_gglist(stats::setNames(
    list(ggplot2::ggplot(environment = emptyenv()), inner),
    c("top", "group")
  ))
  added <- outer + ggplot2::geom_point()
  expect_named(added, c("top", "group"))
  # top-level plain ggplot got the geom
  expect_s3_class(added[["top"]]$layers[[1]]$geom, "GeomPoint")
  # nested gglist stayed a gglist and its leaf also got the geom
  expect_s3_class(added[["group"]], "gglist")
  expect_named(added[["group"]], "leaf")
  expect_s3_class(added[["group"]][["leaf"]]$layers[[1]]$geom, "GeomPoint")
})

test_that("`+` broadcast is NULL-safe (NULL elements stay NULL)", {
  g <- new_gglist(stats::setNames(
    list(ggplot2::ggplot(environment = emptyenv()), NULL),
    c("a", "b")
  ))
  g2 <- g + ggplot2::geom_point()
  expect_named(g2, c("a", "b"))
  expect_s3_class(g2[["a"]]$layers[[1]]$geom, "GeomPoint")
  expect_null(g2[["b"]])
})

test_that("format.gglist summarizes nested and NULL elements", {
  inner <- new_gglist(list(
    ggplot2::ggplot(environment = emptyenv()),
    ggplot2::ggplot(environment = emptyenv())
  ))
  g <- new_gglist(list(ggplot2::ggplot(environment = emptyenv()), inner, NULL))
  expect_equal(format(g), c("A ggplot object", "A gglist (2)", "NULL"))
})

# plot methods ####

test_that("plot.NULL renders nothing", {
  expect_invisible(plot(NULL))
  expect_null(plot(NULL))
})

test_that("plot.gglist renders flat, nested, and NULL elements without error", {
  inner <- new_gglist(list(ggplot2::ggplot(environment = emptyenv())))
  g <- new_gglist(list(ggplot2::ggplot(environment = emptyenv()), inner, NULL))
  pdf(NULL)
  on.exit(grDevices::dev.off(), add = TRUE)
  expect_invisible(plot(g))
})
