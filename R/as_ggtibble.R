#' Convert an object to a `ggtibble`
#'
#' Converts a named (and possibly nested) [gglist()] into a [ggtibble()] whose
#' `caption` column is built from the element names.  This is the bridge that
#' lets a collection of figures built up as a `gglist` flow into the reporting
#' helpers ([knit_print.ggtibble()], [ggsave.ggtibble()]).
#'
#' When the `gglist` is nested (an element is itself a `gglist`), the result is
#' flattened to a single `ggtibble` with one row per leaf figure and the outer
#' element name prepended to each inner name.  For example, a top-level element
#' named `"All Data"` whose value is a `gglist` containing a figure named
#' `"dv_pred_ipred_linear"` produces a caption of
#' `"All Data dv_pred_ipred_linear"`.
#'
#' @param x The object to convert (currently a `gglist`).
#' @param ... Passed to methods.
#' @return A `ggtibble` object with `figure` and `caption` columns.
#' @examples
#' g <-
#'   new_gglist(stats::setNames(
#'     list(
#'       ggplot2::ggplot(mtcars, ggplot2::aes(mpg, wt)) + ggplot2::geom_point(),
#'       ggplot2::ggplot(mtcars, ggplot2::aes(mpg, hp)) + ggplot2::geom_point()
#'     ),
#'     c("weight", "horsepower")
#'   ))
#' as_ggtibble(g)
#' @export
as_ggtibble <- function(x, ...) {
  UseMethod("as_ggtibble")
}

#' @export
as_ggtibble.default <- function(x, ...) {
  rlang::abort(
    paste0("No `as_ggtibble()` method for class <", class(x)[1], ">")
  )
}

#' @export
as_ggtibble.ggtibble <- function(x, ...) {
  x
}

#' @describeIn as_ggtibble Convert a (possibly nested) `gglist` to a `ggtibble`,
#'   using element names as captions
#' @param caption_prefix Text prepended (separated by a space) to the name of
#'   each element when building captions.  Defaults to `NULL` (no prefix), and
#'   is set automatically to the outer caption when recursing into a nested
#'   `gglist`.
#' @export
as_ggtibble.gglist <- function(x, ..., caption_prefix = NULL) {
  if (length(x) == 0) {
    return(new_ggtibble(tibble::tibble(
      figure = new_gglist(list()), caption = character()
    )))
  }
  nms <- names(x)
  if (is.null(nms)) {
    nms <- rep("", length(x))
  }
  pieces <-
    lapply(
      X = seq_along(x),
      FUN = function(i) {
        nm <- nms[[i]]
        caption <-
          if (is.null(caption_prefix)) {
            nm
          } else {
            paste(caption_prefix, nm)
          }
        el <- x[[i]]
        if (inherits(el, "gglist")) {
          # Recurse, carrying the current caption inward as the prefix
          as_ggtibble(el, caption_prefix = caption)
        } else {
          new_ggtibble(tibble::tibble(
            figure = new_gglist(list(el)), caption = caption
          ))
        }
      }
    )
  new_ggtibble(vctrs::vec_rbind(!!!pieces))
}
