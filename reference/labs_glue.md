# Generate ggplot2 labels based on data in a ggtibble

Generate ggplot2 labels based on data in a ggtibble

## Usage

``` r
labs_glue(p, ...)
```

## Arguments

- p:

  The ggtibble object

- ...:

  Named arguments to be used as
  [`ggplot2::labs()`](https://ggplot2.tidyverse.org/reference/labs.html)
  labels where the value is a glue specification

## Value

`p` with the labels modified
