# Figures with footnotes or labels are written as markdown by ggtibble itself
# rather than through knitr's plot hook: the hook cannot give each figure of a
# chunk its own identifier, nor put text between a figure and the next one
# inside one float or unbreakable block.

#' Does a ggtibble carry a footnote or a label on any row?
#'
#' @param x A ggtibble
#' @returns `TRUE` or `FALSE`
#' @noRd
has_figure_annotations <- function(x) {
  any(nzchar(ggtibble_text_column(x, "footnote"))) ||
    any(nzchar(ggtibble_text_column(x, "label")))
}

#' Print a ggtibble whose figures have footnotes or labels
#'
#' Within knitr, each figure is saved under the chunk's `fig.path` and written
#' as markdown for the output format (see "Footnotes and labels" in
#' [knit_print.gglist()]), so the chunk must have `results = "asis"`.  Outside
#' knitr, each figure is printed and its footnote written after it.
#'
#' @inheritParams knit_print.gglist
#' @inheritParams knit_print.gg
#' @returns `x`, invisibly
#' @noRd
knit_print_annotated <- function(x, ..., filename = NULL, fig_suffix = NULL, float_barrier_after = 10,
                                 width = 6, height = 4, units = "in") {
  n <- nrow(x)
  fig_suffix <- resolve_fig_suffix(fig_suffix, n = n, float_barrier_after = float_barrier_after)
  filename <- resolve_knit_filenames(filename, n = n)
  caption <- ggtibble_text_column(x, "caption")
  footnote <- ggtibble_text_column(x, "footnote")
  label <- validate_ggtibble_labels(ggtibble_text_column(x, "label"))
  in_knitr <- isTRUE(getOption("knitr.in.progress"))
  if (in_knitr) {
    options <- knitr::opts_current$get()
    if (!identical(options$results, "asis")) {
      rlang::abort(
        paste(
          "A `ggtibble` with footnotes or labels is written as markdown,",
          "so its chunk needs `results = \"asis\"` (the `ggtibble` chunk option sets it)."
        ),
        class = "ggtibble_error_results_not_asis"
      )
    }
    engine <- figure_output_engine()
    quarto <- is_quarto_render()
    device <- figure_device(options$dev)
    id <- figure_ids(label, chunk_label = options$label, quarto = quarto)
  }
  for (idx in seq_len(n)) {
    plot <- x$figure[[idx]]
    if (is.null(plot)) next
    if (!inherits(plot, "gg")) {
      rlang::abort(
        "Each figure of a `ggtibble` with footnotes or labels must be a single ggplot",
        class = "ggtibble_error_figure_not_gg"
      )
    }
    if (!is.null(filename)) {
      ggplot2::ggsave(filename = filename[[idx]], plot = plot, width = width, height = height, units = units)
    }
    if (in_knitr) {
      path <- figure_image_path(label[idx], number = idx, ext = device$ext, options = options)
      dir.create(dirname(path), recursive = TRUE, showWarnings = FALSE)
      ggplot2::ggsave(
        filename = path, plot = plot, device = device$device,
        width = options$fig.width, height = options$fig.height, units = "in", dpi = options$dpi
      )
      cat(
        figure_markdown(
          engine = engine, path = path, caption = caption[idx], footnote = footnote[idx],
          id = id[idx], quarto = quarto, fig_pos = options$fig.pos
        ),
        fig_suffix,
        sep = ""
      )
    } else {
      print(plot)
      if (nzchar(footnote[idx])) {
        cat("\n\n", footnote[idx], "\n\n", sep = "")
      }
    }
  }
  invisible(x)
}

#' Which kind of figure markup the document being knitted needs
#'
#' @returns One of `"latex"` (LaTeX through pandoc), `"rnw"` (LaTeX without
#'   pandoc, as from an Rnw file), `"typst"`, `"html"`, `"pandoc"` (any other
#'   pandoc format, such as docx), or `"markdown"` (knitr markdown with no
#'   pandoc target)
#' @noRd
figure_output_engine <- function() {
  to <- knitr::pandoc_to()
  if (knitr::is_latex_output()) {
    if (is.null(to)) "rnw" else "latex"
  } else if (is.null(to)) {
    "markdown"
  } else if (identical(to, "typst")) {
    "typst"
  } else if (knitr::is_html_output(excludes = c("markdown", "gfm"))) {
    "html"
  } else {
    "pandoc"
  }
}

