# Print a ggplot (usually within knit_print.gglist)

Print a ggplot (usually within knit_print.gglist)

## Usage

``` r
# S3 method for class 'gg'
knit_print(
  x,
  ...,
  fig_prefix,
  fig_suffix,
  filename = NULL,
  width = 6,
  height = 4,
  units = "in"
)
```

## Arguments

- x:

  The gg object (i.e. a ggplot)

- ...:

  Ignored

- fig_prefix:

  Text to [`cat()`](https://rdrr.io/r/base/cat.html) before the figure
  is printed

- fig_suffix:

  Any text to add after the figure. Defaults to `NULL`, which means
  "auto-select": `"\n\n\\FloatBarrier\n\n"` for LaTeX output when
  `length(x) > float_barrier_after`, otherwise `"\n\n"`.

- filename:

  A filename saving the plot

- width, height:

  Plot size in units expressed by the `units` argument. If not supplied,
  uses the size of the current graphics device.

- units:

  One of the following units in which the `width` and `height` arguments
  are expressed: `"in"`, `"cm"`, `"mm"` or `"px"`.

## Value

The gg object, invisibly

## See also

Other knitters:
[`knit_print.gglist()`](https://humanpred.github.io/ggtibble/reference/knit_print.gglist.md)
