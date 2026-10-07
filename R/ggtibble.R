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
#' @return A data.frame with a column named "data_plot" with the data to plot,
#'   "figure" with the gglist, "caption" with the captions, "footnote" with the
#'   footnotes, and "label" with the figure labels
#' @export
ggtibble <- function(data, ...) {
  UseMethod("ggtibble")
}

#' @describeIn ggtibble The default method for a data.frame or tibble
#' @inheritParams ggplot2::ggplot
#' @param outercols The columns to have outside the nesting
#' @param caption The glue specification for creating the caption
#' @param footnote The glue specification for creating the footnote, a note
#'   rendered under each figure and kept with it (see "Footnotes and labels" in
#'   [knit_print.gglist()]).  The default `""` gives no footnote.
#' @param label The glue specification for creating each figure's label, its
#'   identifier for cross-references and the base name of its image file.
#'   Labels must be unique and may contain only letters, digits, hyphens,
#'   underscores, and dots.  Under Quarto, start them with `fig-` so that
#'   `@fig-...` cross-references resolve.  The default `""` gives no label.
#' @param labs Labels to add via `labs_glue()`
#' @returns A `ggtibble` object which is a tibble with columns named "figure"
#'   which is a `gglist` object (a list of ggplots), "data_plot" which is the a
#'   list of data.frames making up the source data used for each individual
#'   plot, "caption" which is the text to use for the plot caption, "footnote"
#'   which is the text to show under the plot, "label" which is the plot's
#'   identifier, and all of the `outercols` used for nesting.
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
ggtibble.data.frame <- function(data, mapping = ggplot2::aes(), ..., outercols = group_vars(data), labs = list(), caption = "", footnote = "", label = "") {
  if (!tibble::is_tibble(data)) {
    data <- tibble::as_tibble(as.data.frame(data))
  }
  d_plot <- tidyr::nest(.data = data, data_plot = !tidyr::all_of(outercols))
  d_plot$figure <- gglist(data = d_plot$data_plot, mapping = mapping, ...)

  # Check that all `outercols` are used in an argument that will be glued
  glued_expr <-
    unlist(lapply(
      X = append(labs, list(caption, footnote, label)), FUN = extract_glue_expr
    ))
  unused_outercols <- unique(setdiff(outercols, glued_expr))
  if (length(unused_outercols) > 0) {
    warning(
      "The following `outercols` are not used in `caption`, `footnote`, `label`, or `labs`: ",
      paste0("`", unused_outercols, "`", collapse = ", ")
    )
  }

  d_plot$caption <- glue::glue_data(d_plot, caption)
  d_plot$footnote <- glue::glue_data(d_plot, footnote)
  d_plot$label <- glue::glue_data(d_plot, label)
  d_plot <- new_ggtibble(d_plot)
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
#'   the "figure" column is a ggtibble.  The "footnote" and "label" columns are
#'   added as empty strings when absent.  Non-empty labels must be unique and
#'   may contain only letters, digits, hyphens, underscores, and dots.
#' @returns The object with a ggtibble class
#' @family New ggtibble objects
#' @examples
#' new_ggtibble(tibble::tibble(figure = list(ggplot2::ggplot()), caption = ""))
#' @export
new_ggtibble <- function(x) {
  stopifnot(is.data.frame(x))
  stopifnot(c("figure", "caption") %in% names(x))
  if (!inherits(x$figure, "gglist")) {
    x$figure <- new_gglist(x$figure)
  }
  for (nm in setdiff(c("footnote", "label"), names(x))) {
    x[[nm]] <- rep("", nrow(x))
  }
  validate_ggtibble_labels(x$label)
  class(x) <- unique(c("ggtibble", class(x)))
  x
}

#' Get a text column of a ggtibble, reading `NA` and a missing column as empty
#'
#' A ggtibble made before the "footnote" and "label" columns existed (for
#' example, one read back from a cache) lacks them, which reads as all empty.
#'
#' @param x A ggtibble
#' @param name The column name
#' @returns A character vector with one element per row of `x`
#' @noRd
ggtibble_text_column <- function(x, name) {
  if (!(name %in% names(x))) {
    return(rep("", nrow(x)))
  }
  ret <- as.character(x[[name]])
  ret[is.na(ret)] <- ""
  ret
}

#' Check figure labels for identifier syntax and uniqueness
#'
#' Empty and `NA` labels mean "no label" and are not checked.
#'
#' @param label A character vector of labels
#' @returns `label`, invisibly; an error of class
#'   `ggtibble_error_label_invalid` or `ggtibble_error_label_duplicated`
#'   otherwise
#' @noRd
validate_ggtibble_labels <- function(label) {
  label <- as.character(label)
  given <- label[!is.na(label) & nzchar(label)]
  invalid <- unique(given[!grepl("^[A-Za-z0-9_.-]+$", given)])
  if (length(invalid) > 0) {
    rlang::abort(
      paste0(
        "Each `label` may contain only letters, digits, hyphens, underscores, and dots; invalid: ",
        paste0("`", invalid, "`", collapse = ", ")
      ),
      class = "ggtibble_error_label_invalid"
    )
  }
  duplicated_labels <- unique(given[duplicated(given)])
  if (length(duplicated_labels) > 0) {
    rlang::abort(
      paste0(
        "Each `label` must be unique; duplicated: ",
        paste0("`", duplicated_labels, "`", collapse = ", ")
      ),
      class = "ggtibble_error_label_duplicated"
    )
  }
  invisible(label)
}

#' @describeIn knit_print.gglist Print the plots in a `ggtibble` object
#' @export
knit_print.ggtibble <- function(x, ...) {
  knit_print(x$figure, ...)
}

#' @describeIn plot.gglist Plot the figures in a `ggtibble` object
#' @export
plot.ggtibble <- function(x, y, ...) {
  plot(x$figure, ...)
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
