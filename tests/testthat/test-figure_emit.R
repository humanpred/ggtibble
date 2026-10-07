# A two-figure ggtibble with footnotes and, optionally, labels
make_footnoted_ggtibble <- function(label = "") {
  ggtibble(
    data.frame(A = 1:2, B = 3:4),
    ggplot2::aes(x = B, y = B),
    outercols = "A",
    caption = "Cap {A}",
    footnote = "Note {A}",
    label = label
  ) +
    ggplot2::geom_point()
}

# knitr::raw_block() warns when pandoc is unavailable
skip_if_no_pandoc <- function() {
  testthat::skip_if_not_installed("rmarkdown")
  testthat::skip_if_not(rmarkdown::pandoc_available("2.0.0"), "pandoc >= 2.0.0 is not available")
}

# Set knitr package options for the rest of the calling test
local_knit_opts <- function(..., .env = parent.frame()) {
  old <- knitr::opts_knit$get(names(list(...)))
  knitr::opts_knit$set(...)
  withr::defer(knitr::opts_knit$set(old), envir = .env)
}

# has_figure_annotations ####

test_that("has_figure_annotations is TRUE only with a footnote or a label", {
  expect_false(has_figure_annotations(ggtibble(data.frame(A = 1:2), outercols = "A", caption = "{A}")))
  expect_true(has_figure_annotations(make_footnoted_ggtibble()))
  expect_true(has_figure_annotations(
    ggtibble(data.frame(A = 1:2), outercols = "A", label = "lab{A}")
  ))
  # A ggtibble lacking the columns (made before they existed) has none
  old <- structure(
    tibble::tibble(figure = new_gglist(list(ggplot2::ggplot())), caption = "c"),
    class = c("ggtibble", "tbl_df", "tbl", "data.frame")
  )
  expect_false(has_figure_annotations(old))
})

# figure_output_engine ####

test_that("figure_output_engine distinguishes the output formats", {
  local_knit_opts(out.format = "markdown", rmarkdown.pandoc.to = NULL)
  expect_equal(figure_output_engine(), "markdown")
  knitr::opts_knit$set(rmarkdown.pandoc.to = "latex")
  expect_equal(figure_output_engine(), "latex")
  knitr::opts_knit$set(rmarkdown.pandoc.to = "beamer")
  expect_equal(figure_output_engine(), "latex")
  knitr::opts_knit$set(rmarkdown.pandoc.to = "typst")
  expect_equal(figure_output_engine(), "typst")
  knitr::opts_knit$set(rmarkdown.pandoc.to = "html")
  expect_equal(figure_output_engine(), "html")
  knitr::opts_knit$set(rmarkdown.pandoc.to = "revealjs")
  expect_equal(figure_output_engine(), "html")
  knitr::opts_knit$set(rmarkdown.pandoc.to = "docx")
  expect_equal(figure_output_engine(), "pandoc")
  knitr::opts_knit$set(rmarkdown.pandoc.to = "gfm")
  expect_equal(figure_output_engine(), "pandoc")
  knitr::opts_knit$set(rmarkdown.pandoc.to = NULL, out.format = "latex")
  expect_equal(figure_output_engine(), "rnw")
})

# figure_device ####

test_that("figure_device maps knitr devices to ggsave devices and extensions", {
  expect_equal(figure_device(NULL), list(device = NULL, ext = "png"))
  expect_equal(figure_device("png"), list(device = NULL, ext = "png"))
  expect_equal(figure_device(c("pdf", "png")), list(device = NULL, ext = "pdf"))
  expect_equal(figure_device("svglite"), list(device = NULL, ext = "svg"))
  expect_equal(figure_device("postscript"), list(device = NULL, ext = "eps"))
  expect_equal(figure_device("cairo_pdf"), list(device = grDevices::cairo_pdf, ext = "pdf"))
  expect_error(
    figure_device("tikz"),
    regexp = paste0(
      "The knitr `dev` chunk option \"tikz\" is not supported for a `ggtibble` with footnotes or labels; ",
      "use one of: \"png\", \"ragg_png\", \"pdf\", \"cairo_pdf\", \"svg\", \"svglite\", \"jpeg\", \"tiff\", \"bmp\", \"postscript\""
    ),
    fixed = TRUE,
    class = "ggtibble_error_device_unsupported"
  )
})

