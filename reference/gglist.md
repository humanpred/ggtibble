# Generate a list of ggplots from a list of data.frames

Generate a list of ggplots from a list of data.frames

## Usage

``` r
gglist(
  data = NULL,
  mapping = ggplot2::aes(),
  ...,
  environment = parent.frame()
)
```

## Arguments

- data:

  A list of data.frames (or similar objects)

- mapping:

  Default list of aesthetic mappings to use for plot. If not specified,
  must be supplied in each layer added to the plot.

- ...:

  Other arguments passed on to methods. Not currently used.

- environment:

  **\[deprecated\]** Used prior to tidy evaluation.

## Value

A list of ggplot2 objects

## Examples

``` r
mydata <-
  list(
    data.frame(x = 1:3, y = 3:1),
    data.frame(x = 4:7, y = 7:4)
  )
gglist(mydata, ggplot2::aes(x = x, y = y)) +
  ggplot2::geom_point()

```
