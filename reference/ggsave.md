# Save a plot or list of plots

Save a plot or list of plots

## Usage

``` r
ggsave(
  filename,
  plot = ggplot2::last_plot(),
  device = NULL,
  path = NULL,
  scale = 1,
  width = NA,
  height = NA,
  units = c("in", "cm", "mm", "px"),
  dpi = 300,
  limitsize = TRUE,
  bg = NULL,
  create.dir = FALSE,
  ...
)

# S3 method for class 'gglist'
ggsave(
  filename,
  plot,
  device = NULL,
  path = NULL,
  scale = 1,
  width = NA,
  height = NA,
  units = c("in", "cm", "mm", "px"),
  dpi = 300,
  limitsize = TRUE,
  bg = NULL,
  create.dir = FALSE,
  ...
)

# S3 method for class 'ggtibble'
ggsave(
  filename,
  plot,
  device = NULL,
  path = NULL,
  scale = 1,
  width = NA,
  height = NA,
  units = c("in", "cm", "mm", "px"),
  dpi = 300,
  limitsize = TRUE,
  bg = NULL,
  create.dir = FALSE,
  ...
)
```

## Arguments

- filename:

  A character string passed to
  [`glue::glue_data()`](https://glue.tidyverse.org/reference/glue.html)
  to generate file names for each row in `plot`.

- plot:

  Plot to save, defaults to last plot displayed.

- device:

  Device to use. Can either be a device function (e.g.
  [png](https://rdrr.io/r/grDevices/png.html)), or one of "eps", "ps",
  "tex" (pictex), "pdf", "jpeg", "tiff", "png", "bmp", "svg" or "wmf"
  (windows only). If `NULL` (default), the device is guessed based on
  the `filename` extension.

- path:

  Path of the directory to save plot to: `path` and `filename` are
  combined to create the fully qualified file name. Defaults to the
  working directory.

- scale:

  Multiplicative scaling factor.

- width, height:

  Plot size in units expressed by the `units` argument. If not supplied,
  uses the size of the current graphics device.

- units:

  One of the following units in which the `width` and `height` arguments
  are expressed: `"in"`, `"cm"`, `"mm"` or `"px"`.

- dpi:

  Plot resolution. Also accepts a string input: "retina" (320), "print"
  (300), or "screen" (72). Only applies when converting pixel units, as
  is typical for raster output types.

- limitsize:

  When `TRUE` (the default), `ggsave()` will not save images larger than
  50x50 inches, to prevent the common error of specifying dimensions in
  pixels.

- bg:

  Background colour. If `NULL`, uses the `plot.background` fill value
  from the plot theme.

- create.dir:

  Whether to create new directories if a non-existing directory is
  specified in the `filename` or `path` (`TRUE`) or return an error
  (`FALSE`, default). If `FALSE` and run in an interactive session, a
  prompt will appear asking to create a new directory when necessary.

- ...:

  Other arguments passed on to the graphics device function, as
  specified by `device`.

## Methods (by class)

- `ggsave(gglist)`: Save the figures in a `gglist` object

- `ggsave(ggtibble)`: Save the figures in a `ggtibble` object
