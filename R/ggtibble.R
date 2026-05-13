#' @importFrom dplyr group_vars
#' @export
dplyr::group_vars

#' @importFrom ggplot2 ggplot
#' @export
ggplot2::ggplot

#' Make a tibble where one column is the data to plot, one is the gglist, and
#' one is the caption
#'
#' @param data The data.frame to plot
#' @param ... Passed to subsequent methods (usually passed to `gglist()`)
#' @return A data.frame with a column named "data_plot" with the data to plot, "figure" with the gglist, and "caption" with the captions
#' @export
ggtibble <- function(data, ...) {
  UseMethod("ggtibble")
}

#' @describeIn ggtibble The default method for a data.frame or tibble
#' @inheritParams ggplot2::ggplot
#' @param outercols The columns to have outside the nesting
#' @param caption The glue specification for creating the caption
#' @param labs Labels to add via `labs_glue()`
#' @param panel_caption A glue template appended to each caption when a row's
#'   figure renders as multiple pages (e.g. via
#'   `ggforce::facet_wrap_paginate()`).  Available glue variables are `page`
#'   (the current page number, 1-indexed) and `n_pages` (the total page count
#'   for that row).  Set to `NULL` or `""` to opt out and let the caption
#'   repeat unchanged for every page.
#' @returns A `ggtibble` object which is a tibble with columns named "figure"
#'   which is a `gglist` object (a list of ggplots), "data_plot" which is the a
#'   list of data.frames making up the source data used for each individual
#'   plot, "caption" which is the text to use for the plot caption, and all of
#'   the `outercols` used for nesting.
#' @examples
#' d_plot <-
#'   data.frame(
#'     A = rep(c("foo", "bar"), each = 4),
#'     B = 1:8,
#'     C = 11:18,
#'     Bunit = "mg",
#'     Cunit = "km"
#'   )
#' all_plots <-
#'   ggtibble(
#'     d_plot,
#'     ggplot2::aes(x = B, y = C),
#'     outercols = c("A", "Bunit", "Cunit"),
#'     caption = "All the {A}",
#'     labs = list(x = "B ({Bunit})", y = "C ({Cunit})")
#'   ) +
#'   ggplot2::geom_point() +
#'   ggplot2::geom_line()
#' knit_print(all_plots)
#' @export
ggtibble.data.frame <- function(data, mapping = ggplot2::aes(), ...,
                                outercols = group_vars(data), labs = list(),
                                caption = "",
                                panel_caption = " (panel {page} of {n_pages})") {
  if (!tibble::is_tibble(data)) {
    data <- tibble::as_tibble(as.data.frame(data))
  }
  d_plot <- tidyr::nest(.data = data, data_plot = !tidyr::all_of(outercols))
  d_plot$figure <- gglist(data = d_plot$data_plot, mapping = mapping, ...)

  # Check that all `outercols` are used either in the `caption` or the `labs`
  # Extract all expressions used in arguments that will be glued
  glued_expr <-
    unlist(lapply(
      X = append(labs, list(caption)), FUN = extract_glue_expr
    ))
  unused_outercols <- unique(setdiff(outercols, glued_expr))
  if (length(unused_outercols) > 0) {
    warning(
      "The following `outercols` are not used in `caption` or `labs`: ",
      paste0("`", unused_outercols, "`", collapse = ", ")
    )
  }

  d_plot$caption <- glue::glue_data(d_plot, caption)
  d_plot <- new_ggtibble(d_plot, panel_caption = panel_caption)
  if (length(labs) > 0) {
    d_plot$figure <-
      d_plot$figure +
      # Convert to a gglist so that the values will be added element-wise
      new_gglist(do.call(
        what = labs_glue, append(list(p = d_plot), labs)
      ))
  }
  d_plot
}

#' Create a new `ggtibble` object
#'
#' @param x A data.frame with a column named "figure" and "caption", and where
#'   the "figure" column is a ggtibble.
#' @param panel_caption A glue template appended to each caption when a row's
#'   figure renders as multiple pages.  See [ggtibble()] for details.  If
#'   omitted, any existing `panel_caption` attribute on `x` is preserved (and
#'   defaulted otherwise).
#' @returns The object with a ggtibble class
#' @family New ggtibble objects
#' @examples
#' new_ggtibble(tibble::tibble(figure = list(ggplot2::ggplot()), caption = ""))
#' @export
new_ggtibble <- function(x, panel_caption) {
  stopifnot(is.data.frame(x))
  stopifnot(c("figure", "caption") %in% names(x))
  if (!inherits(x$figure, "gglist")) {
    x$figure <- new_gglist(x$figure)
  }
  if (missing(panel_caption)) {
    panel_caption <- attr(x, "panel_caption", exact = TRUE)
    if (is.null(panel_caption)) {
      panel_caption <- " (panel {page} of {n_pages})"
    }
  }
  attr(x, "panel_caption") <- panel_caption
  class(x) <- unique(c("ggtibble", class(x)))
  x
}

#' @describeIn knit_print.gglist Print the plots in a `ggtibble` object
#' @export
knit_print.ggtibble <- function(x, ...) {
  knit_print(x$figure, ...)
}

#' @export
chooseOpsMethod.ggtibble <- function(x, y, mx, my, cl, reverse) {
  # Always use the ggtibble method (which will usually then pass to the gglist
  # method for the "figure" column)
  TRUE
}

#' @export
Ops.ggtibble <- function(e1, e2) {
  if (nargs() == 1) {
    stop("Unary operations are not defined for ggtibble objects")
  }
  if (.Generic == "+") {
    # Add the gglist object to something else (usually a ggplot2-style object)
    e1$figure <- e1$figure + e2
  } else {
    stop(.Generic, " is not defined for ggtibble objects")
  }
  e1
}
