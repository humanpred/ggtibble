#' Knitr/Quarto chunk option for rendering ggtibble objects
#'
#' Setting the chunk option `ggtibble` triggers a knitr `opts_hooks` callback
#' that sets the chunk label, sets `fig.cap` (or `fig.subcap` under Quarto when
#' the ggtibble has multiple captions), and injects a call to `knit_print()` if
#' the chunk body is empty.
#'
#' The chunk option value may be either:
#' * a character string holding R code that evaluates to a `ggtibble` object
#'   (e.g. `ggtibble = "my_obj"` or `ggtibble = "targets::tar_read(my_obj)"`).
#'   With the string form a chunk label is derived automatically.
#' * a `ggtibble` object directly (e.g. `ggtibble = my_obj`). With the object
#'   form the chunk label is not auto-derived; set `label = ...` explicitly if
#'   you want a non-default label.
#'
#' Under Quarto (detected via the `QUARTO_VERSION` environment variable) the
#' auto-derived label is prefixed with `"fig-"` so `@fig-...` cross-references
#' work, and a multi-caption ggtibble is rendered using `fig.subcap` because
#' Quarto's cross-reference resolver does not handle vector `fig.cap` on a
#' `fig-` labelled chunk.
#'
#' @param options The chunk option list passed by knitr.
#' @returns The (possibly modified) chunk option list.
#' @keywords internal
#' @name ggtibble-knitr-hook
NULL

.ggtibble_chunk_cache <- new.env(parent = emptyenv())
.ggtibble_label_cache <- new.env(parent = emptyenv())

#' @rdname ggtibble-knitr-hook
ggtibble_opts_hook <- function(options) {
  process_ggtibble_chunk_options(options, envir = knitr::knit_global())
}

process_ggtibble_chunk_options <- function(options, envir) {
  val <- options$ggtibble
  if (is.null(val)) return(options)
  if (isFALSE(val)) return(options)
  if (is.character(val) && (length(val) != 1 || !nzchar(val))) return(options)

  obj_name <- NULL

  if (is.character(val)) {
    parsed <- tryCatch(
      parse(text = val)[[1]],
      error = function(e) {
        stop("Chunk option `ggtibble` is not valid R code: ", val, call. = FALSE)
      }
    )
    obj_name <- extract_ggtibble_name(parsed)
    obj <- eval(parsed, envir = envir)
  } else if (inherits(val, "ggtibble")) {
    obj <- val
  } else {
    stop(
      "Chunk option `ggtibble` must be a character string or a `ggtibble` object",
      call. = FALSE
    )
  }

  if (!inherits(obj, "ggtibble")) {
    stop(
      "Chunk option `ggtibble` did not evaluate to a `ggtibble` object",
      call. = FALSE
    )
  }

  if (!is.null(obj_name) && is_unnamed_label(options$label)) {
    base <- if (is_quarto_render()) paste0("fig-", obj_name) else obj_name
    options$label <- deduplicate_label(base)
  }

  captions <- expand_captions_for_pages(obj)

  if (is_quarto_render() && length(captions) > 1) {
    if (is.null(options$fig.subcap)) options$fig.subcap <- captions
    if (is.null(options$fig.cap)) options$fig.cap <- ""
  } else {
    if (is.null(options$fig.cap)) options$fig.cap <- captions
  }

  if (is_empty_code(options$code)) {
    cache_key <- options$label
    assign(cache_key, obj, envir = .ggtibble_chunk_cache)
    options$code <- sprintf(
      'knitr::knit_print(getFromNamespace(".ggtibble_chunk_cache", "ggtibble")[["%s"]])',
      cache_key
    )
  }

  options
}

expand_captions_for_pages <- function(obj) {
  caps <- obj$caption
  figures <- obj$figure
  page_counts <- vapply(seq_along(figures), function(i) length(as_gglist(figures[[i]])), integer(1))
  if (all(page_counts == 1L)) {
    return(caps)
  }
  panel_tpl <- attr(obj, "panel_caption", exact = TRUE)
  unlist(lapply(seq_along(caps), function(i) {
    n <- page_counts[i]
    cap <- caps[[i]]
    if (n == 1L || is.null(panel_tpl) || !nzchar(panel_tpl)) {
      return(rep(cap, n))
    }
    suffixes <- vapply(seq_len(n), function(p) {
      as.character(glue::glue(panel_tpl, page = p, n_pages = n))
    }, character(1))
    paste0(cap, suffixes)
  }))
}

extract_ggtibble_name <- function(parsed) {
  while (is.call(parsed) && length(parsed) >= 3 &&
         (identical(parsed[[1]], as.name("$")) ||
          identical(parsed[[1]], as.name("[[")))) {
    rhs <- parsed[[3]]
    if (is.name(rhs)) return(make.names(as.character(rhs)))
    if (is.character(rhs)) return(make.names(rhs))
    parsed <- parsed[[2]]
  }
  vars <- all.vars(parsed)
  if (length(vars) == 0) {
    return(make.names(paste0("ggtibble-", substr(rlang::hash(deparse(parsed)), 1, 8))))
  }
  make.names(vars[1])
}

is_unnamed_label <- function(label) {
  is.null(label) || (is.character(label) && grepl("^unnamed-chunk-", label))
}

is_empty_code <- function(code) {
  length(code) == 0 || all(trimws(paste(code, collapse = "")) == "")
}

is_quarto_render <- function() {
  nzchar(Sys.getenv("QUARTO_VERSION", ""))
}

deduplicate_label <- function(base) {
  count <- get0(base, envir = .ggtibble_label_cache, ifnotfound = 0L) + 1L
  assign(base, count, envir = .ggtibble_label_cache)
  if (count == 1L) base else paste0(base, "-", count)
}

reset_ggtibble_caches <- function() {
  rm(list = ls(.ggtibble_chunk_cache, all.names = TRUE), envir = .ggtibble_chunk_cache)
  rm(list = ls(.ggtibble_label_cache, all.names = TRUE), envir = .ggtibble_label_cache)
  invisible()
}

.onLoad <- function(libname, pkgname) {
  knitr::opts_hooks$set(ggtibble = ggtibble_opts_hook)

  prev <- knitr::knit_hooks$get("document")
  knitr::knit_hooks$set(document = function(x) {
    on.exit(reset_ggtibble_caches(), add = TRUE)
    if (is.function(prev)) prev(x) else x
  })
}

.onUnload <- function(libpath) {
  if (requireNamespace("knitr", quietly = TRUE)) {
    try(knitr::opts_hooks$delete("ggtibble"), silent = TRUE)
  }
}
