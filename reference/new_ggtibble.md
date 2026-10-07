# Create a new `ggtibble` object

Create a new `ggtibble` object

## Usage

``` r
new_ggtibble(x)
```

## Arguments

- x:

  A data.frame with a column named "figure" and "caption", and where the
  "figure" column is a ggtibble. The "footnote" and "label" columns are
  added as empty strings when absent. Non-empty labels must be unique,
  ignoring case, and may contain only letters, digits, hyphens,
  underscores, and dots.

## Value

The object with a ggtibble class

## See also

Other New ggtibble objects:
[`new_gglist()`](https://humanpred.github.io/ggtibble/reference/new_gglist.md)

## Examples

``` r
new_ggtibble(tibble::tibble(figure = list(ggplot2::ggplot()), caption = ""))
#> # A tibble: 1 × 4
#>            figure caption footnote label
#>          <gglist> <chr>   <chr>    <chr>
#> 1 A ggplot object ""      ""       ""   
```