#' The ggsave() device and file extension for a knitr `dev` chunk option
#'
#' @param dev The `dev` chunk option; only its first element is used
#' @returns A list with `device` (for [ggplot2::ggsave()]; `NULL` lets the
#'   extension choose) and `ext`
#' @noRd
figure_device <- function(dev) {
  dev <- if (length(dev) == 0) "png" else dev[[1]]
  ext <- c(
    png = "png", ragg_png = "png", pdf = "pdf", cairo_pdf = "pdf", svg = "svg",
    svglite = "svg", jpeg = "jpeg", tiff = "tiff", bmp = "bmp", postscript = "eps"
  )
  if (!(dev %in% names(ext))) {
    rlang::abort(
      paste0(
        "The knitr `dev` chunk option \"", dev, "\" is not supported for a `ggtibble` with footnotes or labels; ",
        "use one of: ", paste0("\"", names(ext), "\"", collapse = ", ")
      ),
      class = "ggtibble_error_device_unsupported"
    )
  }
  device <- if (identical(dev, "cairo_pdf")) grDevices::cairo_pdf else NULL
  list(device = device, ext = ext[[dev]])
}

#' The identifier written for each figure
#'
#' A figure's label is its identifier.  Under Quarto, a figure without a label
#' is given `fig-<chunk label>` (with `-<row number>` when the ggtibble has
#' more than one row) so that it is still a numbered, cross-referenceable
#' figure; elsewhere it has no identifier.
#'
#' @param label The labels, with `""` for none
#' @param chunk_label The knitr chunk label
#' @param quarto Is this a Quarto render?
#' @returns A character vector of identifiers, `NA` for none
#' @noRd
figure_ids <- function(label, chunk_label, quarto) {
  id <- label
  missing_id <- !nzchar(id)
  if (quarto) {
    base <- paste0("fig-", sub("^fig-", "", chunk_label))
    derived <- if (length(id) == 1) base else paste0(base, "-", seq_along(id))
    id[missing_id] <- derived[missing_id]
    validate_ggtibble_labels(id)
  } else {
    id[missing_id] <- NA_character_
  }
  id
}

#' The image file path for one figure
#'
#' A labelled figure's image is named after its label; any other uses knitr's
#' usual `<fig.path><chunk label>-<number>` name.  Both go through
#' [knitr::fig_path()], which makes the name safe for LaTeX.
#'
#' @param label The figure's label, `""` for none
#' @param number The figure's row number
#' @param ext The file extension
#' @param options The knitr chunk options
#' @returns A file path
#' @noRd
figure_image_path <- function(label, number, ext, options) {
  if (nzchar(label)) {
    options$label <- label
    knitr::fig_path(ext, options = options, number = NULL)
  } else {
    knitr::fig_path(ext, options = options, number = number)
  }
}

#' Build the markdown for one figure, its caption, its footnote, and its id
#'
#' @param engine The output engine from `figure_output_engine()`
#' @param path The image path
#' @param caption,footnote The figure's caption and footnote (`""` for none);
#'   markdown in them passes through
#' @param id The figure's identifier, `NA` for none
#' @param quarto Is this a Quarto render?
#' @param fig_pos The LaTeX float placement (the knitr `fig.pos` option)
#' @returns A single string
#' @noRd
figure_markdown <- function(engine, path, caption, footnote, id, quarto, fig_pos = "") {
  quarto_figure <- quarto && !is.na(id) && startsWith(id, "fig-")
  if (engine %in% c("latex", "rnw")) {
    if (quarto_figure && engine == "latex") {
      return(figure_div_markdown(
        path = path, caption = latex_caption_markdown(caption, footnote), id = id,
        scap = if (nzchar(footnote)) latex_flatten(caption)
      ))
    }
    return(figure_latex_markdown(
      path = path, caption = caption, footnote = footnote, id = id,
      fig_pos = fig_pos, pandoc = engine == "latex"
    ))
  }
  figure <-
    if (quarto_figure) {
      figure_div_markdown(path = path, caption = caption, id = id)
    } else {
      figure_image_markdown(path = path, caption = caption, id = if (engine != "markdown") id else NA)
    }
  if (!nzchar(footnote)) {
    return(figure)
  }
  if (engine == "typst") {
    # Keep the figure and its footnote together on one page.  The footnote is
    # outside the figure Div so that Quarto still sees the Div as a figure.
    # knitr::raw_block() starts and ends its fence with a newline
    paste0(
      "\n", knitr::raw_block("#block(breakable: false)[", type = "typst"),
      figure,
      knitr::raw_block("#block(width: 100%, text(size: 0.9em)[", type = "typst"), "\n",
      footnote, "\n\n",
      knitr::raw_block("])\n]", type = "typst"), "\n"
    )
  } else if (engine == "html") {
    paste0(figure, "::: {.figure-footnote style=\"font-size: smaller;\"}\n", footnote, "\n:::\n\n")
  } else {
    paste0(figure, footnote, "\n\n")
  }
}

