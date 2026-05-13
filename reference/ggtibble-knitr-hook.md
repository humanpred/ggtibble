# Knitr/Quarto chunk option for rendering ggtibble objects

Setting the chunk option `ggtibble` triggers a knitr `opts_hooks`
callback that sets the chunk label, sets `fig.cap` (or `fig.subcap`
under Quarto when the ggtibble has multiple captions), and injects a
call to [`knit_print()`](https://rdrr.io/pkg/knitr/man/knit_print.html)
if the chunk body is empty.

## Usage

``` r
ggtibble_opts_hook(options)
```

## Arguments

- options:

  The chunk option list passed by knitr.

## Value

The (possibly modified) chunk option list.

## Details

The chunk option value may be either:

- a character string holding R code that evaluates to a `ggtibble`
  object (e.g. `ggtibble = "my_obj"` or
  `ggtibble = "targets::tar_read(my_obj)"`). With the string form a
  chunk label is derived automatically.

- a `ggtibble` object directly (e.g. `ggtibble = my_obj`). With the
  object form the chunk label is not auto-derived; set `label = ...`
  explicitly if you want a non-default label.

Under Quarto (detected via the `QUARTO_VERSION` environment variable)
the auto-derived label is prefixed with `"fig-"` so `@fig-...`
cross-references work, and a multi-caption ggtibble is rendered using
`fig.subcap` because Quarto's cross-reference resolver does not handle
vector `fig.cap` on a `fig-` labelled chunk.
