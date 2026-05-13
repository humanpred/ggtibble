# Changelog

## ggtibble 1.0.2.9000

- New `ggtibble` knitr chunk option that simplifies rendering a
  `ggtibble` in R Markdown and Quarto reports. Setting
  `ggtibble = "my_obj"` (or `ggtibble = my_obj`) on a chunk auto-sets
  the chunk label, `fig.cap`, and injects `knit_print(my_obj)` for empty
  chunk bodies. Under Quarto, the label is prefixed with `fig-` and
  multi-caption objects use `fig.subcap` so `@fig-...` cross-references
  work (issue 17).
- Works with the `ggbreak` package

## ggtibble 1.0.2

CRAN release: 2025-06-11

- [`ggtibble()`](https://humanpred.github.io/ggtibble/reference/ggtibble.md)
  now warns if `outercols` are not used in either the `caption` or the
  `labs` argument
  ([\#13](https://github.com/humanpred/ggtibble/issues/13)).
- `ggtibble` and `gglist` objects now work with the ggplot2 `%+%`
  operator ([\#16](https://github.com/humanpred/ggtibble/issues/16))
- A new
  [`ggsave()`](https://humanpred.github.io/ggtibble/reference/ggsave.md)
  generic function will now enable simpler saving of `ggtibble` and
  `gglist` objects (unique filenames are required to save).
- [`aes()`](https://ggplot2.tidyverse.org/reference/aes.html) and
  [`data.frame()`](https://rdrr.io/r/base/data.frame.html) objects can
  be added to `ggtibble` and `gglist` objects
  ([\#23](https://github.com/humanpred/ggtibble/issues/23)).
- [`ggsave()`](https://humanpred.github.io/ggtibble/reference/ggsave.md)
  can accept a character vector of all filenames to use when saving
  ([\#25](https://github.com/humanpred/ggtibble/issues/25)).
- Update testing to work with ggplot2 version 4.0.0

## ggtibble 1.0.1

CRAN release: 2024-06-19

- `labs` argument to
  [`ggtibble()`](https://humanpred.github.io/ggtibble/reference/ggtibble.md)
  can now include \`NULL
  ([\#6](https://github.com/humanpred/ggtibble/issues/6))
- [`guides()`](https://ggplot2.tidyverse.org/reference/guides.html) can
  now be added to `gglist` objects.
- Labels created with the `labs` argument to
  [`ggtibble()`](https://humanpred.github.io/ggtibble/reference/ggtibble.md)
  will not longer all be the same
  ([\#3](https://github.com/humanpred/ggtibble/issues/3))
- [`new_gglist()`](https://humanpred.github.io/ggtibble/reference/new_gglist.md)
  and
  [`new_ggtibble()`](https://humanpred.github.io/ggtibble/reference/new_ggtibble.md)
  are now exported making it easier to create objects.
