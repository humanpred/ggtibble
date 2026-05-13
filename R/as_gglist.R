#' Convert an object to a `gglist`, expanding any paginated facets
#'
#' Returns a `gglist` where every element is exactly one renderable page.
#' For inputs that use `ggforce::facet_wrap_paginate()` or
#' `ggforce::facet_grid_paginate()`, each page is expanded into its own
#' element of the result.  Inputs that do not use paginated facets are
#' wrapped (or returned) as a `gglist` unchanged in length, making the
#' function idempotent for non-paginated input.
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
  expanded <- unlist(
    lapply(seq_along(x), function(i) gg_to_pages(x[[i]])),
    recursive = FALSE
  )
  new_gglist(expanded)
}
