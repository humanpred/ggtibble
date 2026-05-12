# Make a tibble where one column is the data to plot, one is the gglist, and one is the caption

Make a tibble where one column is the data to plot, one is the gglist,
and one is the caption

## Usage

``` r
ggtibble(data, ...)

# S3 method for class 'data.frame'
ggtibble(
  data,
  mapping = ggplot2::aes(),
  ...,
  outercols = group_vars(data),
  labs = list(),
  caption = ""
)
```

## Arguments

- data:

  The data.frame to plot

- ...:

  Passed to subsequent methods (usually passed to
  [`gglist()`](https://humanpred.github.io/ggtibble/reference/gglist.md))

- mapping:

  Default list of aesthetic mappings to use for plot. If not specified,
  must be supplied in each layer added to the plot.

- outercols:

  The columns to have outside the nesting

- labs:

  Labels to add via
  [`labs_glue()`](https://humanpred.github.io/ggtibble/reference/labs_glue.md)

- caption:

  The glue specification for creating the caption

## Value

A data.frame with a column named "data_plot" with the data to plot,
"figure" with the gglist, and "caption" with the captions

A `ggtibble` object which is a tibble with columns named "figure" which
is a `gglist` object (a list of ggplots), "data_plot" which is the a
list of data.frames making up the source data used for each individual
plot, "caption" which is the text to use for the plot caption, and all
of the `outercols` used for nesting.

## Methods (by class)

- `ggtibble(data.frame)`: The default method for a data.frame or tibble

## Examples

``` r
d_plot <-
  data.frame(
    A = rep(c("foo", "bar"), each = 4),
    B = 1:8,
    C = 11:18,
    Bunit = "mg",
    Cunit = "km"
  )
all_plots <-
  ggtibble(
    d_plot,
    ggplot2::aes(x = B, y = C),
    outercols = c("A", "Bunit", "Cunit"),
    caption = "All the {A}",
    labs = list(x = "B ({Bunit})", y = "C ({Cunit})")
  ) +
  ggplot2::geom_point() +
  ggplot2::geom_line()
knit_print(all_plots)
#> 
#> 

#> 
#> 
#> 
#> 
#> 
#> 

#> 
#> 
#> 
#> 
```
