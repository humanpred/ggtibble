# Convert an object to a `ggtibble`

Converts a named (and possibly nested)
[`gglist()`](https://humanpred.github.io/ggtibble/reference/gglist.md)
into a
[`ggtibble()`](https://humanpred.github.io/ggtibble/reference/ggtibble.md)
whose `caption` column is built from the element names. This is the
bridge that lets a collection of figures built up as a `gglist` flow
into the reporting helpers
([`knit_print.ggtibble()`](https://humanpred.github.io/ggtibble/reference/knit_print.gglist.md),
[`ggsave.ggtibble()`](https://humanpred.github.io/ggtibble/reference/ggsave.md)).

## Usage

``` r
as_ggtibble(x, ...)

# S3 method for class 'gglist'
as_ggtibble(x, ..., caption_prefix = NULL)
```

## Arguments

- x:

  The object to convert (currently a `gglist`).

- ...:

  Passed to methods.

- caption_prefix:

  Text prepended (separated by a space) to the name of each element when
  building captions. Defaults to `NULL` (no prefix), and is set
  automatically to the outer caption when recursing into a nested
  `gglist`.

## Value

A `ggtibble` object with `figure` and `caption` columns.

## Details

When the `gglist` is nested (an element is itself a `gglist`), the
result is flattened to a single `ggtibble` with one row per leaf figure
and the outer element name prepended to each inner name. For example, a
top-level element named `"All Data"` whose value is a `gglist`
containing a figure named `"dv_pred_ipred_linear"` produces a caption of
`"All Data dv_pred_ipred_linear"`.

## Methods (by class)

- `as_ggtibble(gglist)`: Convert a (possibly nested) `gglist` to a
  `ggtibble`, using element names as captions

## Examples

``` r
g <-
  new_gglist(stats::setNames(
    list(
      ggplot2::ggplot(mtcars, ggplot2::aes(mpg, wt)) + ggplot2::geom_point(),
      ggplot2::ggplot(mtcars, ggplot2::aes(mpg, hp)) + ggplot2::geom_point()
    ),
    c("weight", "horsepower")
  ))
as_ggtibble(g)
#> # A tibble: 2 × 2
#>            figure caption   
#>          <gglist> <chr>     
#> 1 A ggplot object weight    
#> 2 A ggplot object horsepower
```
