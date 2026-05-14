#' Convert an object to a `gglist`
#'
#' Promotes an input value to a `gglist`.  This is a pure type coercion
#' generic: a single `gg` becomes a length-1 `gglist`, a list of plots
#' becomes a `gglist` wrapping that list, and an input that is already a
#' `gglist` is returned unchanged.
#'
#' Page expansion for `ggforce::facet_wrap_paginate()` /
#' `ggforce::facet_grid_paginate()` is handled at render time by
#' [print.gglist()], [knit_print.gglist()], and [ggsave.gglist()] — it is
#' not the job of `as_gglist()`.  Keeping the two concerns separate makes
#' `as_gglist()` idempotent and preserves the logical length of a gglist
#' (so `vec_arith.gglist.*` length-matching keeps working).
#'
#' @param x A `gg`, `gglist`, or list of `gg` objects to convert.
#' @param ... Not used.
#' @return A `gglist` object.
#' @examples
#' p <- ggplot2::ggplot(mtcars, ggplot2::aes(mpg, wt)) + ggplot2::geom_point()
#' as_gglist(p)
#' @export
as_gglist <- function(x, ...) {
  UseMethod("as_gglist")
}

#' @export
as_gglist.default <- function(x, ...) {
  rlang::abort(
    paste0("No `as_gglist()` method for class <", class(x)[1], ">")
  )
}

#' @export
as_gglist.gg <- function(x, ...) {
  new_gglist(list(x))
}

#' @export
as_gglist.list <- function(x, ...) {
  new_gglist(x)
}

#' @export
as_gglist.gglist <- function(x, ...) {
  x
}
