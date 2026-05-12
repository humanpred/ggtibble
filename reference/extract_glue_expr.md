# Extract all expressions to be evaluated by `glue()`

Extract all expressions to be evaluated by `glue()`

## Usage

``` r
extract_glue_expr(...)
```

## Arguments

- ...:

  passed to `glue()`

## Value

A character vector of expressions to be evaluated

## Examples

``` r
if (FALSE) { # \dontrun{
extract_glue_expr("foo {character(0)} {bar}")
} # }
```