# figure_ids ####

test_that("figure_ids uses labels, and derives fig- ids only under Quarto", {
  expect_equal(figure_ids(c("a", "b"), chunk_label = "chunk", quarto = FALSE), c("a", "b"))
  expect_equal(figure_ids(c("a", ""), chunk_label = "chunk", quarto = FALSE), c("a", NA))
  expect_equal(figure_ids(c("", ""), chunk_label = "chunk", quarto = TRUE), c("fig-chunk-1", "fig-chunk-2"))
  expect_equal(figure_ids("", chunk_label = "chunk", quarto = TRUE), "fig-chunk")
  # A chunk label that already starts with fig- is not prefixed twice
  expect_equal(figure_ids(c("fig-x", ""), chunk_label = "fig-chunk", quarto = TRUE), c("fig-x", "fig-chunk-2"))
  # A derived id may not repeat a label
  expect_error(
    figure_ids(c("fig-chunk-2", ""), chunk_label = "chunk", quarto = TRUE),
    regexp = "Each `label` must be unique; duplicated: `fig-chunk-2`",
    fixed = TRUE,
    class = "ggtibble_error_label_duplicated"
  )
})

# figure_image_path ####

test_that("figure_image_path names a labelled figure after its label", {
  options <- list(fig.path = "out/figure-html/", label = "chunk")
  local_knit_opts(out.format = "markdown")
  expect_equal(figure_image_path("lab1", number = 1, ext = "png", options = options), "out/figure-html/lab1.png")
  expect_equal(figure_image_path("", number = 2, ext = "png", options = options), "out/figure-html/chunk-2.png")
})

# figure_markdown ####

test_that("figure_markdown: knitr markdown is an image and a paragraph, without an id", {
  expect_equal(
    figure_markdown("markdown", "p.png", caption = "Cap", footnote = "Note *em*", id = "lab", quarto = FALSE),
    "\n\n![Cap](p.png)\n\nNote *em*\n\n"
  )
  expect_equal(
    figure_markdown("markdown", "p.png", caption = "Cap", footnote = "", id = NA, quarto = FALSE),
    "\n\n![Cap](p.png)\n\n"
  )
})

test_that("figure_markdown: other pandoc formats (docx) give the image an id and a plain paragraph", {
  expect_equal(
    figure_markdown("pandoc", "p.png", caption = "Cap", footnote = "Note", id = "lab", quarto = FALSE),
    "\n\n![Cap](p.png){#lab}\n\nNote\n\n"
  )
})

test_that("figure_markdown: HTML puts the footnote in a smaller figure-footnote Div", {
  expect_equal(
    figure_markdown("html", "p.png", caption = "Cap", footnote = "Note", id = "lab", quarto = FALSE),
    "\n\n![Cap](p.png){#lab}\n\n::: {.figure-footnote style=\"font-size: smaller;\"}\nNote\n:::\n\n"
  )
  expect_equal(
    figure_markdown("html", "p.png", caption = "Cap", footnote = "", id = NA, quarto = FALSE),
    "\n\n![Cap](p.png)\n\n"
  )
})

test_that("figure_markdown: Quarto writes a figure Div for a fig- id and an image otherwise", {
  expect_equal(
    figure_markdown("html", "p.png", caption = "Cap", footnote = "", id = "fig-a", quarto = TRUE),
    "\n\n::: {#fig-a}\n![](p.png)\n\nCap\n:::\n\n"
  )
  expect_equal(
    figure_markdown("html", "p.png", caption = "Cap", footnote = "", id = "a", quarto = TRUE),
    "\n\n![Cap](p.png){#a}\n\n"
  )
})

