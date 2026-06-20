# Plot a `NULL` object (render nothing)

A `gglist` may contain `NULL` elements (for example a placeholder for a
plot that was not generated). Defining `plot.NULL()` lets those elements
be rendered as a no-op instead of erroring.

## Usage

``` r
# S3 method for class '`NULL`'
plot(x, y, ...)
```

## Arguments

- x:

  `NULL`

- y:

  Ignored; present to match the
  [`plot()`](https://rdrr.io/r/graphics/plot.default.html) generic

- ...:

  Ignored

## Value

`NULL`, invisibly
