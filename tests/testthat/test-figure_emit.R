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
  expect_equal(
    figure_ids(c("a", "b"), chunk_label = "chunk", quarto = FALSE),
    list(id = c("a", "b"), derived = c(FALSE, FALSE))
  )
  expect_equal(
    figure_ids(c("a", ""), chunk_label = "chunk", quarto = FALSE),
    list(id = c("a", NA), derived = c(FALSE, FALSE))
  )
  expect_equal(
    figure_ids(c("", ""), chunk_label = "chunk", quarto = TRUE),
    list(id = c("fig-chunk-1", "fig-chunk-2"), derived = c(TRUE, TRUE))
  )
  expect_equal(
    figure_ids("", chunk_label = "chunk", quarto = TRUE),
    list(id = "fig-chunk", derived = TRUE)
  )
  # A chunk label that already starts with fig- is not prefixed twice
  expect_equal(
    figure_ids(c("fig-x", ""), chunk_label = "fig-chunk", quarto = TRUE),
    list(id = c("fig-x", "fig-chunk-2"), derived = c(FALSE, TRUE))
  )
})

test_that("figure_ids refuses a derived id that repeats a label, saying it was derived", {
  expect_error(
    figure_ids(c("fig-chunk-2", ""), chunk_label = "chunk", quarto = TRUE),
    regexp = paste0(
      "The figure id `fig-chunk-2`, derived from the chunk label `chunk` for a figure without a label, ",
      "is also a `label` of the ggtibble; figure ids must be unique"
    ),
    fixed = TRUE,
    class = "ggtibble_error_label_duplicated"
  )
})

# register_document_ids ####

test_that("register_document_ids refuses an id already used in the document", {
  reset_ggtibble_caches()
  withr::defer(reset_ggtibble_caches())
  register_document_ids(c("a", NA), derived = c(FALSE, FALSE), chunk_label = "first")
  register_document_ids("b", derived = FALSE, chunk_label = "second")
  expect_error(
    register_document_ids(c("c", "a"), derived = c(FALSE, FALSE), chunk_label = "third"),
    regexp = paste0(
      "The figure id `a` in chunk `third` was already used in chunk `first`; ",
      "figure ids must be unique within a document"
    ),
    fixed = TRUE,
    class = "ggtibble_error_label_duplicated"
  )
  register_document_ids("fig-x-1", derived = FALSE, chunk_label = "fig-x")
  expect_error(
    register_document_ids("fig-x-1", derived = TRUE, chunk_label = "x"),
    regexp = paste0(
      "The figure id `fig-x-1` (derived from the chunk label for a figure without a label) ",
      "in chunk `x` was already used in chunk `fig-x`; figure ids must be unique within a document"
    ),
    fixed = TRUE,
    class = "ggtibble_error_label_duplicated"
  )
})

test_that("register_document_ids forgets ids from an earlier knitting run", {
  reset_ggtibble_caches()
  withr::defer(reset_ggtibble_caches())
  # As left by a run that stopped before the document hook reset the caches
  assign("frame", new.env(), envir = .ggtibble_id_cache)
  assign("chunks", c(a = "old"), envir = .ggtibble_id_cache)
  expect_silent(register_document_ids("a", derived = FALSE, chunk_label = "new"))
  expect_equal(get("chunks", envir = .ggtibble_id_cache), c(a = "new"))
})

test_that("reset_ggtibble_caches clears the document ids", {
  register_document_ids("a", derived = FALSE, chunk_label = "first")
  reset_ggtibble_caches()
  expect_length(ls(.ggtibble_id_cache), 0)
})

# warn_quarto_labels_not_fig ####

test_that("warn_quarto_labels_not_fig names the labels without the fig- prefix", {
  expect_warning(
    warn_quarto_labels_not_fig(c("fig-a", "b", "", "c.d"), chunk_label = "chunk"),
    regexp = paste0(
      "Under Quarto, only labels starting with `fig-` are cross-referenceable figures, ",
      "so `@` references to these labels in chunk `chunk` will not resolve: `b`, `c.d`"
    ),
    fixed = TRUE,
    class = "ggtibble_warning_label_not_fig"
  )
  expect_silent(warn_quarto_labels_not_fig(c("fig-a", ""), chunk_label = "chunk"))
})

# figure_image_path and check_figure_paths ####

test_that("figure_image_path prefixes a labelled figure's file with the chunk label", {
  options <- list(fig.path = "out/figure-html/", label = "chunk")
  local_knit_opts(out.format = "markdown")
  expect_equal(figure_image_path("lab1", number = 1, ext = "png", options = options), "out/figure-html/chunk-lab1.png")
  expect_equal(figure_image_path("", number = 2, ext = "png", options = options), "out/figure-html/chunk-2.png")
})