test_that("figure_markdown: Typst keeps the figure Div and footnote in one unbreakable block", {
  skip_if_no_pandoc()
  expect_equal(
    figure_markdown("typst", "p.svg", caption = "Cap", footnote = "Note *em*", id = "fig-a", quarto = TRUE),
    paste0(
      "\n\n```{=typst}\n#block(breakable: false)[\n```\n",
      "\n\n::: {#fig-a}\n![](p.svg)\n\nCap\n:::\n\n",
      "\n```{=typst}\n#block(width: 100%, text(size: 0.9em)[\n```\n\n",
      "Note *em*\n\n",
      "\n```{=typst}\n])\n]\n```\n\n"
    )
  )
  # Without a footnote there is no block
  expect_equal(
    figure_markdown("typst", "p.svg", caption = "Cap", footnote = "", id = "fig-a", quarto = TRUE),
    "\n\n::: {#fig-a}\n![](p.svg)\n\nCap\n:::\n\n"
  )
})

test_that("figure_markdown: LaTeX through pandoc writes the float with raw LaTeX around markdown", {
  skip_if_no_pandoc()
  expect_equal(
    figure_markdown("latex", "p.pdf", caption = "Cap", footnote = "Note *em*", id = "lab", quarto = FALSE, fig_pos = "H"),
    paste0(
      "\n\n```{=latex}\n\\begin{figure}[H]\n\\centering\n```\n\n",
      "`\\includegraphics{p.pdf}`{=latex}\n\n",
      "`\\caption[{`{=latex}Cap`}]{`{=latex}Cap`\\\\{\\footnotesize`{=latex} Note *em*`}}`{=latex}",
      "`\\label{lab}`{=latex}\n",
      "\n```{=latex}\n\\end{figure}\n```\n\n"
    )
  )
  # No footnote: no short caption; no id: no \label
  expect_equal(
    figure_markdown("latex", "p.pdf", caption = "Cap", footnote = "", id = NA, quarto = FALSE),
    paste0(
      "\n\n```{=latex}\n\\begin{figure}\n\\centering\n```\n\n",
      "`\\includegraphics{p.pdf}`{=latex}\n\n",
      "`\\caption{`{=latex}Cap`}`{=latex}\n",
      "\n```{=latex}\n\\end{figure}\n```\n\n"
    )
  )
})

test_that("figure_markdown: LaTeX joins multi-line captions and footnotes into one line", {
  expect_equal(
    figure_markdown("rnw", "p.pdf", caption = "Cap\nline", footnote = "Note\n\n  more", id = "lab", quarto = FALSE),
    "\n\n\\begin{figure}\n\\centering\n\\includegraphics{p.pdf}\n\\caption[{Cap line}]{Cap line\\\\{\\footnotesize Note more}}\\label{lab}\n\\end{figure}\n\n"
  )
})

test_that("figure_markdown: Quarto LaTeX appends the footnote to the Div caption with a short caption", {
  expect_equal(
    figure_markdown("latex", "p.pdf", caption = "Cap \"q\"", footnote = "Note", id = "fig-a", quarto = TRUE),
    "\n\n::: {#fig-a fig-scap=\"Cap \\\"q\\\"\"}\n![](p.pdf)\n\nCap \"q\"`\\\\{\\footnotesize`{=latex} Note`}`{=latex}\n:::\n\n"
  )
  expect_equal(
    figure_markdown("latex", "p.pdf", caption = "Cap", footnote = "", id = "fig-a", quarto = TRUE),
    "\n\n::: {#fig-a}\n![](p.pdf)\n\nCap\n:::\n\n"
  )
  # A label without fig- is not a Quarto figure, so the float is written directly
  expect_match(
    figure_markdown("latex", "p.pdf", caption = "Cap", footnote = "", id = "a", quarto = TRUE),
    "\\label{a}",
    fixed = TRUE
  )
})

# knit_print outside and inside knitr ####

test_that("knit_print outside knitr prints each figure and writes its footnote", {
  p <- make_footnoted_ggtibble()
  pdf(NULL)
  withr::defer(grDevices::dev.off())
  expect_equal(
    utils::capture.output(knit_print(p)),
    c("", "", "Note 1", "", "", "", "Note 2", "")
  )
})

test_that("knit_print outside knitr also saves to `filename`", {
  p <- make_footnoted_ggtibble()
  td <- withr::local_tempdir()
  pdf(NULL)
  withr::defer(grDevices::dev.off())
  expect_output(knit_print(p, filename = file.path(td, "f%d.png")))
  expect_equal(sort(list.files(td)), c("f1.png", "f2.png"))
})

