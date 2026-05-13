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
  if (!all(x_null | x_gg | x_labels)) {
    rlang::abort("the contents of 'x' must be NULL, a 'gg' (ggplot), or a 'labels' object")
  }
  vctrs::new_vctr(x, class = "gglist")
}

vec_ptype_abbr.gglist <- function(x, ...) {
  "gglst"
}

#' @export
format.gglist <- function(x, ...) {
  rep("A ggplot object", length(x))
}

#' @export
print.gglist <- function(x, ...) {
  for (idx in seq_along(x)) {
    for (page in gg_to_pages(x[[idx]])) {
      print(page, ...)
    }
  }
  invisible(x)
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
#' @export
#' @method vec_arith.gglist gglist
vec_arith.gglist.gglist <- function(op, x, y, ...) {
  stopifnot(op == "+")
  stopifnot(length(y) %in% c(1, length(x)))
  new_gglist(
    mapply(FUN = "+", x, y, ..., SIMPLIFY = FALSE)
  )
}
#' @export
#' @method vec_arith.gglist list
vec_arith.gglist.list <- function(op, x, y, ...) {
  stopifnot(op == "+")
  ret <- x
  for (idx in seq_along(ret)) {
    # Add the entire list to each gglist object
    ret[[idx]] <- ret[[idx]] + y
  }
  new_gglist(ret)
}
#' @export
#' @method vec_arith.gglist gg
vec_arith.gglist.gg <- function(op, x, y, ...) {
  stopifnot(op == "+")
  new_gglist(
    lapply(FUN = "+", X = x, y, ...)
  )
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
  new_gglist(
    lapply(FUN = "%+%", X = x, y, ...)
  )
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
#' When an element of `x` uses `ggforce::facet_wrap_paginate()` or
#' `ggforce::facet_grid_paginate()`, every page is rendered.  The `filename`
#' length (when not using the `%d` sprintf form) must match the total number of
#' rendered pages, which may exceed `length(x)`.
#'
#' @param x The gglist object
#' @param ... extra arguments to `knit_print()`
#' @param filename A filename with an optional "%d" sprintf pattern for saving
#'   the plots
#' @param fig_suffix Any text to add after the figure
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
knit_print.gglist <- function(x, ..., filename = NULL, fig_suffix = "\n\n") {
  page_counts <- vapply(seq_along(x), function(i) n_pages_for_plot(x[[i]]), integer(1))
  filename_list <- expand_filenames(filename, page_counts)
  pos <- 1L
  for (idx in seq_along(x)) {
    n <- page_counts[idx]
    slice <- filename_list[pos:(pos + n - 1L)]
    per_elt_filename <-
      if (all(vapply(slice, is.null, logical(1)))) {
        NULL
      } else {
        unlist(slice)
      }
    knitr::knit_print(
      x = x[[idx]], ...,
      filename = per_elt_filename,
      fig_suffix = fig_suffix
    )
    pos <- pos + n
  }
  invisible(x)
}

#' Print a ggplot (usually within knit_print.gglist)
#'
#' When `x` uses `ggforce::facet_wrap_paginate()` or
#' `ggforce::facet_grid_paginate()`, every page is rendered.  If `filename` is
#' supplied for a paginated plot it must either be length 1 with a `%d`
#' sprintf pattern, or length equal to the total number of pages.
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
  pages <- gg_to_pages(x)
  filename_list <- expand_filenames(filename, length(pages))
  for (i in seq_along(pages)) {
    cat("\n\n")
    if (!missing(fig_prefix)) {
      cat(fig_prefix)
    }
    print(pages[[i]], ...)
    if (!is.null(filename_list[[i]])) {
      ggplot2::ggsave(
        filename = filename_list[[i]], plot = pages[[i]], width = width,
        height = height, units = units
      )
    }
    if (!missing(fig_suffix)) {
      cat(fig_suffix)
    }
    cat("\n\n")
  }
  invisible(x)
}
