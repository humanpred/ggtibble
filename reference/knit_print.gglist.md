# Print a list of plots made by gglist

The `filename` argument may be given with an
[`sprintf()`](https://rdrr.io/r/base/sprintf.html) format including "%d"
to allow automatic numbering of the output filenames. Specifically, the
pattern of "%d" with an optional non-negative integer between the "%"
and "d" is searched for and if found, then the filename will be
generated using that [`sprintf()`](https://rdrr.io/r/base/sprintf.html)
format. Note that also means that other requirements for
[`sprintf()`](https://rdrr.io/r/base/sprintf.html) must be met; for
example, if you want a percent sign ("%") in the filename, it must be
doubled so that sprintf returns what is desired.

## Usage

``` r
# S3 method for class 'gglist'
knit_print(
  x,
  ...,
  filename = NULL,
  fig_suffix = NULL,
  float_barrier_after = 10
)

# S3 method for class 'ggtibble'
knit_print(x, ...)
```

## Arguments

- x:

  The gglist object

- ...:

  extra arguments to
  [`knit_print()`](https://rdrr.io/pkg/knitr/man/knit_print.html)

- filename:

  A filename with an optional "%d" sprintf pattern for saving the plots

- fig_suffix:

  Any text to add after the figure. Defaults to `NULL`, which means
  "auto-select": `"\n\n\\FloatBarrier\n\n"` for LaTeX output when
  `length(x) > float_barrier_after`, otherwise `"\n\n"`.

- float_barrier_after:

  Numeric threshold for emitting `\FloatBarrier` between figures in
  LaTeX output. When `length(x) > float_barrier_after` and
  [`knitr::is_latex_output()`](https://rdrr.io/pkg/knitr/man/output_type.html)
  is `TRUE` and the user did not supply `fig_suffix`, `fig_suffix`
  defaults to `"\n\n\\FloatBarrier\n\n"`. Has no effect on non-LaTeX
  output. Set to `Inf` to disable. Defaults to `10`.

## Value

The list, invisibly

## Details

When `length(x)` exceeds `float_barrier_after` and the output format is
LaTeX (as detected by
[`knitr::is_latex_output()`](https://rdrr.io/pkg/knitr/man/output_type.html)),
`fig_suffix` defaults to `"\n\n\\FloatBarrier\n\n"` instead of the usual
`"\n\n"`. This avoids the LaTeX "Output loop—100 consecutive dead
cycles" error that occurs when the float queue (default capacity ~18)
overflows. `\FloatBarrier` is provided by the `placeins` LaTeX package,
which is *not* loaded by default in
[`rmarkdown::pdf_document`](https://pkgs.rstudio.com/rmarkdown/reference/pdf_document.html);
add `\usepackage{placeins}` to the document preamble (e.g. via
`header-includes` in the YAML) when relying on the auto-suffix. Pass
`fig_suffix` explicitly to override, or set `float_barrier_after = Inf`
to disable the auto-suffix entirely.

## Functions

- `knit_print(ggtibble)`: Print the plots in a `ggtibble` object

## Footnotes and labels

A `ggtibble` whose "footnote" or "label" column (see
[`ggtibble()`](https://humanpred.github.io/ggtibble/reference/ggtibble.md))
is non-empty on any row is written by
[`knit_print()`](https://rdrr.io/pkg/knitr/man/knit_print.html) as
markdown: each figure is saved as an image and written with its caption,
its footnote, and its label as its identifier. The chunk therefore needs
`results = "asis"`; the `ggtibble` chunk option sets it, and calling
[`knit_print()`](https://rdrr.io/pkg/knitr/man/knit_print.html) in a
chunk without it is an error. A `ggtibble` with no footnotes or labels
renders through the knitr plot hook exactly as before.

Of the chunk options, this route uses `fig.path`, `label`, `dev` (one of
the common devices; others are an error), `fig.width`, `fig.height`,
`dpi`, and, for LaTeX, `fig.pos`. It does not apply `out.width`,
`out.height`, `fig.align`, `fig.alt`, `fig.cap` (the captions come from
the ggtibble), or `dev.args`.

Captions and footnotes are markdown and pass through to pandoc: emphasis
and links work, a footnote line starting with `# ` becomes a heading,
and raw LaTeX reaches only LaTeX output (pandoc drops it elsewhere). A
caption is joined onto one line, and unbalanced square brackets in it
are escaped.

|  |  |  |  |
|----|----|----|----|
| Output | Figure | Footnote | Kept with the figure |
| LaTeX (R Markdown and Quarto) | A figure float with `\label{<label>}` | Inside the float, appended to the caption after a line break in `\footnotesize`; the short caption (for the List of Figures) is the plain caption | Yes, it is in the float |
| Quarto to Typst | A figure Div | A paragraph in 0.9em text after the Div | Yes, the Div and footnote are one unbreakable Typst block |
| HTML | An image with its caption | A Div of class `figure-footnote` in a smaller font directly after the figure | Not applicable (no pages) |
| Word and other pandoc formats | An image with its caption | A plain paragraph, in the body text size, directly after the figure | No: Word may break the page between them |
| knitr markdown without pandoc | An image with its caption, without an identifier | A plain paragraph directly after the figure | Not applicable |

Under Quarto, a figure whose label starts with `fig-` is written as a
figure Div so that `@<label>` cross-references resolve; other labels are
kept as given, with a warning of class `ggtibble_warning_label_not_fig`,
since Quarto reads `@<label>` without the prefix as a citation. A figure
without a label is given the identifier `fig-<chunk label>` (with
`-<row number>` for more than one row), so each figure of a multi-row
ggtibble is its own numbered figure rather than a subfigure. Do not give
such a chunk a `fig-` label of its own; the `ggtibble` chunk option
leaves it off. In R Markdown to LaTeX, cross-reference a labelled figure
with `\ref{<label>}`.

Figure ids must be unique within a document: an id already written by an
earlier chunk is an error of class `ggtibble_error_label_duplicated`. A
labelled figure's image file is `<chunk label>-<label>` with the
device's extension; other figures use the knitr default
`<chunk label>-<row number>`.

## See also

Other knitters:
[`knit_print.gg()`](https://humanpred.github.io/ggtibble/reference/knit_print.gg.md)

## Examples

``` r
# Ensure that each figure is within its own float area
mydata <-
  list(
    data.frame(x = 1:3, y = 3:1),
    data.frame(x = 4:7, y = 7:4)
  )
p <- gglist(mydata, ggplot2::aes(x = x, y = y)) +
  ggplot2::geom_point()
knit_print(p, fig_suffix = "\n\n\\FloatBarrier\n\n")
#> 
#> 

#> 
#> 
#> \FloatBarrier
#> 
#> 
#> 
#> 
#> 

#> 
#> 
#> \FloatBarrier
#> 
#> 
#> 
```
