# ggtibble (development version)

* `ggtibble()` gains `footnote` and `label` arguments, glue specifications
  evaluated per row like `caption`, giving `footnote` and `label` columns
  (empty when not given, including from `as_ggtibble()`).  A footnote is
  markdown rendered under its figure: inside the figure float after the
  caption in LaTeX (with the plain caption as the List of Figures entry), in
  one unbreakable block with the figure Div in Quarto Typst, as a smaller
  `figure-footnote` Div directly after the figure in HTML, and as a plain
  paragraph directly after the figure in Word and plain markdown.  In LaTeX
  and Typst it cannot be separated from its figure by a page break; in Word it
  can, and it is in the body text size.  A label is the figure's own
  identifier (`\label{}` in LaTeX, the figure Div or image id in Quarto and
  pandoc output) and part of its image file name.  Labels must be unique
  (ignoring case) and use only letters, digits, hyphens, underscores, and
  dots, and a figure id may appear only once in a document.  Under Quarto, a
  label without the `fig-` prefix gives a warning, since `@` references to it
  do not resolve.  A ggtibble without footnotes or labels renders as before.
* `ggsave()` on a `ggtibble` without `filename` names each file after its
  label.
* Quarto renders are detected again with current Quarto versions, which no
  longer set the `QUARTO_VERSION` environment variable, so the `ggtibble`
  chunk option once more prefixes `fig-` to its labels and uses `fig.subcap`
  for multiple captions under Quarto.

# ggtibble 1.0.4

* `gglist` objects may now nest: a `gglist` element of a `gglist` is allowed,
  so a `gglist` can represent a list of lists of plots.  The `+` broadcast,
  `print()`, and the new `plot()` method all recurse through the nesting.
* `gglist` element names are now preserved through the `+` broadcast (they were
  previously dropped), in addition to construction and subsetting.  This makes
  name-indexed collections (`g[["my plot"]]`, `names(g)`) reliable.
* New `plot()` methods for `gglist` and `ggtibble`, plus a `plot.NULL()` method
  so that `NULL` elements of a `gglist` render as a no-op instead of erroring.
  The `+` broadcast is likewise `NULL`-safe (a `NULL` element stays `NULL`).
* New exported S3 generic `as_ggtibble()` with a `gglist` method that converts a
  named (and possibly nested) `gglist` into a `ggtibble`, using the element
  names as captions.  Nesting is flattened and the outer name is prepended to
  each inner name (e.g. `"All Data dv_pred_ipred_linear"`).

# ggtibble 1.0.3

* `knit_print.gglist()` automatically inserts `\FloatBarrier` between
  figures when more than 10 plots are rendered to LaTeX, avoiding the
  LaTeX "Output loop---100 consecutive dead cycles" error.  The
  threshold is configurable via the new `float_barrier_after` argument
  (default `10`; use `Inf` to disable).  Requires `\usepackage{placeins}`
  in the document preamble. (#27)
* New exported S3 generic `as_gglist()` (methods for `gg`, `list`, `gglist`,
  `labels`, and `NULL`) that promotes an input to a `gglist`.  When the input
  uses `ggforce::facet_wrap_paginate()` or `ggforce::facet_grid_paginate()`,
  `as_gglist()` expands the paginated plot into one element per rendered
  page so it can be passed to `print()`, `knit_print()`, or `ggsave()` and
  every page will render.  Page expansion is opt-in — render methods are
  unchanged and do not call `as_gglist()` implicitly.  `ggforce` is added to
  Suggests (issue 2).
* New `ggtibble` knitr chunk option that simplifies rendering a `ggtibble` in
  R Markdown and Quarto reports.  Setting `ggtibble = "my_obj"` (or
  `ggtibble = my_obj`) on a chunk auto-sets the chunk label, `fig.cap`, and
  injects `knit_print(my_obj)` for empty chunk bodies.  Under Quarto, the
  label is prefixed with `fig-` and multi-caption objects use `fig.subcap` so
  `@fig-...` cross-references work (issue 17).
* Works with the `ggbreak` package

# ggtibble 1.0.2

* `ggtibble()` now warns if `outercols` are not used in either the `caption` or
  the `labs` argument (#13).
* `ggtibble` and `gglist` objects now work with the ggplot2 `%+%` operator (#16)
* A new `ggsave()` generic function will now enable simpler saving of `ggtibble`
  and `gglist` objects (unique filenames are required to save).
* `aes()` and `data.frame()` objects can be added to `ggtibble` and `gglist`
  objects (#23).
* `ggsave()` can accept a character vector of all filenames to use when saving
  (#25).
* Update testing to work with ggplot2 version 4.0.0

# ggtibble 1.0.1

* `labs` argument to `ggtibble()` can now include `NULL (#6)
* `guides()` can now be added to `gglist` objects.
* Labels created with the `labs` argument to `ggtibble()` will not longer all be
  the same (#3)
* `new_gglist()` and `new_ggtibble()` are now exported making it easier to
  create objects.
