# as_ggtibble ####

test_that("as_ggtibble.gglist uses element names as captions", {
  g <- new_gglist(stats::setNames(
    list(
      ggplot2::ggplot(environment = emptyenv()),
      ggplot2::ggplot(environment = emptyenv())
    ),
    c("weight", "horsepower")
  ))
  gt <- as_ggtibble(g)
  expect_s3_class(gt, "ggtibble")
  expect_s3_class(gt$figure, "gglist")
  expect_equal(nrow(gt), 2)
  expect_equal(as.character(gt$caption), c("weight", "horsepower"))
})

test_that("as_ggtibble.gglist flattens nesting and composes captions", {
  inner <- new_gglist(stats::setNames(
    list(
      ggplot2::ggplot(environment = emptyenv()),
      ggplot2::ggplot(environment = emptyenv())
    ),
    c("dv_pred_ipred_linear", "dv_pred_ipred_log")
  ))
  outer <- new_gglist(stats::setNames(
    list(ggplot2::ggplot(environment = emptyenv()), inner),
    c("traceplot", "All Data")
  ))
  gt <- as_ggtibble(outer)
  expect_s3_class(gt, "ggtibble")
  expect_equal(nrow(gt), 3)
  expect_equal(
    as.character(gt$caption),
    c("traceplot", "All Data dv_pred_ipred_linear", "All Data dv_pred_ipred_log")
  )
  # every row's figure is a single ggplot
  expect_true(all(vapply(gt$figure, ggplot2::is_ggplot, logical(1))))
})

test_that("as_ggtibble.ggtibble is an identity", {
  d_plot <- data.frame(A = 1:2, B = 3:4, C = 5:6)
  gt <- ggtibble(d_plot, ggplot2::aes(x = B, y = C), outercols = "A", caption = "{A}")
  expect_identical(as_ggtibble(gt), gt)
})

test_that("as_ggtibble handles an empty gglist", {
  gt <- as_ggtibble(new_gglist(list()))
  expect_s3_class(gt, "ggtibble")
  expect_equal(nrow(gt), 0)
})

test_that("as_ggtibble errors on unsupported classes", {
  expect_error(as_ggtibble(1), regexp = "No `as_ggtibble\\(\\)` method")
})
