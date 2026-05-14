# ggtibble 1.0.2.9000

* `gglist` and `ggtibble` objects now automatically render every page when an
  element uses `ggforce::facet_wrap_paginate()` or
  `ggforce::facet_grid_paginate()`.  A new exported S3 generic `as_gglist()`
  (with methods for `gg`, `list`, `gglist`, and `labels`) is the entry point
  for page expansion.  Captions on a paginated `ggtibble` are appended with
  `" (panel {page} of {n_pages})"` so each rendered page receives a unique
  caption suitable for Quarto cross-references.  `ggsave.gglist()` accepts a
  single filename with a `%d` sprintf pattern that is expanded to match the
  total number of rendered pages.  `ggforce` is added to Suggests (issue 2).
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
