#' Convert an object to a `gglist`
#'
#' Promotes an input value to a `gglist`.  When the input includes a `gg`
#' object that uses `ggforce::facet_wrap_paginate()` or
#' `ggforce::facet_grid_paginate()`, the paginated plot is expanded into one
#' `gglist` element per rendered page.  All page-counting logic lives here;
#' the render methods call `as_gglist()` rather than handling pagination
#' directly.
#'
#' For an input that is already a `gglist`, the value is returned unchanged
#' so the method is a no-op when nothing needs to be coerced or expanded.
#' Re-applying `as_gglist()` to a `gglist` is therefore always safe and
#' idempotent.
#'
#' @param x A `gg`, `gglist`, list of `gg` objects, `NULL`, or `labels`
#'   object to convert.
#' @param ... Not used.
#' @return A `gglist` object.
#' @examples
#' p <- ggplot2::ggplot(mtcars, ggplot2::aes(mpg, wt)) + ggplot2::geom_point()
#' as_gglist(p)
#' @export
as_gglist <- function(x, ...) {
  if (is.null(x)) return(new_gglist(list(NULL)))
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
  new_gglist(gg_to_pages(x))
}

#' @export
as_gglist.list <- function(x, ...) {
  expanded <- unlist(
    lapply(x, function(el) {
      if (inherits(el, "gg")) gg_to_pages(el) else list(el)
    }),
    recursive = FALSE
  )
  new_gglist(expanded)
}

#' @export
as_gglist.gglist <- function(x, ...) {
  x
}

#' @export
as_gglist.labels <- function(x, ...) {
  new_gglist(list(x))
}
