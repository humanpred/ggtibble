# Create a new `gglist` object

Create a new `gglist` object

## Usage

``` r
new_gglist(x = list())
```

## Arguments

- x:

  A list of ggplot2 objects to convert into a gglist

## Value

The list verified to be a gglist and with the gglist class

## See also

Other New ggtibble objects:
[`new_ggtibble()`](https://humanpred.github.io/ggtibble/reference/new_ggtibble.md)

## Examples

``` r
new_gglist(list(NULL, ggplot2::ggplot(data = data.frame())))
#> NULL
```