test_that("knit_print of a ggtibble with a non-ggplot figure is refused", {
  p <- make_footnoted_ggtibble()
  p$figure[[2]] <- new_gglist(list(ggplot2::ggplot()))
  pdf(NULL)
  withr::defer(grDevices::dev.off())
  expect_error(
    expect_output(knit_print(p)),
    regexp = "Each figure of a `ggtibble` with footnotes or labels must be a single ggplot",
    fixed = TRUE,
    class = "ggtibble_error_figure_not_gg"
  )
})

test_that("knitr::knit writes footnoted figures as markdown (knitr markdown, no pandoc)", {
  reset_ggtibble_caches()
  withr::defer(reset_ggtibble_caches())
  withr::local_envvar(c(QUARTO_VERSION = ""))
  td <- normalizePath(withr::local_tempdir(), winslash = "/")
  knit_env <- new.env(parent = globalenv())
  knit_env$my_plots <- make_footnoted_ggtibble(label = "lab{A}")
  knit_env$my_plots$label[2] <- ""
  rmd <- paste0(
    "```{r ggtibble=\"my_plots\", echo=FALSE, dev=\"png\", fig.path=\"", td, "/\"}\n",
    "```\n"
  )
  out <- knitr::knit(text = rmd, envir = knit_env, quiet = TRUE)
  expect_equal(
    out,
    paste0(
      "\n\n![Cap 1](", td, "/lab1.png)\n\nNote 1\n\n\n\n",
      "\n\n![Cap 2](", td, "/my_plots-2.png)\n\nNote 2\n\n\n\n\n"
    )
  )
  expect_equal(sort(list.files(td)), c("lab1.png", "my_plots-2.png"))
})

test_that("knit_print of a footnoted ggtibble in a chunk without results='asis' is an error", {
  reset_ggtibble_caches()
  withr::defer(reset_ggtibble_caches())
  td <- normalizePath(withr::local_tempdir(), winslash = "/")
  knit_env <- new.env(parent = globalenv())
  knit_env$my_plots <- make_footnoted_ggtibble()
  rmd <- paste0(
    "```{r error=FALSE, fig.path=\"", td, "/\"}\n",
    "knit_print(my_plots)\n",
    "```\n"
  )
  expect_error(
    knitr::knit(text = rmd, envir = knit_env, quiet = TRUE),
    regexp = "its chunk needs `results = \"asis\"`",
    fixed = TRUE,
    class = "ggtibble_error_results_not_asis"
  )
})

# Rendered documents ####

# The ggtibble that Quarto's own R process loads: this source tree when the
# tests run from it (devtools::test()), the installed package otherwise
quarto_setup_chunk <- function() {
  ns_path <- getNamespaceInfo("ggtibble", "path")
  load_line <-
    if (file.exists(file.path(ns_path, "R", "figure_emit.R"))) {
      sprintf("pkgload::load_all(%s, quiet = TRUE)", deparse(normalizePath(ns_path, winslash = "/")))
    } else {
      "library(ggtibble)"
    }
  c(
    "```{r}",
    "#| include: false",
    load_line,
    "my_plots <- ggtibble(",
    "  data.frame(A = 1:2, B = 3:4),",
    "  ggplot2::aes(x = B, y = B),",
    "  outercols = 'A',",
    "  caption = 'Cap {A}',",
    "  footnote = 'Note *{A}*',",
    "  label = 'fig-lab{A}'",
    ") + ggplot2::geom_point()",
    "```",
    "",
    "See @fig-lab2.",
    "",
    "```{r}",
    "#| ggtibble: \"my_plots\"",
    "#| echo: false",
    "```"
  )
}

skip_if_no_quarto <- function() {
  testthat::skip_on_cran()
  testthat::skip_if(!nzchar(Sys.which("quarto")), "the quarto binary is not on the PATH")
  testthat::skip_if_not_installed("quarto")
}

