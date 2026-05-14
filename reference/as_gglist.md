# Convert an object to a `gglist`

Promotes an input value to a `gglist`. When the input includes a `gg`
object that uses
[`ggforce::facet_wrap_paginate()`](https://ggforce.data-imaginist.com/reference/facet_wrap_paginate.html)
or
[`ggforce::facet_grid_paginate()`](https://ggforce.data-imaginist.com/reference/facet_grid_paginate.html),
the paginated plot is expanded into one `gglist` element per rendered
page so subsequent calls to
[`print()`](https://rdrr.io/r/base/print.html),
[`knit_print()`](https://rdrr.io/pkg/knitr/man/knit_print.html), or
[`ggsave()`](https://humanpred.github.io/ggtibble/reference/ggsave.md)
render every page. Inputs that already use a non-paginated facet (or no
facet at all) pass through unchanged.

## Usage

``` r
as_gglist(x, ...)
```

## Arguments

- x:

  A `gg`, `gglist`, list of `gg` objects, `NULL`, or `labels` object to
  convert.

- ...:

  Not used.

## Value

A `gglist` object.

## Details

For an input that is already a `gglist`, the value is returned unchanged
so the method is a no-op when nothing needs to be coerced. Call this
yourself before rendering when you want paginated facets expanded — the
render methods do not call it implicitly because page expansion is not
always desired.

## Examples

``` r
p <- ggplot2::ggplot(mtcars, ggplot2::aes(mpg, wt)) + ggplot2::geom_point()
as_gglist(p)
```
