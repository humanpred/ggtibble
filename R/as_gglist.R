#' Convert an object to a `gglist`
#'
#' Promotes an input value to a `gglist`.  When the input includes a `gg`
#' object that uses `ggforce::facet_wrap_paginate()` or
#' `ggforce::facet_grid_paginate()`, the paginated plot is expanded into one
#' `gglist` element per rendered page so subsequent calls to `print()`,
#' `knit_print()`, or `ggsave()` render every page.  Inputs that already
#' use a non-paginated facet (or no facet at all) pass through unchanged.
#'
#' For an input that is already a `gglist`, the value is returned unchanged
#' so the method is a no-op when nothing needs to be coerced.  Call this
#' yourself before rendering when you want paginated facets expanded — the
#' render methods do not call it implicitly because page expansion is not
#' always desired.
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

#' @method as_gglist NULL
#' @export
`as_gglist.NULL` <- function(x, ...) {
  new_gglist(list(NULL))
}
