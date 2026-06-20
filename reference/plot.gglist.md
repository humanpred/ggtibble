# Plot a list of plots made by gglist

Each element is rendered in order. `NULL` elements render nothing (via
the
[`plot.NULL()`](https://humanpred.github.io/ggtibble/reference/plot.NULL.md)
method) and nested `gglist` elements recurse, so a `gglist` that
contains other `gglist` objects (a list of lists of plots) renders every
leaf plot.

## Usage

``` r
# S3 method for class 'gglist'
plot(x, y, ...)

# S3 method for class 'ggtibble'
plot(x, y, ...)
```

## Arguments

- x:

  The `gglist` object

- y:

  Ignored; present to match the
  [`plot()`](https://rdrr.io/r/graphics/plot.default.html) generic

- ...:

  Passed to each element's
  [`plot()`](https://rdrr.io/r/graphics/plot.default.html) method

## Value

The `gglist`, invisibly

## Functions

- `plot(ggtibble)`: Plot the figures in a `ggtibble` object
