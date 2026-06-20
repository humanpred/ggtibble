#' Generate a list of ggplots from a list of data.frames
#'
#' @param data A list of data.frames (or similar objects)
#' @inheritParams ggplot2::ggplot
#' @return A list of ggplot2 objects
#' @examples
#' mydata <-
#'   list(
#'     data.frame(x = 1:3, y = 3:1),
#'     data.frame(x = 4:7, y = 7:4)
#'   )
#' gglist(mydata, ggplot2::aes(x = x, y = y)) +
#'   ggplot2::geom_point()
#' @export
gglist <- function(data = NULL, mapping = ggplot2::aes(), ..., environment = parent.frame()) {
  new_gglist(
    lapply(X = data, FUN = ggplot2::ggplot, mapping = mapping, ..., environment = environment)
  )
}

#' Create a new `gglist` object
#'
#' @param x A list of ggplot2 objects to convert into a gglist
#' @returns The list verified to be a gglist and with the gglist class
#' @family New ggtibble objects
#' @examples
#' new_gglist(list(NULL, ggplot2::ggplot(data = data.frame())))
#' @export
new_gglist <- function(x = list()) {
  if (!inherits(x, "list")) {
    stop("`x` must be a list")
  }
  x_null <- vapply(X = x, FUN = is.null, FUN.VALUE = TRUE)
  x_gg <- vapply(X = x, FUN = inherits, "gg", FUN.VALUE = TRUE)
  x_labels <- vapply(X = x, FUN = inherits, "labels", FUN.VALUE = TRUE)
  # A `gglist` element is allowed so that a `gglist` may nest (a list of lists
  # of plots).  Nested elements are handled transparently by the `+` broadcast
  # and by `print()`/`plot()` because each dispatches back to the gglist method.
  x_gglist <- vapply(X = x, FUN = inherits, "gglist", FUN.VALUE = TRUE)
  if (!all(x_null | x_gg | x_labels | x_gglist)) {
    rlang::abort("the contents of 'x' must be NULL, a 'gg' (ggplot), a 'labels' object, or a 'gglist'")
  }
  vctrs::new_vctr(x, class = "gglist")
}

vec_ptype_abbr.gglist <- function(x, ...) {
  "gglst"
}

#' @export
format.gglist <- function(x, ...) {
  vapply(
    X = seq_along(x),
    FUN = function(i) {
      el <- x[[i]]
      if (is.null(el)) {
        "NULL"
      } else if (inherits(el, "gglist")) {
        paste0("A gglist (", length(el), ")")
      } else {
        "A ggplot object"
      }
    },
    FUN.VALUE = ""
  )
}

#' @export
print.gglist <- function(x, ...) {
  for (idx in seq_along(x)) {
    print(x[[idx]], ...)
  }
  invisible(x)
}

#' Plot a list of plots made by gglist
#'
#' Each element is rendered in order.  `NULL` elements render nothing (via the
#' `plot.NULL()` method) and nested `gglist` elements recurse, so a `gglist` that
#' contains other `gglist` objects (a list of lists of plots) renders every
#' leaf plot.
#'
#' @param x The `gglist` object
#' @param y Ignored; present to match the `plot()` generic
#' @param ... Passed to each element's `plot()` method
#' @return The `gglist`, invisibly
#' @export
plot.gglist <- function(x, y, ...) {
  for (idx in seq_along(x)) {
    plot(x[[idx]], ...)
  }
  invisible(x)
}

#' Plot a `NULL` object (render nothing)
#'
#' A `gglist` may contain `NULL` elements (for example a placeholder for a plot
#' that was not generated).  Defining `plot.NULL()` lets those elements be
#' rendered as a no-op instead of erroring.
#'
#' @param x `NULL`
#' @param y Ignored; present to match the `plot()` generic
#' @param ... Ignored
#' @return `NULL`, invisibly
#' @method plot NULL
#' @export
`plot.NULL` <- function(x, y, ...) {
  invisible(NULL)
}

