# Print a list of plots made by gglist

The `filename` argument may be given with an
[`sprintf()`](https://rdrr.io/r/base/sprintf.html) format including "%d"
to allow automatic numbering of the output filenames. Specifically, the
pattern of "%d" with an optional non-negative integer between the "%"
and "d" is searched for and if found, then the filename will be
generated using that [`sprintf()`](https://rdrr.io/r/base/sprintf.html)
format. Note that also means that other requirements for
[`sprintf()`](https://rdrr.io/r/base/sprintf.html) must be met; for
example, if you want a percent sign ("%") in the filename, it must be
doubled so that sprintf returns what is desired.

## Usage

``` r
# S3 method for class 'gglist'
knit_print(
  x,
  ...,
  filename = NULL,
  fig_suffix = NULL,
  float_barrier_after = 10
)

# S3 method for class 'ggtibble'
knit_print(x, ...)
```

## Arguments

- x:

  The gglist object

- ...:

  extra arguments to
  [`knit_print()`](https://rdrr.io/pkg/knitr/man/knit_print.html)

- filename:

  A filename with an optional "%d" sprintf pattern for saving the plots

- fig_suffix:

  Any text to add after the figure. Defaults to `NULL`, which means
  "auto-select": `"\n\n\\FloatBarrier\n\n"` for LaTeX output when
  `length(x) > float_barrier_after`, otherwise `"\n\n"`.

- float_barrier_after:

  Numeric threshold for emitting `\FloatBarrier` between figures in
  LaTeX output. When `length(x) > float_barrier_after` and
  [`knitr::is_latex_output()`](https://rdrr.io/pkg/knitr/man/output_type.html)
  is `TRUE` and the user did not supply `fig_suffix`, `fig_suffix`
  defaults to `"\n\n\\FloatBarrier\n\n"`. Has no effect on non-LaTeX
  output. Set to `Inf` to disable. Defaults to `10`.

## Value

The list, invisibly

## Details

When `length(x)` exceeds `float_barrier_after` and the output format is
LaTeX (as detected by
[`knitr::is_latex_output()`](https://rdrr.io/pkg/knitr/man/output_type.html)),
`fig_suffix` defaults to `"\n\n\\FloatBarrier\n\n"` instead of the usual
`"\n\n"`. This avoids the LaTeX "Output loop—100 consecutive dead
cycles" error that occurs when the float queue (default capacity ~18)
overflows. `\FloatBarrier` is provided by the `placeins` LaTeX package,
which is *not* loaded by default in
[`rmarkdown::pdf_document`](https://pkgs.rstudio.com/rmarkdown/reference/pdf_document.html);
add `\usepackage{placeins}` to the document preamble (e.g. via
`header-includes` in the YAML) when relying on the auto-suffix. Pass
`fig_suffix` explicitly to override, or set `float_barrier_after = Inf`
to disable the auto-suffix entirely.

## Functions

- `knit_print(ggtibble)`: Print the plots in a `ggtibble` object

## See also

Other knitters:
[`knit_print.gg()`](https://humanpred.github.io/ggtibble/reference/knit_print.gg.md)

## Examples

``` r
# Ensure that each figure is within its own float area
mydata <-
  list(
    data.frame(x = 1:3, y = 3:1),
    data.frame(x = 4:7, y = 7:4)
  )
p <- gglist(mydata, ggplot2::aes(x = x, y = y)) +
  ggplot2::geom_point()
knit_print(p, fig_suffix = "\n\n\\FloatBarrier\n\n")
#> 
#> 

#> 
#> 
#> \FloatBarrier
#> 
#> 
#> 
#> 
#> 

#> 
#> 
#> \FloatBarrier
#> 
#> 
#> 
```