#' A Quarto figure Div: the image, then the caption as the Div's last paragraph
#'
#' @param scap The short caption for the LaTeX List of Figures, or `NULL`
#' @noRd
figure_div_markdown <- function(path, caption, id, scap = NULL) {
  attrs <- paste0("#", id)
  if (!is.null(scap)) {
    attrs <- paste0(attrs, " fig-scap=\"", markdown_attr_escape(scap), "\"")
  }
  paste0("\n\n::: {", attrs, "}\n![](", path, ")\n\n", caption, "\n:::\n\n")
}

#' A pandoc implicit figure: an image alone in its paragraph
#' @noRd
figure_image_markdown <- function(path, caption, id) {
  attrs <- if (is.na(id)) "" else paste0("{#", id, "}")
  paste0("\n\n![", caption, "](", path, ")", attrs, "\n\n")
}

#' A LaTeX figure float written directly
#'
#' Through pandoc, the LaTeX commands are raw inlines and blocks around the
#' caption and footnote markdown, so pandoc still converts and escapes the
#' text.  For an Rnw document (no pandoc) everything is LaTeX already.  The
#' footnote goes inside the caption, after a line break and in
#' `\footnotesize`; the plain caption is the short caption, so the List of
#' Figures carries only the caption.
#'
#' @param pandoc Is the document going through pandoc?
#' @noRd
figure_latex_markdown <- function(path, caption, footnote, id, fig_pos, pandoc) {
  caption <- latex_flatten(caption)
  footnote <- latex_flatten(footnote)
  pos <- if (length(fig_pos) == 1 && nzchar(fig_pos)) paste0("[", fig_pos, "]") else ""
  begin <- paste0("\\begin{figure}", pos, "\n\\centering")
  end <- "\\end{figure}"
  caption_tex <-
    if (nzchar(footnote)) {
      paste0(
        latex_inline("\\caption[{", pandoc), caption, latex_inline("}]{", pandoc), caption,
        latex_inline("\\\\{\\footnotesize", pandoc), " ", footnote, latex_inline("}}", pandoc)
      )
    } else {
      paste0(latex_inline("\\caption{", pandoc), caption, latex_inline("}", pandoc))
    }
  label_tex <- if (is.na(id)) "" else latex_inline(paste0("\\label{", id, "}"), pandoc)
  graphic <- latex_inline(paste0("\\includegraphics{", path, "}"), pandoc)
  if (pandoc) {
    # knitr::raw_block() starts and ends its fence with a newline
    paste0(
      "\n", knitr::raw_block(begin, type = "latex"), "\n",
      graphic, "\n\n",
      caption_tex, label_tex, "\n",
      knitr::raw_block(end, type = "latex"), "\n"
    )
  } else {
    paste0("\n\n", begin, "\n", graphic, "\n", caption_tex, label_tex, "\n", end, "\n\n")
  }
}

#' The caption paragraph of a Quarto figure Div for LaTeX: the caption, a line
#' break, and the footnote in `\footnotesize`
#' @noRd
latex_caption_markdown <- function(caption, footnote) {
  caption <- latex_flatten(caption)
  if (!nzchar(footnote)) {
    return(caption)
  }
  paste0(
    caption, latex_inline("\\\\{\\footnotesize", TRUE), " ", latex_flatten(footnote),
    latex_inline("}", TRUE)
  )
}

#' Mark a LaTeX fragment as a pandoc raw inline (unchanged without pandoc)
#' @noRd
latex_inline <- function(x, pandoc) {
  if (pandoc) paste0("`", x, "`{=latex}") else x
}

#' Join the lines of a caption or footnote, which LaTeX's `\caption` needs to be
#' a single paragraph
#' @noRd
latex_flatten <- function(x) {
  gsub("[[:space:]]*\n[[:space:]]*", " ", x)
}

#' Escape a value for a double-quoted pandoc attribute
#' @noRd
markdown_attr_escape <- function(x) {
  gsub("([\"\\\\])", "\\\\\\1", x)
}
