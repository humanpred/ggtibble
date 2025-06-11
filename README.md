
# ggtibble

<!-- badges: start -->
[![R-CMD-check](https://github.com/humanpred/ggtibble/actions/workflows/R-CMD-check.yaml/badge.svg)](https://github.com/humanpred/ggtibble/actions/workflows/R-CMD-check.yaml)
[![CRAN status](https://www.r-pkg.org/badges/version/ggtibble)](https://CRAN.R-project.org/package=ggtibble)
[![Codecov test coverage](https://codecov.io/gh/humanpred/ggtibble/graph/badge.svg)](https://app.codecov.io/gh/humanpred/ggtibble)
<!-- badges: end -->

The goal of `ggtibble` is to allow creation of similarly-formatted figures as
lists of ggplots (gglist) and tibbles of those lists with captions.  These are
augmented with `knit_print()` methods enabling simple inclusion in reports.

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
