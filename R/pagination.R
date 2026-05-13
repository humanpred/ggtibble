# Internal helpers for handling ggforce paginated facets.

is_paginated <- function(plot) {
  inherits(plot, "gg") &&
    inherits(plot$facet, c("FacetWrapPaginate", "FacetGridPaginate"))
}

n_pages_for_plot <- function(plot) {
  if (!is_paginated(plot)) {
    return(1L)
  }
  rlang::check_installed("ggforce", reason = "to render paginated facets")
  np <- ggforce::n_pages(plot)
  if (is.null(np)) 1L else as.integer(np)
}

gg_to_pages <- function(plot) {
  if (!is_paginated(plot)) {
    return(list(plot))
  }
  np <- n_pages_for_plot(plot)
  # `plot$facet` is a ggproto object (reference semantics); modifying its
  # `params$page` field mutates the shared facet for every reference to it.
  # Deep-clone the plot per page so the returned list elements render
  # independently.
  lapply(seq_len(np), function(i) {
    p <- unserialize(serialize(plot, NULL))
    p$facet$params$page <- i
    p
  })
}

expand_filenames <- function(filename, pages_per_plot) {
  n_total <- sum(pages_per_plot)
  n_logical <- length(pages_per_plot)
  if (is.null(filename)) {
    return(rep(list(NULL), n_total))
  }
  if (length(filename) == n_total) {
    return(as.list(filename))
  }
  if (length(filename) == 1 && grepl(x = filename, pattern = "%[0-9]*d")) {
    return(as.list(sprintf(filename, seq_len(n_total))))
  }
  if (length(filename) == n_logical && all(grepl(x = filename, pattern = "%[0-9]*d"))) {
    out <- unlist(
      lapply(seq_along(filename), function(i) {
        sprintf(filename[i], seq_len(pages_per_plot[i]))
      })
    )
    return(as.list(out))
  }
  stop(
    "`filename` must be NULL, length 1 with a `%d` sprintf pattern, ",
    "length equal to the number of logical plots (", n_logical,
    ") with each containing a `%d` pattern when pagination is used, ",
    "or length equal to the total number of rendered pages (", n_total, ")"
  )
}