test_that("R Markdown to LaTeX puts each footnote inside its figure float, with a short caption and the label", {
  testthat::skip_on_cran()
  skip_if_no_pandoc()
  reset_ggtibble_caches()
  withr::defer(reset_ggtibble_caches())
  withr::local_envvar(c(QUARTO_VERSION = ""))
  td <- withr::local_tempdir()
  rmd_path <- file.path(td, "doc.Rmd")
  writeLines(
    c(
      "---", "title: t", "---", "",
      "```{r ggtibble=\"my_plots\", echo=FALSE}", "```"
    ),
    rmd_path
  )
  render_env <- new.env(parent = globalenv())
  render_env$my_plots <- make_footnoted_ggtibble(label = "lab{A}")
  render_env$my_plots$footnote <- paste0("Note *", 1:2, "* 50%")
  rmarkdown::render(
    rmd_path, output_format = rmarkdown::latex_document(), envir = render_env, quiet = TRUE
  )
  tex <- paste(readLines(file.path(td, "doc.tex"), warn = FALSE), collapse = "\n")
  for (i in 1:2) {
    expect_match(
      tex,
      sprintf(
        paste0(
          "\\begin{figure}\n\\centering\n\n\\includegraphics{doc_files/figure-latex/lab%d.pdf}\n\n",
          "\\caption[{Cap %d}]{Cap %d\\\\{\\footnotesize Note \\emph{%d} 50\\%%}}\\label{lab%d}\n\n",
          "\\end{figure}"
        ),
        i, i, i, i, i
      ),
      fixed = TRUE
    )
  }
  expect_true(file.exists(file.path(td, "doc_files", "figure-latex", "lab1.pdf")))
})

test_that("Quarto to Typst keeps each footnote after its figure in one unbreakable block", {
  skip_if_no_quarto()
  td <- withr::local_tempdir()
  qmd_path <- file.path(td, "doc.qmd")
  writeLines(
    c("---", "title: t", "format:", "  typst:", "    keep-typ: true", "---", "", quarto_setup_chunk()),
    qmd_path
  )
  quarto::quarto_render(qmd_path, quiet = TRUE)
  typ <- paste(readLines(file.path(td, "doc.typ"), warn = FALSE), collapse = "\n")
  expect_match(typ, "#ref(<fig-lab2>, supplement: [Figure])", fixed = TRUE)
  for (i in 1:2) {
    expect_match(
      typ,
      sprintf(
        paste0(
          "#block\\(breakable: false\\)\\[\n#figure\\(\\[\n",
          "#box\\(image\\(\"doc_files/figure-typst/fig-lab%d\\.[a-z]+\"\\)\\)\n",
          "\\], caption: figure\\.caption\\(\n[^\n]*\n\\[\nCap %d\n\\]\\), \n",
          "[^<]*<fig-lab%d>\n\n\n",
          "#block\\(width: 100%%, text\\(size: 0\\.9em\\)\\[\nNote #emph\\[%d\\]\n\n\\]\\)\n\\]"
        ),
        i, i, i, i
      )
    )
  }
})

test_that("Quarto to HTML writes each footnote directly after its figure, which carries its label", {
  skip_if_no_quarto()
  td <- withr::local_tempdir()
  qmd_path <- file.path(td, "doc.qmd")
  writeLines(c("---", "title: t", "format: html", "---", "", quarto_setup_chunk()), qmd_path)
  quarto::quarto_render(qmd_path, quiet = TRUE)
  html <- paste(readLines(file.path(td, "doc.html"), warn = FALSE), collapse = "\n")
  expect_match(html, "<a href=\"#fig-lab2\" class=\"quarto-xref\">Figure&nbsp;2</a>", fixed = TRUE)
  for (i in 1:2) {
    expect_match(
      html,
      sprintf(
        paste0(
          "<div id=\"fig-lab%d\" class=\"quarto-float[^\"]*\">\n<figure[^>]*>\n",
          "<div aria-describedby=\"fig-lab%d-caption[^\"]*\">\n",
          "<img src=\"doc_files/figure-html/fig-lab%d\\.png\"[^>]*>\n",
          "</div>\n<figcaption [^>]*>\nFigure&nbsp;%d: Cap %d\n</figcaption>\n</figure>\n</div>\n",
          "<div class=\"figure-footnote\" style=\"font-size: smaller;\">\n",
          "<p>Note <em>%d</em></p>\n</div>"
        ),
        i, i, i, i, i, i
      )
    )
  }
})