test_that("check_figure_paths refuses figures that would share an image file", {
  expect_identical(check_figure_paths(c("f/c-a.png", "f/c-2.png"), chunk_label = "c"), c("f/c-a.png", "f/c-2.png"))
  # A label "2" beside an unlabelled second row
  expect_error(
    check_figure_paths(c("f/c-2.png", "f/c-2.png"), chunk_label = "c"),
    regexp = paste0(
      "Figures in chunk `c` would be saved to the same image file: `f/c-2.png`; ",
      "change the labels so that no two differ only by case or match another figure's row number"
    ),
    fixed = TRUE,
    class = "ggtibble_error_figure_path_duplicated"
  )
  expect_error(
    check_figure_paths(c("f/c-A.png", "f/c-a.png", "f/c-b.png"), chunk_label = "c"),
    regexp = "would be saved to the same image file: `f/c-A.png`, `f/c-a.png`;",
    fixed = TRUE,
    class = "ggtibble_error_figure_path_duplicated"
  )
})

# markdown_link_text ####

test_that("markdown_link_text escapes unbalanced brackets and a trailing backslash only", {
  expect_equal(markdown_link_text("AUC over (0, 24] h"), "AUC over (0, 24\\] h")
  expect_equal(markdown_link_text("from [0, 24) h"), "from \\[0, 24) h")
  expect_equal(markdown_link_text("] and ["), "\\] and \\[")
  # Balanced brackets, as in a markdown link, pass through
  expect_equal(markdown_link_text("see [the protocol](https://x.org)"), "see [the protocol](https://x.org)")
  # Already-escaped brackets are left alone
  expect_equal(markdown_link_text("x \\] y"), "x \\] y")
  # One trailing backslash would escape the closing bracket; two are a literal
  # backslash already
  expect_equal(markdown_link_text("ends in \\"), "ends in \\\\")
  expect_equal(markdown_link_text("ends in \\\\"), "ends in \\\\")
  expect_equal(markdown_link_text("two\n\nparagraphs"), "two paragraphs")
  expect_equal(markdown_link_text(""), "")
})

# figure_markdown ####

test_that("figure_markdown: knitr markdown is an image and a paragraph, without an id", {
  expect_equal(
    figure_markdown("markdown", "p.png", caption = "Cap", footnote = "Note *em*", id = "lab", quarto = FALSE),
    "\n\n![Cap](<p.png>)\n\nNote *em*\n\n"
  )
  expect_equal(
    figure_markdown("markdown", "p.png", caption = "Cap", footnote = "", id = NA, quarto = FALSE),
    "\n\n![Cap](<p.png>)\n\n"
  )
})

test_that("figure_markdown: other pandoc formats (docx) give the image an id and a plain paragraph", {
  expect_equal(
    figure_markdown("pandoc", "p.png", caption = "Cap", footnote = "Note", id = "lab", quarto = FALSE),
    "\n\n![Cap](<p.png>){#lab}\n\nNote\n\n"
  )
})

test_that("figure_markdown: HTML puts the footnote in a smaller figure-footnote Div", {
  expect_equal(
    figure_markdown("html", "p.png", caption = "Cap", footnote = "Note", id = "lab", quarto = FALSE),
    "\n\n![Cap](<p.png>){#lab}\n\n::: {.figure-footnote style=\"font-size: smaller;\"}\nNote\n:::\n\n"
  )
  expect_equal(
    figure_markdown("html", "p.png", caption = "Cap", footnote = "", id = NA, quarto = FALSE),
    "\n\n![Cap](<p.png>)\n\n"
  )
})

test_that("figure_markdown: Quarto writes a figure Div for a fig- id and an image otherwise", {
  expect_equal(
    figure_markdown("html", "p.png", caption = "Cap", footnote = "", id = "fig-a", quarto = TRUE),
    "\n\n::: {#fig-a}\n![](<p.png>)\n\nCap\n:::\n\n"
  )
  expect_equal(
    figure_markdown("html", "p.png", caption = "Cap", footnote = "", id = "a", quarto = TRUE),
    "\n\n![Cap](<p.png>){#a}\n\n"
  )
})

