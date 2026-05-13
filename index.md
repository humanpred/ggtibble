# ggtibble

The goal of `ggtibble` is to allow creation of similarly-formatted
figures as lists of ggplots (gglist) and tibbles of those lists with
captions. These are augmented with
[`knit_print()`](https://rdrr.io/pkg/knitr/man/knit_print.html) methods
enabling simple inclusion in reports.

## Installation

You can install the development version of `ggtibble` from
[GitHub](https://github.com/) with:

``` r

# install.packages("devtools")
devtools::install_github("humanpred/ggtibble")
```

## Example

This is a basic example which shows you how to solve a common problem:

``` r

library(ggtibble)
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
```

In an R Markdown or Quarto report, the `ggtibble` chunk option is a
one-line shorthand for the above: it auto-derives the chunk label, sets
`fig.cap` from the object’s caption, and runs
[`knit_print()`](https://rdrr.io/pkg/knitr/man/knit_print.html)
automatically.

    ```{r ggtibble="all_plots"}
    ```