#' @export
chooseOpsMethod.gglist <- function(x, y, mx, my, cl, reverse) {
  inherits(y, "gg") |
    inherits(y, "labels") |
    inherits(y, "list") |
    inherits(y, "uneval") |
    inherits(y, "data.frame")
}

#' @export
#' @importFrom vctrs vec_arith
vctrs::vec_arith
#' @export
#' @method vec_arith gglist
vec_arith.gglist <- function(op, x, y, ...) {
  UseMethod("vec_arith.gglist", y)
}

# Add `y` to a single element of a gglist.  `NULL` elements are preserved as
# `NULL` (rather than erroring), and a nested `gglist` element recurses through
# the gglist `+` method so the operation is broadcast through the whole tree.
.gglistAddOne <- function(el, y, op = "+") {
  if (is.null(el)) {
    NULL
  } else if (identical(op, "%+%")) {
    el %+% y
  } else {
    el + y
  }
}

# Broadcast `y` over every element of the gglist `x`, preserving element names.
.gglistBroadcast <- function(x, y, op = "+") {
  new_gglist(stats::setNames(
    lapply(seq_along(x), function(i) .gglistAddOne(x[[i]], y, op = op)),
    names(x)
  ))
}

#' @export
#' @method vec_arith.gglist gglist
vec_arith.gglist.gglist <- function(op, x, y, ...) {
  stopifnot(op == "+")
  stopifnot(length(y) %in% c(1, length(x)))
  new_gglist(stats::setNames(
    mapply(FUN = .gglistAddOne, x, y, SIMPLIFY = FALSE),
    names(x)
  ))
}
#' @export
#' @method vec_arith.gglist list
vec_arith.gglist.list <- function(op, x, y, ...) {
  stopifnot(op == "+")
  # Add the entire list to each gglist object (ggplot2 list-addition semantics)
  .gglistBroadcast(x, y)
}
#' @export
#' @method vec_arith.gglist gg
vec_arith.gglist.gg <- function(op, x, y, ...) {
  stopifnot(op == "+")
  .gglistBroadcast(x, y)
}
#' @export
#' @method vec_arith.gglist labels
vec_arith.gglist.labels <- vec_arith.gglist.gg
#' @export
#' @method vec_arith.gglist guides
vec_arith.gglist.guides <- vec_arith.gglist.gg
#' @export
#' @method vec_arith.gglist uneval
vec_arith.gglist.uneval <- vec_arith.gglist.gg # aes()
#' @export
#' @method vec_arith.gglist ggbreak_params
vec_arith.gglist.ggbreak_params <- vec_arith.gglist.gg # ggbreaks package
#' @export
#' @method vec_arith.gglist data.frame
vec_arith.gglist.data.frame <-  function(op, x, y, ...) {
  stopifnot(op == "+")
  .gglistBroadcast(x, y, op = "%+%")
}

#' @importFrom knitr knit_print
#' @export
knitr::knit_print