test_that("figure_markdown: Typst keeps the figure Div and footnote in one unbreakable block", {
  skip_if_no_pandoc()
  expect_equal(
    figure_markdown("typst", "p.svg", caption = "Cap", footnote = "Note *em*", id = "fig-a", quarto = TRUE),
    paste0(
      "\n\n```{=typst}\n#block(breakable: false)[\n```\n",
      "\n\n::: {#fig-a}\n![](<p.svg>)\n\nCap\n:::\n\n",
      "\n```{=typst}\n#block(width: 100%, text(size: 0.9em)[\n```\n\n",
      "Note *em*\n\n",
      "\n```{=typst}\n])\n]\n```\n\n"
    )
  )
  # Without a footnote there is no block
  expect_equal(
    figure_markdown("typst", "p.svg", caption = "Cap", footnote = "", id = "fig-a", quarto = TRUE),
    "\n\n::: {#fig-a}\n![](<p.svg>)\n\nCap\n:::\n\n"
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
    "\n\n::: {#fig-a fig-scap=\"Cap \\\"q\\\"\"}\n![](<p.pdf>)\n\nCap \"q\"`\\\\{\\footnotesize`{=latex} Note`}`{=latex}\n:::\n\n"
  )
  expect_equal(
    figure_markdown("latex", "p.pdf", caption = "Cap", footnote = "", id = "fig-a", quarto = TRUE),
    "\n\n::: {#fig-a}\n![](<p.pdf>)\n\nCap\n:::\n\n"
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
      "\n\n![Cap 1](<", td, "/my_plots-lab1.png>)\n\nNote 1\n\n\n\n",
      "\n\n![Cap 2](<", td, "/my_plots-2.png>)\n\nNote 2\n\n\n\n\n"
    )
  )
  expect_equal(sort(list.files(td)), c("my_plots-2.png", "my_plots-lab1.png"))
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

test_that("two chunks writing the same figure id stop with an error naming both chunks", {
  reset_ggtibble_caches()
  withr::defer(reset_ggtibble_caches())
  withr::local_envvar(c(QUARTO_VERSION = ""))
  td <- normalizePath(withr::local_tempdir(), winslash = "/")
  knit_env <- new.env(parent = globalenv())
  knit_env$first <- make_footnoted_ggtibble(label = "lab{A}")
  knit_env$second <- make_footnoted_ggtibble(label = "lab{A}")
  rmd <- paste0(
    "```{r ggtibble=\"first\", error=FALSE, fig.path=\"", td, "/\"}\n```\n\n",
    "```{r ggtibble=\"second\", error=FALSE, fig.path=\"", td, "/\"}\n```\n"
  )
  expect_error(
    knitr::knit(text = rmd, envir = knit_env, quiet = TRUE),
    regexp = paste0(
      "The figure id `lab1` in chunk `second` was already used in chunk `first`; ",
      "figure ids must be unique within a document"
    ),
    fixed = TRUE,
    class = "ggtibble_error_label_duplicated"
  )
})

test_that("knitting the same document twice does not see the first run's ids", {
  reset_ggtibble_caches()
  withr::defer(reset_ggtibble_caches())
  withr::local_envvar(c(QUARTO_VERSION = ""))
  td <- normalizePath(withr::local_tempdir(), winslash = "/")
  knit_env <- new.env(parent = globalenv())
  knit_env$my_plots <- make_footnoted_ggtibble(label = "lab{A}")
  rmd <- paste0("```{r ggtibble=\"my_plots\", echo=FALSE, fig.path=\"", td, "/\"}\n```\n")
  first <- knitr::knit(text = rmd, envir = knit_env, quiet = TRUE)
  expect_equal(knitr::knit(text = rmd, envir = knit_env, quiet = TRUE), first)
})

test_that("knitting under Quarto warns about labels without the fig- prefix", {
  reset_ggtibble_caches()
  withr::defer(reset_ggtibble_caches())
  withr::local_envvar(c(QUARTO_VERSION = "1.5.0"))
  td <- normalizePath(withr::local_tempdir(), winslash = "/")
  knit_env <- new.env(parent = globalenv())
  knit_env$my_plots <- make_footnoted_ggtibble(label = c("fig-a{A}"))
  knit_env$my_plots$label[2] <- "b2"
  # warning=NA leaves the warning to propagate rather than be written out
  rmd <- paste0("```{r ggtibble=\"my_plots\", warning=NA, fig.path=\"", td, "/\"}\n```\n")
  expect_warning(
    knitr::knit(text = rmd, envir = knit_env, quiet = TRUE),
    regexp = paste0(
      "Under Quarto, only labels starting with `fig-` are cross-referenceable figures, ",
      "so `@` references to these labels in chunk `my_plots` will not resolve: `b2`"
    ),
    fixed = TRUE,
    class = "ggtibble_warning_label_not_fig"
  )
})

# Rendered documents ####

# An R Markdown document whose captions have an unbalanced bracket, rendered
# with `output_format`; returns the output file path
render_bracket_caption_rmd <- function(output_format, td) {
  rmd_path <- file.path(td, "doc.Rmd")
  writeLines(c("---", "title: t", "---", "", "```{r ggtibble=\"my_plots\", echo=FALSE}", "```"), rmd_path)
  render_env <- new.env(parent = globalenv())
  render_env$my_plots <- make_footnoted_ggtibble(label = "lab{A}")
  render_env$my_plots$caption <- paste("AUC over (0, 24] h", 1:2)
  rmarkdown::render(rmd_path, output_format = output_format, envir = render_env, quiet = TRUE)
}

test_that("R Markdown to HTML: a caption with an unbalanced bracket still gives the image, its id, and the footnote", {
  testthat::skip_on_cran()
  skip_if_no_pandoc()
  reset_ggtibble_caches()
  withr::defer(reset_ggtibble_caches())
  withr::local_envvar(c(QUARTO_VERSION = ""))
  td <- withr::local_tempdir()
  out <- render_bracket_caption_rmd(rmarkdown::html_document(self_contained = FALSE), td)
  html <- paste(readLines(out, warn = FALSE), collapse = "\n")
  expect_false(grepl("![AUC", html, fixed = TRUE))
  for (i in 1:2) {
    expect_match(
      html,
      sprintf(
        paste0(
          "<div class=\"float\" id=\"lab%d\">\n",
          "<img src=\"doc_files/figure-html/my_plots-lab%d\\.png\"\\salt=\"AUC over \\(0, 24\\] h %d\" />\n",
          "<div class=\"figcaption\">AUC over \\(0, 24\\] h %d</div>\n",
          "</div>\n",
          "<div class=\"figure-footnote\" style=\"font-size: smaller;\">\n<p>Note %d</p>\n</div>"
        ),
        i, i, i, i, i
      )
    )
  }
})

test_that("R Markdown to Word: a caption with an unbalanced bracket still gives the image, its id, and the footnote", {
  testthat::skip_on_cran()
  skip_if_no_pandoc()
  reset_ggtibble_caches()
  withr::defer(reset_ggtibble_caches())
  withr::local_envvar(c(QUARTO_VERSION = ""))
  td <- withr::local_tempdir()
  out <- render_bracket_caption_rmd(rmarkdown::word_document(), td)
  utils::unzip(out, files = "word/document.xml", exdir = td)
  xml <- paste(readLines(file.path(td, "word", "document.xml"), warn = FALSE, encoding = "UTF-8"), collapse = "\n")
  expect_false(grepl("![AUC", xml, fixed = TRUE))
  # pandoc writes a figure's id as a Word bookmark from 3.8.3 (verified; 3.1.3
  # writes none), so the bookmark is only expected from that version on
  bookmark_expected <- rmarkdown::pandoc_available("3.8.3")
  for (i in 1:2) {
    # In document order: the bookmark carrying the id, the image, the caption,
    # then the footnote paragraph
    positions <- c(
      bookmark = regexpr(sprintf("<w:bookmarkStart[^>]*w:name=\"lab%d\"", i), xml),
      image = regexpr(sprintf("<wp:docPr descr=\"AUC over (0, 24] h %d\"", i), xml, fixed = TRUE),
      caption = regexpr(sprintf("<w:t xml:space=\"preserve\">AUC over (0, 24] h %d</w:t>", i), xml, fixed = TRUE),
      footnote = regexpr(sprintf("<w:t xml:space=\"preserve\">Note %d</w:t>", i), xml, fixed = TRUE)
    )
    if (!bookmark_expected) {
      positions <- positions[names(positions) != "bookmark"]
    }
    expect_true(all(positions > 0), info = paste(names(positions)[positions < 0], collapse = ", "))
    expect_equal(names(sort(positions)), names(positions))
  }
})

# A two-figure, footnoted, labelled ggtibble chunk for the Quarto render tests
quarto_setup_chunk <- function() {
  c(
    "```{r}",
    "#| include: false",
    quarto_load_ggtibble_line(),
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
          "\\begin{figure}\n\\centering\n\n\\includegraphics{doc_files/figure-latex/my_plots-lab%d.pdf}\n\n",
          "\\caption[{Cap %d}]{Cap %d\\\\{\\footnotesize Note \\emph{%d} 50\\%%}}\\label{lab%d}\n\n",
          "\\end{figure}"
        ),
        i, i, i, i, i
      ),
      fixed = TRUE
    )
  }
  expect_true(file.exists(file.path(td, "doc_files", "figure-latex", "my_plots-lab1.pdf")))
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
          "#box\\(image\\(\"doc_files/figure-typst/my_plots-fig-lab%d\\.[a-z]+\"\\)\\)\n",
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
          "<img src=\"doc_files/figure-html/my_plots-fig-lab%d\\.png\"[^>]*>\n",
          "</div>\n<figcaption [^>]*>\nFigure&nbsp;%d: Cap %d\n</figcaption>\n</figure>\n</div>\n",
          "<div class=\"figure-footnote\" style=\"font-size: smaller;\">\n",
          "<p>Note <em>%d</em></p>\n</div>"
        ),
        i, i, i, i, i, i
      )
    )
  }
})