#' Print a list of plots made by gglist
#'
#' The `filename` argument may be given with an `sprintf()` format including
#' "%d" to allow automatic numbering of the output filenames.  Specifically, the
#' pattern of "%d" with an optional non-negative integer between the "%" and "d"
#' is searched for and if found, then the filename will be generated using that
#' `sprintf()` format.  Note that also means that other requirements for
#' `sprintf()` must be met; for example, if you want a percent sign ("%") in the
#' filename, it must be doubled so that sprintf returns what is desired.
#'
#' When `length(x)` exceeds `float_barrier_after` and the output format is
#' LaTeX (as detected by `knitr::is_latex_output()`), `fig_suffix` defaults to
#' `"\n\n\\FloatBarrier\n\n"` instead of the usual `"\n\n"`.  This avoids the
#' LaTeX "Output loop---100 consecutive dead cycles" error that occurs when
#' the float queue (default capacity ~18) overflows.  `\FloatBarrier` is
#' provided by the `placeins` LaTeX package, which is *not* loaded by default
#' in `rmarkdown::pdf_document`; add `\usepackage{placeins}` to the document
#' preamble (e.g. via `header-includes` in the YAML) when relying on the
#' auto-suffix.  Pass `fig_suffix` explicitly to override, or set
#' `float_barrier_after = Inf` to disable the auto-suffix entirely.
#'
#' @param x The gglist object
#' @param ... extra arguments to `knit_print()`
#' @param filename A filename with an optional "%d" sprintf pattern for saving
#'   the plots
#' @param fig_suffix Any text to add after the figure.  Defaults to `NULL`,
#'   which means "auto-select": `"\n\n\\FloatBarrier\n\n"` for LaTeX output
#'   when `length(x) > float_barrier_after`, otherwise `"\n\n"`.
#' @param float_barrier_after Numeric threshold for emitting `\FloatBarrier`
#'   between figures in LaTeX output.  When `length(x) > float_barrier_after`
#'   and `knitr::is_latex_output()` is `TRUE` and the user did not supply
#'   `fig_suffix`, `fig_suffix` defaults to `"\n\n\\FloatBarrier\n\n"`.  Has
#'   no effect on non-LaTeX output.  Set to `Inf` to disable.  Defaults to
#'   `10`.
#' @return The list, invisibly
#' @family knitters
#' @examples
#' # Ensure that each figure is within its own float area
#' mydata <-
#'   list(
#'     data.frame(x = 1:3, y = 3:1),
#'     data.frame(x = 4:7, y = 7:4)
#'   )
#' p <- gglist(mydata, ggplot2::aes(x = x, y = y)) +
#'   ggplot2::geom_point()
#' knit_print(p, fig_suffix = "\n\n\\FloatBarrier\n\n")
#' @export
knit_print.gglist <- function(x, ..., filename = NULL, fig_suffix = NULL, float_barrier_after = 10) {
  checkmate::assert_number(float_barrier_after, lower = 0, na.ok = FALSE)
  if (is.null(fig_suffix)) {
    fig_suffix <- "\n\n"
    if (length(x) > float_barrier_after && knitr::is_latex_output()) {
      fig_suffix <- "\n\n\\FloatBarrier\n\n"
    }
  }
  if (!is.null(filename)) {
    if (length(filename) == length(x)) {
      # do nothing
    } else if (length(filename) == 1 && grepl(x = filename, pattern = "%[0-9]*d")) {
      filename <- sprintf(filename, seq_along(x))
    }
  }
  stopifnot("`filename` must be NULL, the same length as `x`, or an sprintf format" = is.null(filename) |
    length(filename) == length(x))
  lapply(X = seq_along(x), FUN = function(idx) {
    knitr::knit_print(x = x[[idx]], ..., filename = filename[[idx]], fig_suffix = fig_suffix)
  })
  invisible(x)
}

#' Print a ggplot (usually within knit_print.gglist)
#'
#' @param x The gg object (i.e. a ggplot)
#' @param ... Ignored
#' @param filename A filename saving the plot
#' @param fig_prefix Text to `cat()` before the figure is printed
#' @inheritParams knit_print.gglist
#' @inheritParams ggplot2::ggsave
#' @return The gg object, invisibly
#' @family knitters
#' @export
knit_print.gg <- function(x, ..., fig_prefix, fig_suffix, filename = NULL, width = 6, height = 4, units = "in") {
  cat("\n\n")
  if (!missing(fig_prefix)) {
    cat(fig_prefix)
  }
  print(x, ...)
  if (!is.null(filename)) {
    ggplot2::ggsave(
      filename = filename, plot = x, width = width,
      height = height, units = units
    )
  }
  if (!missing(fig_suffix)) {
    cat(fig_suffix)
  }
  cat("\n\n")
  invisible(x)
}
